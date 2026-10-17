#!/usr/bin/env python3
"""Wrap SkillAnimator/init.lua into a Roblox model file (.rbxmx) that Studio
loads as a local plugin.

    python3 tools/build_plugin_rbxmx.py

The output, SkillAnimator/SkillAnimator.rbxmx, is a version-4 Roblox XML model
whose root item is a single `Script` holding the plugin source. Dropped into
the Studio Plugins folder (or installed with "Plugins Folder…"), Studio runs
that Script as a local plugin exactly like a .lua file — this is the same shape
Studio itself produces with right-click → "Save as Local Plugin…".

Why a generator instead of a checked-in blob: the source stays the single
source of truth, so the .rbxmx can always be rebuilt and never drifts. The
script verifies the round trip at the end — the Source it wrote is parsed back
out of the XML and compared byte for byte with init.lua.
"""
import io
import os
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SOURCE = os.path.join(ROOT, "SkillAnimator", "init.lua")
OUTPUT = os.path.join(ROOT, "SkillAnimator", "SkillAnimator.rbxmx")
PLUGIN_NAME = "SkillAnimator"

HEADER = (
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
)

TEMPLATE = """\t<Item class="Script" referent="RBX0">
\t\t<Properties>
\t\t\t<string name="Name">{name}</string>
\t\t\t<bool name="Disabled">false</bool>
\t\t\t<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>
\t\t</Properties>
\t</Item>
"""

FOOTER = "</roblox>\n"


def cdata_escape(text: str) -> str:
    """A CDATA section cannot contain `]]>`; split it the standard way."""
    return text.replace("]]>", "]]]]><![CDATA[>")


def strip_invalid_xml(text: str) -> str:
    """XML 1.0 forbids most control characters — a stray one would make Studio
    silently refuse the whole plugin file."""
    return "".join(
        ch for ch in text
        if ch in "\t\n\r" or ord(ch) >= 0x20
    )


def main() -> int:
    if not os.path.exists(SOURCE):
        print("source not found at %s" % SOURCE)
        return 1

    raw = io.open(SOURCE, encoding="utf-8").read()
    source = strip_invalid_xml(raw)
    if source != raw:
        print("note: %d control character(s) removed" % (len(raw) - len(source)))

    xml = HEADER + TEMPLATE.format(name=PLUGIN_NAME, source=cdata_escape(source)) + FOOTER
    io.open(OUTPUT, "w", encoding="utf-8", newline="\n").write(xml)

    # ── verify: parse the file back and compare the Source property ────────
    tree = ET.parse(OUTPUT)
    root = tree.getroot()
    if root.tag != "roblox":
        print("FAIL root tag is %r" % root.tag)
        return 1
    items = root.findall("Item")
    if len(items) != 1 or items[0].get("class") != "Script":
        print("FAIL expected exactly one Script item")
        return 1
    props = {child.get("name"): child for child in items[0].find("Properties")}
    if props["Name"].text != PLUGIN_NAME:
        print("FAIL name is %r" % props["Name"].text)
        return 1
    restored = props["Source"].text or ""
    if restored != source:
        print("FAIL source round trip differs (%d vs %d chars)" % (len(restored), len(source)))
        return 1
    if not restored.rstrip().endswith("return StudioAnimator"):
        print("FAIL source does not end with the plugin's return statement")
        return 1

    size = os.path.getsize(OUTPUT)
    print("wrote %s" % os.path.relpath(OUTPUT, ROOT))
    print("  %d bytes · %d lines of Lua in a single Script item" % (size, source.count("\n") + 1))
    print("  round trip: OK (Source parsed back identical)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
