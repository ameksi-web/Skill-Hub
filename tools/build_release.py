#!/usr/bin/env python3
"""Build the sealed release copy of main.lua.

    python3 tools/build_release.py            # build dist/ + update loader.lua
    python3 tools/build_release.py --check    # verify dist/ still matches the loader

What "sealed" means here (be honest, it is obfuscation, not encryption):
  · every comment is replaced by spaces — so LINE NUMBERS SURVIVE EXACTLY and the
    hub's own `SkillHubStep("main.lua:1471", …)` labels keep their meaning;
  · every string literal is replaced by `__S("<seed><hex>")` — the literal text is
    decoded at runtime by a tiny XOR decoder on line 1 (the file, and therefore
    line numbering, is unchanged);
  · literals containing backslash escapes are left readable (interpretation risk
    is not worth it — they are pattern strings);
  · the checksum of the sealed payload is written into loader.lua, which refuses
    to run a payload that does not match.

A determined reader with an executor can still dump what runs; what this stops is
somebody copying the repository and reading/harvesting the source for free.
"""
import argparse, io, os, sys

ROOT = "/home/user/Skill-Hub"
SOURCE = os.path.join(ROOT, "main.lua")
DIST = os.path.join(ROOT, "dist", "skillhub.release.lua")
LOADER = os.path.join(ROOT, "loader.lua")
MASK = 0xFFFFFFFF
GOLDEN = 0x9E3779B1


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


def seal_literal(text: str, key: int, index: int) -> str:
    """<seed><hex payload> — the seed travels with the blob, the decoder is on line 1."""
    seed = (key + index * GOLDEN) & MASK
    if seed == 0:
        seed = 1
    payload = []
    for byte in text.encode("utf-8"):
        seed = next_seed(seed)
        payload.append("%02x" % (byte ^ (seed & 0xFF)))
    return "%08x%s" % ((key + index * GOLDEN) & MASK, "".join(payload))


PRELUDE = ('local __S=(function() local floor,sub,tonumber,char=math.floor,string.sub,tonumber,string.char '
           'local function m(a,b) local r=0 for _=1,32 do if b%2==1 then r=(r+a)%4294967296 end '
           'a=(a*2)%4294967296 b=floor(b/2) end return r end '
           'local function x(a,b) if type(bit32)=="table" and type(bit32.bxor)=="function" then return bit32.bxor(a,b) end '
           'local r,bit=0,1 for _=1,32 do if a%2~=b%2 then r=r+bit end '
           'a,b,bit=floor(a/2),floor(b/2),bit*2 end return r end '
           'return function(blob) local seed=tonumber(sub(blob,1,8),16) or 1 if seed==0 then seed=1 end '
           'local out={} local n=#blob for i=9,n-1,2 do local byte=tonumber(sub(blob,i,i+1),16) '
           'if not byte then return "" end seed=x(seed,(seed*8192)%4294967296) '
           'seed=x(seed,floor(seed/131072)) seed=x(seed,(seed*32)%4294967296) '
           'out[#out+1]=char(x(byte,seed%256)) end return table.concat(out) end end)();')


def seal_source(source: str, key: int):
    out, stats = [], {"sealed": 0, "skipped": 0, "comments": 0}
    index, length, counter = 0, len(source), 0
    while index < length:
        ch = source[index]

        # comments ---------------------------------------------------------
        if ch == "-" and source.startswith("--", index):
            eq = 0
            probe = index + 3
            if source.startswith("--[[", index) or source.startswith("--[=", index):
                while probe < length and source[probe] == "=":
                    eq += 1
                    probe += 1
                if probe < length and source[probe] == "[":
                    closer = "]" + "=" * eq + "]"
                    end = source.find(closer, probe)
                    end = length if end == -1 else end + len(closer)
                    block = source[index:end]
                    out.append("".join("\n" if c == "\n" else " " for c in block))
                    stats["comments"] += 1
                    index = end
                    continue
            end = source.find("\n", index)
            end = length if end == -1 else end
            out.append(" " * (end - index))
            stats["comments"] += 1
            index = end
            continue

        # long strings ([[…]]) are left as they are — they are not used as values
        if ch == "[" and source.startswith("[[", index):
            end = source.find("]]", index + 2)
            end = length if end == -1 else end + 2
            out.append(source[index:end])
            index = end
            continue

        # short strings ----------------------------------------------------
        if ch in "\"'":
            quote, cursor, body = ch, index + 1, []
            while cursor < length:
                char = source[cursor]
                if char == "\\":
                    body.append(source[cursor:cursor + 2])
                    cursor += 2
                    continue
                if char == quote or char == "\n":
                    break
                body.append(char)
                cursor += 1
            text = "".join(body)
            index = cursor + 1
            if "\\" in text or text == "":
                stats["skipped"] += 1
                out.append(quote + text + quote)
                continue
            counter += 1
            stats["sealed"] += 1
            out.append('__S("%s")' % seal_literal(text, key, counter))
            continue

        out.append(ch)
        index += 1

    return "".join(out), stats


def current_version(source: str) -> str:
    marker = 'SharedEnv.SkillHubInstance = setmetatable({\n    version = "'
    if marker in source:
        rest = source.split(marker, 1)[1]
        return rest.split('"', 1)[0]
    return "0.0"


def build(key: int) -> int:
    source = io.open(SOURCE, encoding="utf-8").read()
    sealed, stats = seal_source(source, key)

    # the decoder goes on line 1, before the (now blank) header comment: line
    # numbering of every following line is untouched
    lines = sealed.split("\n")
    lines[0] = PRELUDE + lines[0]
    payload = "\n".join(lines)

    version = current_version(source)
    checksum = "%08x" % fnv1a32(payload.encode("utf-8"))

    os.makedirs(os.path.dirname(DIST), exist_ok=True)
    io.open(DIST, "w", encoding="utf-8").write(payload)

    loader = io.open(LOADER, encoding="utf-8").read()
    loader = __import__("re").sub(r'    Build        = "v[\d.]+",', '    Build        = "v%s",' % version, loader)
    loader = __import__("re").sub(r'    ExpectedHash = "[0-9a-f]{8}",', '    ExpectedHash = "%s",' % checksum, loader)
    io.open(LOADER, "w", encoding="utf-8").write(loader)

    same_lines = len(payload.split("\n")) == len(source.split("\n"))
    leaks = [needle for needle in ("rbxassetid", "discord.com", "game:HttpGet", "GetService(\"Players\")")
             if needle in payload]

    print("sealed build  : %s" % DIST)
    print("version       : v%s   seed key: %d" % (version, key))
    print("strings sealed: %d   skipped (escapes): %d   comments blanked: %d"
          % (stats["sealed"], stats["skipped"], stats["comments"]))
    print("lines         : %d source -> %d sealed %s" % (len(source.split("\n")), len(payload.split("\n")),
                                                         "OK (line numbers preserved)" if same_lines else "MISMATCH"))
    print("payload size  : %d bytes   fnv1a32: %s" % (len(payload.encode("utf-8")), checksum))
    print("loader.lua    : Build + ExpectedHash updated")
    print("plaintext leak: %s" % ("none of the checked markers survive" if not leaks else "FOUND " + ", ".join(leaks)))
    return 0 if same_lines and not leaks else 1


def check() -> int:
    if not os.path.exists(DIST):
        print("no sealed build yet — run tools/build_release.py first")
        return 1
    payload = io.open(DIST, encoding="utf-8").read()
    loader = io.open(LOADER, encoding="utf-8").read()
    expected = __import__("re").search(r'    ExpectedHash = "([0-9a-f]{8})",', loader).group(1)
    actual = "%08x" % fnv1a32(payload.encode("utf-8"))
    if expected != actual:
        print("CHECK FAILED — loader expects %s, dist/ is %s (rebuild it)" % (expected, actual))
        return 1
    print("BUILD CHECK OK — dist/ matches the checksum loader.lua pins (%s)" % expected)
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--key", type=int, default=0x5EED1A7E)
    args = parser.parse_args()
    sys.exit(check() if args.check else build(args.key))
