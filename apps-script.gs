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
    if (headers.every(h => !h)) {
      const keys = Object.keys(item);
      sheet.getRange(1, 1, 1, keys.length).setValues([keys]);
      sheet.appendRow(keys.map(k => item[k] !== undefined ? item[k] : ''));
    } else {
      const row = headers.map(h => item[h] !== undefined ? item[h] : '');
      sheet.appendRow(row);
    }
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
      headers.forEach((h, i) => { if (h) obj[h] = row[i]; });
      return obj;
    });
    return jsonResponse({ items });
  } catch (err) {
    return jsonResponse({ items: [], error: err.toString() });
  }
}

function jsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

// One-time helper Tony can run from the Apps Script editor to seed the
// header rows correctly. Run → Authorize → Run again. After that,
// the regular doGet/doPost work without further setup.
function seedHeaders() {
  const ss = SpreadsheetApp.getActive();
  const leadHeaders = ['id','name','email','phone','occasion','budget','style','source','status','time','notes','createdAt'];
  const bookHeaders = ['id','name','email','phone','type','apptId','consultant','date','time','duration','status','notes','occasion','budget','createdAt'];
  let leads = ss.getSheetByName('Leads');
  if (!leads) leads = ss.insertSheet('Leads');
  if (leads.getLastRow() === 0) leads.getRange(1, 1, 1, leadHeaders.length).setValues([leadHeaders]);
  let books = ss.getSheetByName('Bookings');
  if (!books) books = ss.insertSheet('Bookings');
  if (books.getLastRow() === 0) books.getRange(1, 1, 1, bookHeaders.length).setValues([bookHeaders]);
  Logger.log('Headers seeded. Now deploy as Web App.');
}
