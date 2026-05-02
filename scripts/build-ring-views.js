#!/usr/bin/env node
// Build ring-views.json — curated mapping from {slug → angle → metal → photoURL}
// Classifications are encoded as position arrays per ring, derived by visually
// inspecting each ring's contact sheet.
//
// Position pattern: 1-indexed, matches ring-photos.json image positions.
// Each entry is "ANGLE-METAL" where:
//   ANGLE  ∈ FRONT (head-on, gem facing camera)
//          | THREEQ (three-quarter, dynamic angle)
//          | SIDE   (profile, ring as oval, gem at top)
//   METAL  ∈ white | yellow | rose
//
// If a slot is missing/unsuitable, use null.

const fs = require("fs");
const path = require("path");

const CLASSIFICATIONS = {
  // pos 1 → 9
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
  // Switzerland has 13 photos: positions 1–9 are 3×3 ring shots, 10–13 are
  // close-up macro detail shots of the prongs (skip).
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

// Load scraped photos
const photos = JSON.parse(
  fs.readFileSync(path.join(__dirname, "..", "ring-photos.json"), "utf8")
);

const out = { generatedAt: new Date().toISOString(), rings: {} };

for (const ring of photos.rings) {
  const c = CLASSIFICATIONS[ring.slug];
  if (!c) {
    console.warn(`No classifications for ${ring.slug} — skipping`);
    continue;
  }
  const slots = { FRONT: {}, THREEQ: {}, SIDE: {} };
  ring.images.forEach((img, i) => {
    const tag = c[i];
    if (!tag) return;
    const [angle, metal] = tag.split("-");
    // Use Shopify's resize param to get a reasonable-sized image (saves bandwidth)
    const url = img.src.includes("?") ? img.src + "&width=600" : img.src + "?width=600";
    // Don't overwrite — first occurrence wins
    if (!slots[angle][metal]) slots[angle][metal] = url;
  });

  // Fill in fallbacks: if a (angle,metal) slot is empty, fall back to the same
  // angle in another metal, then to FRONT/white as last resort.
  for (const angle of ["FRONT", "THREEQ", "SIDE"]) {
    for (const metal of ["white", "yellow", "rose"]) {
      if (!slots[angle][metal]) {
        slots[angle][metal] =
          slots[angle].white || slots[angle].yellow || slots[angle].rose ||
          slots.FRONT.white || slots.FRONT.yellow || slots.FRONT.rose ||
          ring.images[0]?.src;
      }
    }
  }

  out.rings[ring.slug] = {
    title: ring.title,
    slots,
  };
}

const outPath = path.join(__dirname, "..", "ring-views.json");
fs.writeFileSync(outPath, JSON.stringify(out, null, 2));
console.log(`Wrote ${outPath} for ${Object.keys(out.rings).length} rings.`);
