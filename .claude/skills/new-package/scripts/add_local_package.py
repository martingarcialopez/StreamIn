#!/usr/bin/env python3
"""Register a local Swift package in StreamIn.xcodeproj and link it to the app.

Usage:
  add_local_package.py <PackageName> [--no-link]

Adds the same eight project-file entries Xcode creates when you drag a local
package in and add its library to the app target: the package reference, the
navigator entry, the product dependency, and the framework link. Pass
--no-link for a package the app target doesn't import itself.

The file is validated with `plutil -lint` afterwards and restored if that
fails. Re-running for an already-registered package is a no-op.
"""

import argparse
import re
import secrets
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]
PBXPROJ = REPO / "StreamIn.xcodeproj" / "project.pbxproj"
ITEM_INDENT = "\t\t\t\t"
ENTRY_INDENT = "\t\t"


def new_id(text: str, taken: set[str]) -> str:
    while True:
        candidate = secrets.token_hex(12).upper()
        if candidate not in text and candidate not in taken:
            taken.add(candidate)
            return candidate


def insert_in_section(text: str, section: str, entry_id: str, entry: str) -> str:
    """Insert `entry` into the section in ID order, as Xcode keeps it (otherwise Xcode re-sorts on its next save)."""
    begin, end = f"/* Begin {section} section */\n", f"/* End {section} section */"
    if begin not in text or end not in text:
        sys.exit(f"Section {section} not found in project.pbxproj")
    section_start = text.index(begin) + len(begin)
    section_end = text.index(end, section_start)
    insert_at = section_end
    for match in re.finditer(r"^\t\t(\w{24}) ", text[section_start:section_end], re.MULTILINE):
        if match.group(1) > entry_id:
            insert_at = section_start + match.start()
            break
    return text[:insert_at] + f"{entry}\n" + text[insert_at:]


def object_block(text: str, object_id: str) -> tuple[int, int]:
    """Start and end offsets of the `ID /* … */ = { … };` block for object_id."""
    match = re.search(rf"^\t\t{object_id} (/\*.*?\*/ )?= \{{", text, re.MULTILINE)
    if not match:
        sys.exit(f"Object {object_id} not found")
    end = text.index("\n\t\t};", match.end())
    return match.start(), end


def append_to_list(text: str, object_id: str, key: str, item: str) -> str:
    """Append `item` to the `key = ( … );` list inside the given object."""
    start, end = object_block(text, object_id)
    block = text[start:end]
    list_match = re.search(rf"\n\t\t\t{key} = \(\n(.*?)\t\t\t\);", block, re.DOTALL)
    if not list_match:
        sys.exit(f"List '{key}' not found in object {object_id}")
    insert_at = start + list_match.end(1)
    return text[:insert_at] + f"{ITEM_INDENT}{item},\n" + text[insert_at:]


def find_app_target(text: str) -> str:
    for match in re.finditer(r"^\t\t(\w{24}) /\* .*? \*/ = \{\n\t\t\tisa = PBXNativeTarget;", text, re.MULTILINE):
        start, end = object_block(text, match.group(1))
        if 'productType = "com.apple.product-type.application";' in text[start:end]:
            return match.group(1)
    sys.exit("App target not found")


def frameworks_phase(text: str, target_id: str) -> str:
    start, end = object_block(text, target_id)
    phases = re.search(r"buildPhases = \((.*?)\);", text[start:end], re.DOTALL).group(1)
    for phase_id in re.findall(r"(\w{24}) /\* Frameworks \*/", phases):
        return phase_id
    sys.exit("App target has no Frameworks build phase")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("name", help="Package directory name under Packages/")
    parser.add_argument("--no-link", action="store_true", help="Register the package without linking it to the app")
    args = parser.parse_args()

    name = args.name
    relative_path = f"Packages/{name}"
    if not (REPO / relative_path / "Package.swift").exists():
        sys.exit(f"{relative_path}/Package.swift doesn't exist — scaffold the package first")

    text = PBXPROJ.read_text(encoding="utf-8")
    if f"relativePath = {relative_path};" in text:
        print(f"{name} is already registered in the project — nothing to do.")
        return

    taken: set[str] = set()
    file_ref, package_ref = new_id(text, taken), new_id(text, taken)
    product, build_file = new_id(text, taken), new_id(text, taken)
    package_comment = f'XCLocalSwiftPackageReference "{relative_path}"'

    project_id = re.search(r"rootObject = (\w{24})", text).group(1)
    main_group = re.search(r"mainGroup = (\w{24});", text).group(1)
    app_target = find_app_target(text)

    text = insert_in_section(
        text, "PBXFileReference", file_ref,
        f'{ENTRY_INDENT}{file_ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = wrapper; '
        f'name = {name}; path = {relative_path}; sourceTree = "<group>"; }};')
    text = append_to_list(text, main_group, "children", f"{file_ref} /* {name} */")
    text = insert_in_section(
        text, "XCLocalSwiftPackageReference", package_ref,
        f"{ENTRY_INDENT}{package_ref} /* {package_comment} */ = {{\n"
        f"{ENTRY_INDENT}\tisa = XCLocalSwiftPackageReference;\n"
        f"{ENTRY_INDENT}\trelativePath = {relative_path};\n"
        f"{ENTRY_INDENT}}};")
    text = append_to_list(text, project_id, "packageReferences", f"{package_ref} /* {package_comment} */")

    if not args.no_link:
        frameworks = frameworks_phase(text, app_target)
        text = insert_in_section(
            text, "XCSwiftPackageProductDependency", product,
            f"{ENTRY_INDENT}{product} /* {name} */ = {{\n"
            f"{ENTRY_INDENT}\tisa = XCSwiftPackageProductDependency;\n"
            f"{ENTRY_INDENT}\tproductName = {name};\n"
            f"{ENTRY_INDENT}}};")
        text = append_to_list(text, app_target, "packageProductDependencies", f"{product} /* {name} */")
        text = insert_in_section(
            text, "PBXBuildFile", build_file,
            f"{ENTRY_INDENT}{build_file} /* {name} in Frameworks */ = {{isa = PBXBuildFile; "
            f"productRef = {product} /* {name} */; }};")
        text = append_to_list(text, frameworks, "files", f"{build_file} /* {name} in Frameworks */")

    backup = PBXPROJ.with_suffix(".pbxproj.bak")
    shutil.copy2(PBXPROJ, backup)
    PBXPROJ.write_text(text, encoding="utf-8")
    lint = subprocess.run(["plutil", "-lint", str(PBXPROJ)], capture_output=True, text=True)
    if lint.returncode != 0:
        shutil.move(backup, PBXPROJ)
        sys.exit(f"plutil rejected the result; project file restored.\n{lint.stdout}{lint.stderr}")
    backup.unlink()

    linked = "registered" if args.no_link else "registered and linked to the app target"
    print(f"{name} {linked}. Reopen the project in Xcode if it's open.")


if __name__ == "__main__":
    main()
