#!/usr/bin/env python3
"""Turn a sealed Skill Hub build back into readable Lua.

`tools/build_release.py` replaces every string literal in `main.lua` with
`__S("<hex>")`, where the hex blob starts with the 32-bit seed of that literal
and continues with the literal XOR a xorshift keystream. The seed travels
*inside* the blob, so the transform is reversible without any key:

    python3 tools/unseal_literals.py release/skillhub.sealed.lua main.lua

Comments cannot be recovered (the sealer blanks them so line numbers survive).
Everything else — code, structure and every literal — comes back exactly, which
`python3 tools/build_release.py --check` proves: re-sealing the recovered file
must reproduce the published sealed build byte for byte.
"""
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_release as br  # noqa: E402

MASK = 0xFFFFFFFF
GOLDEN = 0x9E3779B9
CALL = re.compile(r'__S\("([0-9a-fA-F]+)"\)')


def decode_literal(blob: str) -> str:
    seed = int(blob[:8], 16) or 1
    out = bytearray()
    body = blob[8:]
    if len(body) % 2:
        raise ValueError("odd hex payload")
    for index in range(0, len(body), 2):
        byte = int(body[index:index + 2], 16)
        seed ^= (seed << 13) & MASK
        seed ^= seed >> 17
        seed ^= (seed << 5) & MASK
        seed &= MASK
        out.append(byte ^ (seed & 0xFF))
    return out.decode("utf-8")


def quote(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def unseal(source: str):
    stats = {"literals": 0}

    def replace(match):
        stats["literals"] += 1
        return quote(decode_literal(match.group(1)))

    text = CALL.sub(replace, source)
    if text.startswith(br.PRELUDE):
        text = text[len(br.PRELUDE):]
    return text, stats


def main() -> int:
    sealed_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(br.RELEASE_DIR, "skillhub.sealed.lua")
    out_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(br.ROOT, "main.lua")

    if not os.path.exists(sealed_path):
        print("no sealed build at %s — run tools/build_release.py --unseal first" % sealed_path)
        return 1

    source = io.open(sealed_path, encoding="utf-8").read()
    if "__S(" not in source:
        print("%s is not a sealed build (no __S calls) — nothing to do" % sealed_path)
        return 1

    text, stats = unseal(source)
    if "__S(" in text:
        print("REFUSING: %d __S calls survived decoding" % text.count("__S("))
        return 1
    io.open(out_path, "w", encoding="utf-8").write(text)

    lines = text.split("\n")
    blanks = sum(1 for line in lines if line.strip() == "")
    print("wrote %s — %d lines, %d literals restored, %d blank lines (comments were not recoverable)"
          % (out_path, len(lines), stats["literals"], blanks))

    # prove it round-trips: sealing the recovered file must reproduce the input
    resealed, _ = br.seal_source(text, 0x5EED1A7E)
    if resealed == source:
        print("ROUND TRIP OK — re-sealing the recovered source reproduces the sealed build byte for byte")
        return 0
    print("ROUND TRIP MISMATCH — the recovered file differs from the sealed build")
    return 1


if __name__ == "__main__":
    sys.exit(main())
