#!/usr/bin/env python3
"""Add or update one key in a package's String Catalog, then regenerate symbols.

Usage:
  add_strings.py <Package> <key> --comment "Context for translators" \
      --value en="Choose your services" --value es="Elegir tus servicios"

<Package> is a directory under Packages/ (e.g. DetailsFeature). Every language
already present in the catalog must get a value, so a key can never ship
untranslated. The catalog's own JSON style is preserved, so diffs show only
the key that changed.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]


def catalog_path(package: str) -> Path:
    path = REPO / "Packages" / package / "Sources" / package / "Translations" / "Localizable.xcstrings"
    if not path.exists():
        sys.exit(f"No catalog at {path.relative_to(REPO)}")
    return path


def parse_values(pairs: list[str]) -> dict[str, str]:
    values = {}
    for pair in pairs:
        language, sep, text = pair.partition("=")
        if not sep or not language or not text:
            sys.exit(f"--value must look like en=\"Text\", got {pair!r}")
        values[language] = text
    return values


def catalog_languages(strings: dict) -> set[str]:
    languages = set()
    for entry in strings.values():
        languages.update(entry.get("localizations", {}).keys())
    return languages


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("package")
    parser.add_argument("key")
    parser.add_argument("--comment", required=True, help="Translator context: where and how the string is shown")
    parser.add_argument("--value", action="append", required=True, metavar="LANG=TEXT")
    args = parser.parse_args()

    path = catalog_path(args.package)
    raw = path.read_text(encoding="utf-8")
    catalog = json.loads(raw)
    strings = catalog["strings"]
    values = parse_values(args.value)

    expected = catalog_languages(strings) or {catalog.get("sourceLanguage", "en")}
    missing = sorted(expected - values.keys())
    if missing:
        sys.exit(f"Missing values for {', '.join(missing)} — every catalog language needs one.")

    entry = strings.get(args.key, {})
    action = "Updated" if entry else "Added"
    entry["comment"] = args.comment
    entry["extractionState"] = "manual"
    entry["localizations"] = {
        language: {"stringUnit": {"state": "translated", "value": text}}
        for language, text in sorted(values.items())
    }
    strings[args.key] = entry

    separators = (",", " : ") if '" : ' in raw else (",", ": ")
    output = json.dumps(catalog, indent=2, ensure_ascii=False, separators=separators)
    if raw.endswith("\n"):
        output += "\n"
    path.write_text(output, encoding="utf-8")

    subprocess.run(
        ["xcrun", "xcstringstool", "generate-symbols", str(path),
         "--output-directory", str(path.parent), "--language", "swift"],
        check=True,
    )
    print(f"{action} '{args.key}' in {args.package} ({', '.join(sorted(values))}); symbols regenerated.")


if __name__ == "__main__":
    main()
