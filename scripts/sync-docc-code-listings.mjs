#!/usr/bin/env node

import { readFile, writeFile } from "node:fs/promises";
import { codeListings, sourceListing } from "./docc-code-listings.mjs";

await Promise.all(codeListings.map(async ({ listingPath, sourcePath, ranges }) => {
  const source = await readFile(sourcePath, "utf8");
  await writeFile(listingPath, sourceListing(source, ranges), "utf8");
}));

console.log(`Synchronized ${codeListings.length} DocC code listings from package sources.`);
