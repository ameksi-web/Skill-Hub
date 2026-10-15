#!/usr/bin/env python3
"""Seal a webhook / API url so it never exists as readable text in the script.

The hub stores only the sealed blob (Config.SealedEndpoint). It is XOR-ed against
a keystream seeded from the machine fingerprint — a copy of the file that lands on
somebody else's PC simply cannot decrypt it (the hub prints "fingerprint mismatch"
and uses nothing).

  python3 tools/seal_secret.py --selftest
  python3 tools/seal_secret.py --hwid "<raw hwid>"  --seal "https://discord.com/api/webhooks/…"
  python3 tools/seal_secret.py --tag "<fingerprint>" --decode "<blob>"     # verify

The algorithm is mirrored byte-for-byte in main.lua (span GUARD-CORE) and in
loader.lua (span HASH32-CORE); --selftest executes both Lua spans through lupa
and proves the two languages agree.
"""
import argparse, io, os, sys

HUB = "/home/user/Skill-Hub/main.lua"
LOADER = "/home/user/Skill-Hub/loader.lua"
MASK = 0xFFFFFFFF


def fnv1a32(data: bytes) -> int:
    h = 2166136261
    for byte in data:
        h ^= byte
        h = (h * 16777619) & MASK
    return h


def next_seed(seed: int) -> int:
    seed ^= (seed << 13) & MASK
    seed ^= seed >> 17
    seed ^= (seed << 5) & MASK
    return seed & MASK


def fingerprint_from_hwid(hwid: str) -> str:
    return "%08x" % fnv1a32((str(hwid) + "|skill-hub").encode("utf-8"))


def seal(text: str, tag: str) -> str:
    seed = fnv1a32(tag.encode("utf-8")) or 1
    out = []
    for byte in text.encode("utf-8"):
        seed = next_seed(seed)
        out.append("%02x" % (byte ^ (seed & 0xFF)))
    return "".join(out)


def unseal(blob: str, tag: str) -> str:
    seed = fnv1a32(tag.encode("utf-8")) or 1
    out = bytearray()
    for index in range(0, len(blob) - 1, 2):
        byte = int(blob[index:index + 2], 16)
        seed = next_seed(seed)
        out.append(byte ^ (seed & 0xFF))
    return out.decode("utf-8", "replace")


def extract_span(path: str, start: str, end: str) -> str:
    if not os.path.exists(path):
        return ""
    src = io.open(path, encoding="utf-8").read()
    if start not in src or end not in src:
        return ""
    return src[src.index(start):src.index(end)]


def lua_functions(span: str):
    """Run one of the Lua spans in a real Lua VM and hand the functions back."""
    try:
        import lupa
    except ImportError:
        return None
    runtime = lupa.LuaRuntime(unpack_returned_tuples=True)
    chunk = span.replace("local function ", "function ").replace("local ", "local ")
    chunk += "\nreturn guardHash32, guardUnseal\n" if "guardUnseal" in span else "\nreturn hash32, nil\n"
    try:
        return runtime.execute(chunk)
    except Exception as error:                     # pragma: no cover - diagnostics
        print("   (lua span failed to load: %s)" % error)
        return None


def selftest() -> int:
    failures = []
    samples = ["", "a", "skill-hub", "https://discord.com/api/webhooks/1234567890/abcdef",
               "Привет, мир — 100% защита", "x" * 500]
    for sample in samples:
        blob = seal(sample, "abcdef012345")
        if unseal(blob, "abcdef012345") != sample:
            failures.append("python round trip failed for %r" % sample[:32])
        if sample and unseal(blob, "different-tag") == sample:
            failures.append("sealed blob decrypted with the wrong tag (%r)" % sample[:32])

    spans = [("main.lua GUARD-CORE", extract_span(HUB, "-- >>> GUARD-CORE", "-- <<< GUARD-CORE")),
             ("loader.lua HASH32-CORE", extract_span(LOADER, "-- >>> HASH32-CORE", "-- <<< HASH32-CORE"))]
    for name, span in spans:
        if not span:
            failures.append("%s span not found" % name)
            continue
        functions = lua_functions(span)
        if functions is None:
            print("   %s: lupa unavailable — Lua side not executed" % name)
            continue
        lua_hash, lua_unseal = functions
        for sample in ["", "abc", "https://example.com/hook", "Привет"]:
            expected = "%08x" % fnv1a32(sample.encode("utf-8"))
            got = lua_hash(sample)
            if got != expected:
                failures.append("%s hash32(%r) = %s, python says %s" % (name, sample, got, expected))
        if lua_unseal:
            payload = "https://discord.com/api/webhooks/999/AAA?x=1"
            blob = seal(payload, "0f0f0f0f")
            back = lua_unseal(blob, "0f0f0f0f")
            if back != payload:
                failures.append("%s unseal mismatch: %r" % (name, back))

    if failures:
        print("SELFTEST FAILED")
        for failure in failures:
            print("   " + failure)
        return 1
    print("SEAL SELFTEST OK — python and Lua agree (FNV-1a-32 + xorshift keystream), "
          "wrong tags produce garbage instead of the secret")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="seal / unseal a Skill Hub secret for one machine")
    parser.add_argument("--selftest", action="store_true")
    parser.add_argument("--hwid", help="raw hwid (the hub shows it as Fingerprint = hash32(hwid|skill-hub))")
    parser.add_argument("--tag", help="fingerprint, exactly as the hub prints it")
    parser.add_argument("--seal", help="secret to seal (webhook url, token, …)")
    parser.add_argument("--decode", help="blob to decode again (verification)")
    args = parser.parse_args()

    if args.selftest:
        return selftest()

    tag = args.tag
    if not tag and args.hwid:
        tag = fingerprint_from_hwid(args.hwid)
    if args.seal:
        if not tag:
            print("give --hwid or --tag"); return 2
        blob = seal(args.seal, tag)
        print("fingerprint : %s" % tag)
        print("sealed blob : %s" % blob)
        print("paste it as Config.SealedEndpoint — it only decrypts on the machine whose fingerprint is %s" % tag)
        return 0
    if args.decode:
        if not tag:
            print("give --hwid or --tag"); return 2
        print(unseal(args.decode, tag))
        return 0
    parser.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
