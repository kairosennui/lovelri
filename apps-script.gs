/**
 * Lovelri Leads & Bookings — Google Sheets backend
 * ──────────────────────────────────────────────────────────────────────────
 * Paste this whole file into a Google Apps Script project bound to a Google
 * Sheet that has two tabs: "Leads" and "Bookings". Then deploy as Web App
 * (Execute as: Me, Who has access: Anyone). Copy the Web App URL into
 * SHEETS_URL at the top of index.html. Done.
 *
 * The sheet's first row in each tab is the header row — column names map
 * 1:1 to JSON keys when reading and writing. Recommended headers:
 *
 *   Leads tab:
 *     id | name | email | phone | occasion | budget | style | source | status | time | notes | createdAt
 *
 *   Bookings tab:
 *     id | name | email | phone | type | apptId | consultant | date | time | duration | status | notes | occasion | budget | createdAt
 *
 * Anything in the dashboard that doesn't match a column is silently ignored —
 * adding new columns later just means the dashboard can start writing to them.
 */

// CORS-friendly POST handler. Body is JSON.stringified text.
function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    const tab = body.tab; // "Leads" or "Bookings"
    const item = body.item || {};
    const sheet = SpreadsheetApp.getActive().getSheetByName(tab);
    if (!sheet) {
      return jsonResponse({ ok: false, error: 'Tab "' + tab + '" not found. Create it in the sheet first.' });
    }
    const lastCol = Math.max(1, sheet.getLastColumn());
    const headers = sheet.getRange(1, 1, 1, lastCol).getValues()[0];
    // If header row is empty, seed it from the item's keys
    // Sheets treats strings starting with =, +, or - as formulas. Escape them
    // by prepending an apostrophe so phone numbers like "+1 416 555 0000" land
    // as text instead of evaluating to #ERROR!.
    function safe(v) {
      if (typeof v === 'string' && /^[=+\-]/.test(v)) return "'" + v;
      return v === undefined ? '' : v;
    }
    // If the header row is empty, seed it from the item's keys
    if (headers.every(h => !h)) {
      const keys = Object.keys(item);
      sheet.getRange(1, 1, 1, keys.length).setValues([keys]);
      sheet.appendRow(keys.map(k => safe(item[k])));
      return jsonResponse({ ok: true });
    }
    // If this id already exists in the sheet, UPDATE the row instead of appending.
    // Lets the dashboard call pushToSheet repeatedly with the same id to mutate
    // a lead's status (new → booked → SQL → Won) without creating duplicate rows.
    const idIdx = headers.indexOf('id');
    if (idIdx >= 0 && item.id !== undefined && item.id !== '') {
      const lastRow = sheet.getLastRow();
      if (lastRow > 1) {
        const ids = sheet.getRange(2, idIdx + 1, lastRow - 1, 1).getValues();
        let matchRow = -1;
        for (let i = 0; i < ids.length; i++) {
          if (String(ids[i][0]) === String(item.id)) { matchRow = i + 2; break; }
        }
        if (matchRow > 0) {
          const newRow = headers.map(h => safe(item[h]));
          sheet.getRange(matchRow, 1, 1, newRow.length).setValues([newRow]);
          return jsonResponse({ ok: true, updated: true });
        }
      }
    }
    // Otherwise append a new row
    sheet.appendRow(headers.map(h => safe(item[h])));
    return jsonResponse({ ok: true });
  } catch (err) {
    return jsonResponse({ ok: false, error: err.toString() });
  }
}

// GET handler. Returns all rows of the requested tab as an array of objects.
function doGet(e) {
  try {
    const tab = (e && e.parameter && e.parameter.tab) || 'Leads';
    const sheet = SpreadsheetApp.getActive().getSheetByName(tab);
    if (!sheet) return jsonResponse({ items: [] });
    const lastRow = sheet.getLastRow();
    const lastCol = sheet.getLastColumn();
    if (lastRow < 2 || lastCol < 1) return jsonResponse({ items: [] });
    const data = sheet.getRange(1, 1, lastRow, lastCol).getValues();
    const headers = data[0];
    const items = data.slice(1).map(row => {
      const obj = {};
      headers.forEach((h, i)