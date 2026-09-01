#!/usr/bin/env node

import { readdir, readFile, stat, writeFile } from "node:fs/promises";
import { join } from "node:path";

const outputPath = process.argv[2];

if (!outputPath) {
  console.error("Usage: normalize-docc-section-links.mjs <docc-output-path>");
  process.exit(1);
}

let changedFiles = 0;
let changedLinks = 0;

async function pathExists(path) {
  try {
    await stat(path);
    return true;
  } catch {
    return false;
  }
}

async function walk(path) {
  const entries = await readdir(path, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const child = join(path, entry.name);

    if (entry.isDirectory()) {
      files.push(...await walk(child));
    } else if (entry.isFile() && entry.name.endsWith(".json")) {
      files.push(child);
    }
  }

  return files;
}

async function normalizeUrl(value) {
  if (typeof value !== "string") {
    return value;
  }

  const match = value.match(/^(\/[^#?]+)(#[^#]+)$/);

  if (!match) {
    return value;
  }

  const [, pagePath, hash] = match;

  if (pagePath.endsWith("/")) {
    return value;
  }

  const pageDirectory = join(outputPath, pagePath);

  if (!await pathExists(pageDirectory)) {
    return value;
  }

  changedLinks += 1;
  return `${pagePath}/${hash}`;
}

async function normalizeNode(node) {
  if (Array.isArray(node)) {
    let changed = false;
    const next = [];

    for (const item of node) {
      const { value, changed: childChanged } = await normalizeNode(item);
      next.push(value);
      changed = changed || childChanged;
    }

    return { value: next, changed };
  }

  if (!node || typeof node !== "object") {
    return { value: node, changed: false };
  }

  let changed = false;
  const next = {};

  for (const [key, item] of Object.entries(node)) {
    if (key === "url") {
      const normalized = await normalizeUrl(item);
      next[key] = normalized;
      changed = changed || normalized !== item;
      continue;
    }

    const { value, changed: childChanged } = await normalizeNode(item);
    next[key] = value;
    changed = changed || childChanged;
  }

  return { value: next, changed };
}

for (const file of await walk(join(outputPath, "data"))) {
  const source = await readFile(file, "utf8");
  const json = JSON.parse(source);
  const { value, changed } = await normalizeNode(json);

  if (!changed) {
    continue;
  }

  await writeFile(file, JSON.stringify(value), "utf8");
  changedFiles += 1;
}

console.log(
  `Normalized ${changedLinks} DocC section links in ${changedFiles} JSON files.`
);
