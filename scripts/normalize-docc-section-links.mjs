#!/usr/bin/env node

import { mkdir, readdir, readFile, stat, writeFile } from "node:fs/promises";
import { dirname, join, relative } from "node:path";

const outputPath = process.argv[2];

if (!outputPath) {
  console.error("Usage: normalize-docc-section-links.mjs <docc-output-path>");
  process.exit(1);
}

let changedFiles = 0;
let changedLinks = 0;
let changedHighlights = 0;

const highlightLinesByFile = {
  "04-01-HandJointSample.swift": range(3, 20),
  "04-02-HandJointCatalog.swift": range(3, 33),
  "04-03-HandTrackingSnapshot.swift": [
    ...range(7, 10),
    17,
    ...range(30, 46),
  ],
  "04-04-HandTrackingService.swift": [10, 23, 24],
  "04-05-HandJointVisualizer.swift": range(5, 85),
  "04-06-ImmersiveView.swift": [6, 10, 11, 12],
  "05-01-HandJointPositionSample.swift": range(4, 18),
  "05-02-HandPoseFeature.swift": range(4, 31),
  "05-03-HandPoseFeatureBuilder.swift": [
    ...range(4, 33),
    ...range(35, 45),
    ...range(48, 56),
    ...range(59, 64),
    ...range(68, 82),
  ],
  "05-04-HandTrackingSnapshot.swift": [
    ...range(7, 12),
    ...range(15, 18),
    25,
    ...range(38, 53),
  ],
  "05-05-ContentView.swift": [
    ...range(26, 33),
    ...range(40, 61),
  ],
};

function range(start, end) {
  return Array.from({ length: end - start + 1 }, (_, index) => start + index);
}

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

async function walkFiles(path, filter) {
  const entries = await readdir(path, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const child = join(path, entry.name);

    if (entry.isDirectory()) {
      files.push(...await walkFiles(child, filter));
    } else if (entry.isFile() && filter(entry.name)) {
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

function normalizeHighlights(reference) {
  const lines = highlightLinesByFile[reference.identifier];

  if (!lines) {
    return false;
  }

  const highlights = lines.map((line) => ({ line }));
  const previous = JSON.stringify(reference.highlights ?? []);
  const next = JSON.stringify(highlights);

  if (previous === next) {
    return false;
  }

  reference.highlights = highlights;
  changedHighlights += highlights.length;
  return true;
}

function normalizeReferenceHighlights(json) {
  if (!json.references || typeof json.references !== "object") {
    return false;
  }

  let changed = false;

  for (const reference of Object.values(json.references)) {
    if (!reference || typeof reference !== "object") {
      continue;
    }

    changed = normalizeHighlights(reference) || changed;
  }

  return changed;
}

async function writeTutorialAssets() {
  const cssPath = join(outputPath, "css", "handjutsu-tutorial-overrides.css");
  const jsPath = join(outputPath, "js", "handjutsu-tutorial-overrides.js");

  await mkdir(dirname(cssPath), { recursive: true });
  await mkdir(dirname(jsPath), { recursive: true });

  await writeFile(cssPath, `:root {
  --color-code-line-highlight: rgba(14, 165, 233, 0.2);
  --color-code-line-highlight-border: #0ea5e9;
}

body[data-color-scheme="dark"] {
  --color-code-line-highlight: rgba(56, 189, 248, 0.24);
  --color-code-line-highlight-border: #38bdf8;
}
`, "utf8");

  await writeFile(jsPath, `(function () {
  function normalizeText(value) {
    return (value || "").replace(/\\s+/g, " ").trim();
  }

  function sectionIdFromHash(hash) {
    if (!hash) {
      return "";
    }

    try {
      return decodeURIComponent(hash.replace(/^#/, ""));
    } catch {
      return hash.replace(/^#/, "");
    }
  }

  function sections() {
    return Array.from(document.querySelectorAll(".section[id], .sections > [id]"));
  }

  function sectionTitle(section) {
    const heading = section.querySelector("h2, h3, .headline");
    return normalizeText(heading && heading.textContent);
  }

  function sectionForLabel(label) {
    const normalizedLabel = normalizeText(label);

    if (!normalizedLabel) {
      return null;
    }

    if (normalizedLabel === "Introduction") {
      return document.getElementById("app-main") || document.body;
    }

    return sections().find((section) => sectionTitle(section) === normalizedLabel) || null;
  }

  function sectionForHash(hash) {
    const id = sectionIdFromHash(hash);

    if (!id) {
      return null;
    }

    return document.getElementById(id);
  }

  function scrollToSection(section) {
    if (!section) {
      return false;
    }

    if (!section.hasAttribute("tabindex")) {
      section.setAttribute("tabindex", "-1");
    }

    section.scrollIntoView({ block: "start" });
    section.focus({ preventScroll: true });
    return true;
  }

  function scrollFromCurrentHash() {
    window.requestAnimationFrame(function () {
      scrollToSection(sectionForHash(window.location.hash));
    });
  }

  window.addEventListener("hashchange", scrollFromCurrentHash);
  window.addEventListener("popstate", scrollFromCurrentHash);

  document.addEventListener("click", function (event) {
    const target = event.target.closest("a, button, [role='button']");

    if (!target) {
      return;
    }

    let section = null;
    let hash = "";
    const href = target.getAttribute("href");

    if (href) {
      try {
        const url = new URL(href, window.location.href);
        const samePage = url.origin === window.location.origin
          && url.pathname.replace(/\\/$/, "") === window.location.pathname.replace(/\\/$/, "");

        if (samePage && url.hash) {
          hash = url.hash;
          section = sectionForHash(hash);
        }
      } catch {
        section = null;
      }
    }

    if (!section) {
      section = sectionForLabel(target.textContent);
      hash = section && section.id ? "#" + encodeURIComponent(section.id) : "";
    }

    if (!section) {
      return;
    }

    event.preventDefault();

    if (hash && window.location.hash !== hash) {
      history.pushState(null, "", hash);
    }

    window.setTimeout(function () {
      scrollToSection(section);
    }, 0);
  }, true);

  if (window.location.hash) {
    window.setTimeout(scrollFromCurrentHash, 250);
  }
}());
`, "utf8");
}

async function injectTutorialAssets() {
  const htmlFiles = await walkFiles(outputPath, (name) => name.endsWith(".html"));
  let changedHtmlFiles = 0;

  for (const file of htmlFiles) {
    const source = await readFile(file, "utf8");
    const cssHref = relative(dirname(file), join(outputPath, "css", "handjutsu-tutorial-overrides.css")).replaceAll("\\", "/");
    const jsSrc = relative(dirname(file), join(outputPath, "js", "handjutsu-tutorial-overrides.js")).replaceAll("\\", "/");
    const cssTag = `<link rel="stylesheet" href="${cssHref}">`;
    const jsTag = `<script src="${jsSrc}"></script>`;

    let next = source;

    if (!next.includes(cssTag)) {
      next = next.replace("</head>", `  ${cssTag}\n</head>`);
    }

    if (!next.includes(jsTag)) {
      next = next.replace("</body>", `  ${jsTag}\n</body>`);
    }

    if (next === source) {
      continue;
    }

    await writeFile(file, next, "utf8");
    changedHtmlFiles += 1;
  }

  return changedHtmlFiles;
}

for (const file of await walk(join(outputPath, "data"))) {
  const source = await readFile(file, "utf8");
  const json = JSON.parse(source);
  const { value, changed: linksChanged } = await normalizeNode(json);
  const highlightsChanged = normalizeReferenceHighlights(value);
  const changed = linksChanged || highlightsChanged;

  if (!changed) {
    continue;
  }

  await writeFile(file, JSON.stringify(value), "utf8");
  changedFiles += 1;
}

await writeTutorialAssets();
const changedHtmlFiles = await injectTutorialAssets();

console.log(
  `Normalized ${changedLinks} DocC section links and ${changedHighlights} code highlights in ${changedFiles} JSON files.`
);
console.log(`Injected tutorial overrides in ${changedHtmlFiles} HTML files.`);
