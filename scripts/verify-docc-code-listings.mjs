#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { codeListings, sourceListing } from "./docc-code-listings.mjs";

let differences = 0;

for (const { listingPath, sourcePath, ranges } of codeListings) {
  const [listing, source] = await Promise.all([
    readFile(listingPath, "utf8"),
    readFile(sourcePath, "utf8"),
  ]);

  if (listing !== sourceListing(source, ranges)) {
    console.error(`DocC listing differs from source: ${listingPath} != ${sourcePath}`);
    differences += 1;
  }
}

if (differences > 0) {
  process.exit(1);
}

console.log(`Verified ${codeListings.length} DocC code listings against package sources.`);
