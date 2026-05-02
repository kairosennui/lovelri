#!/usr/bin/env node
// Lovelri ring photo scraper
// Hits Shopify's /products/{slug}.json endpoint for each pilot ring,
// extracts all image URLs + metadata, writes ring-photos.json next to it.
//
// Usage:  node scripts/scrape-rings.js
//
// No build step, no dependencies — uses Node's built-in fetch (Node 18+).

const fs = require("fs");
const path = require("path");

// All 33 ring slugs — full Lovelri catalog (matches index.html's RINGS array)
const PILOT_SLUGS = [
  "sicily-lotus-ring", "dolomites-ring", "sicily-ring-marquise", "hawaii-ring",
  "portland", "mt-fuji-ring", "thunder-bay-ring", "switzerland", "verona-ring",
  "sydney-ring", "tahiti-ring", "lake-como-ring", "victoria", "versailles",
  "ontario", "madrid", "vancouver", "amalfi-coast", "nara-ring", "capri-ring",
  "england", "osaka-ring", "lab-diamonds-mississauga", "kyoto",
  "san-francisco-ring", "kingston", "halifax", "fiji-ring", "lake-louise-ring",
  "edmonton", "florence", "burlington-ring", "aspen-ring", "whistler",
];

const STORE = "https://lovelri.com";

async function fetchProduct(slug) {
  const url = `${STORE}/products/${slug}.json`;
  const res = await fetch(url, {
    headers: { "User-Agent": "lovelri-tryon-scraper/1.0" },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${slug}`);
  const data = await res.json();
  const p = data.product;
  return {
    slug,
    title: p.title,
    handle: p.handle,
    productType: p.product_type,
    vendor: p.vendor,
    tags: p.tags,
    priceFrom: p.variants?.[0]?.price ?? null,
    images: p.images.map((im) => ({
      id: im.id,
      position: im.position,
      src: im.src,
      width: im.width,
      height: im.height,
      alt: im.alt || null,
      // Angle tag will be filled in by the classification pass.
      angle: null,
    })),
    fetchedAt: new Date().toISOString(),
  };
}

async function main() {
  const out = { generatedAt: new Date().toISOString(), rings: [] };
  for (const slug of PILOT_SLUGS) {
    process.stdout.write(`Fetching ${slug}... `);
    try {
      const r = await fetchProduct(slug);
      out.rings.push(r);
      console.log(`✓ ${r.images.length} images`);
    } catch (e) {
      console.log(`✗ ${e.message}`);
      out.rings.push({ slug, error: e.message });
    }
  }

  const outPath = path.join(__dirname, "..", "ring-photos.json");
  fs.writeFileSync(outPath, JSON.stringify(out, null, 2));
  console.log(`\nWrote ${outPath}`);
  const total = out.rings.reduce((s, r) => s + (r.images?.length || 0), 0);
  console.log(`Total: ${out.rings.length} rings, ${total} images.`);
}

main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});
