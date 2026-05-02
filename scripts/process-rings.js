#!/usr/bin/env node
// Download pilot ring photos, chromakey + auto-crop via ImageMagick, save as
// transparent PNGs to rings/multi/. Then build ring-views.json with local paths.
//
// Why this exists: loading remote Shopify CDN images into a canvas in the
// browser taints the canvas (CORS), which prevents pixel-level chromakey at
// runtime. Doing the chromakey here at build time sidesteps the problem.
//
// Requires: ImageMagick (`convert` on PATH).
//
// Usage:  node scripts/process-rings.js

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

// ── Same classifications as build-ring-views.js ─────────────────────────────
// Position pattern: 1-indexed, matches ring-photos.json image positions.
// "ANGLE-METAL" tags. null = skip (e.g. detail close-ups).
const CLASSIFICATIONS = {
  "sicily-lotus-ring": [
    "SIDE-white",  "SIDE-yellow",  "FRONT-yellow",
    "FRONT-rose",  "FRONT-white",  "THREEQ-yellow",
    "THREEQ-rose", "THREEQ-white", "SIDE-rose",
  ],
  "dolomites-ring": [
    "FRONT-white",  "THREEQ-yellow", "FRONT-yellow",
    "SIDE-yellow",  "FRONT-rose",    "THREEQ-rose",
    "THREEQ-white", "SIDE-rose",     "SIDE-white",
  ],
  "hawaii-ring": [
    "FRONT-white",  "FRONT-yellow",  "SIDE-yellow",
    "FRONT-rose",   "THREEQ-yellow", "THREEQ-rose",
    "THREEQ-white", "SIDE-rose",     "SIDE-white",
  ],
  "mt-fuji-ring": [
    "SIDE-white",   "FRONT-yellow",  "FRONT-rose",
    "FRONT-white",  "THREEQ-yellow", "THREEQ-rose",
    "THREEQ-white", "SIDE-yellow",   "SIDE-rose",
  ],
  "switzerland": [
    "FRONT-white",  "FRONT-yellow",  "FRONT-rose",
    "SIDE-white",   "SIDE-rose",     "SIDE-yellow",
    "THREEQ-yellow","THREEQ-white",  "THREEQ-rose",
    null, null, null, null,
  ],
  "victoria": [
    "FRONT-white",  "THREEQ-yellow", "FRONT-rose",
    "THREEQ-rose",  "FRONT-rose",    "FRONT-yellow",
    "FRONT-yellow", "FRONT-white",   "THREEQ-white",
  ],
  "versailles": [
    "FRONT-white",  "THREEQ-yellow", "FRONT-yellow",
    "SIDE-yellow",  "FRONT-rose",    "FRONT-rose",
    "SIDE-rose",    "THREEQ-white",  "THREEQ-rose",
  ],
  "edmonton": [
    "FRONT-white",  "FRONT-yellow",  "FRONT-rose",
    "FRONT-rose",   "THREEQ-rose",   "FRONT-white",
    "FRONT-yellow", "SIDE-white",    "SIDE-yellow",
  ],
  "lake-como-ring": [
    "FRONT-white",  "THREEQ-yellow", "FRONT-yellow",
    "FRONT-rose",   "THREEQ-yellow", "THREEQ-rose",
    "SIDE-white",   "SIDE-rose",     "SIDE-white",
  ],
  "vancouver": [
    "FRONT-white",  "FRONT-yellow",  "FRONT-white",
    "THREEQ-white", "FRONT-yellow",  "THREEQ-yellow",
    "FRONT-rose",   "FRONT-rose",    "THREEQ-rose",
  ],
};

const REPO_ROOT = path.join(__dirname, "..");
const PHOTOS_PATH = path.join(REPO_ROOT, "ring-photos.json");
const OUT_DIR = path.join(REPO_ROOT, "rings", "multi");
const VIEWS_PATH = path.join(REPO_ROOT, "ring-views.json");
const TMP_IN = "/tmp/lovelri-ring-in.jpg";

if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

async function downloadAndProcess(url, outName) {
  const outPath = path.join(OUT_DIR, outName);
  if (fs.existsSync(outPath)) return outPath; // idempotent — skip if present
  const u = url.includes("?") ? url + "&width=600" : url + "?width=600";
  const res = await fetch(u);
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(TMP_IN, buf);

  // ImageMagick:
  //   -fuzz 8%       : tolerance for "near-white"
  //   -transparent #fff : key out white background
  //   -trim          : crop to bounding box of non-transparent pixels
  //   -bordercolor   : add a small transparent border so antialiased edges
  //                    don't sit flush against the canvas edge
  //   -border 6      : 6-pixel padding
  execSync(
    `convert "${TMP_IN}" -fuzz 8% -transparent white -trim ` +
    `-bordercolor none -border 6 "${outPath}"`,
    { stdio: "pipe" }
  );
  return outPath;
}

async function main() {
  const photos = JSON.parse(fs.readFileSync(PHOTOS_PATH, "utf8"));
  const views = { generatedAt: new Date().toISOString(), rings: {} };
  let total = 0, skipped = 0, failed = 0;

  for (const ring of photos.rings) {
    const c = CLASSIFICATIONS[ring.slug];
    if (!c) { skipped++; continue; }

    const slots = { FRONT: {}, THREEQ: {}, SIDE: {} };
    for (let i = 0; i < ring.images.length; i++) {
      const tag = c[i];
      if (!tag) continue;
      const img = ring.images[i];
      const [angle, metal] = tag.split("-");
      const fileName = `${ring.slug}_${angle}_${metal}.png`;
      process.stdout.write(`Processing ${fileName}... `);
      try {
        await downloadAndProcess(img.src, fileName);
        if (!slots[angle][metal]) slots[angle][metal] = `./rings/multi/${fileName}`;
        total++;
        console.log("✓");
      } catch (e) {
        failed++;
        console.log(`✗ ${e.message}`);
      }
    }

    // Fill in fallbacks: if a (angle,metal) slot is empty, fall back to the
    // same angle in another metal, then to FRONT/white.
    for (const angle of ["FRONT", "THREEQ", "SIDE"]) {
      for (const metal of ["white", "yellow", "rose"]) {
        if (!slots[angle][metal]) {
          slots[angle][metal] =
            slots[angle].white || slots[angle].yellow || slots[angle].rose ||
            slots.FRONT.white  || slots.FRONT.yellow  || slots.FRONT.rose ||
            null;
        }
      }
    }

    views.rings[ring.slug] = { title: ring.title, slots };
  }

  fs.writeFileSync(VIEWS_PATH, JSON.stringify(views, null, 2));
  console.log(`\nProcessed: ${total}  Skipped rings: ${skipped}  Failed: ${failed}`);
  console.log(`Wrote ${VIEWS_PATH}`);
}

main().catch((e) => { console.error("FATAL:", e); process.exit(1); });
