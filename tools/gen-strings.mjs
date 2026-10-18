// Generates App/Resources/Web.xcstrings from the site's dictionaries, so the app
// speaks with the same words as erasemc.com and keys stay identical (`tiers.title`).
//
// Usage: node tools/gen-strings.mjs [path/to/Imprint-Web]
// Node 22.18+ loads `lib/i18n.ts` directly (it has no imports, only types to strip).

import { writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const web = resolve(process.argv[2] ?? resolve(root, "..", "Imprint-Web"));
const { dictionaries } = await import(pathToFileURL(resolve(web, "lib", "i18n.ts")).href);

const strings = {};
for (const key of Object.keys(dictionaries.en).sort()) {
  const localizations = {};
  for (const [locale, dictionary] of Object.entries(dictionaries)) {
    const value = dictionary[key];
    if (typeof value === "string") {
      localizations[locale] = { stringUnit: { state: "translated", value } };
    }
  }
  // Placeholders stay in the site's `{name}` form; `Copy.text` fills them at runtime.
  strings[key] = { extractionState: "manual", localizations };
}

const catalogue = { sourceLanguage: "en", strings, version: "1.0" };
const target = resolve(root, "App", "Resources", "Web.xcstrings");
writeFileSync(target, JSON.stringify(catalogue, null, 2) + "\n");
console.log(`${Object.keys(strings).length} keys → ${target}`);
