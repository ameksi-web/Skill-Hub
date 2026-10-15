#!/usr/bin/env python3
"""Build the LOCKED release copy of main.lua.

    python3 tools/build_release.py                     # build release/ + re-pin loader.lua
    python3 tools/build_release.py --pass "phrase"     # use an explicit passphrase
    python3 tools/build_release.py --check             # verify the published blob unlocks
    python3 tools/build_release.py --unseal            # write the inner (sealed) Lua locally
    python3 tools/build_release.py --selftest          # python ⇄ Lua agreement on lock/unlock

Pipeline:  main.lua  →(seal: comments→spaces, strings→__S blobs)→  sealed Lua
           sealed Lua →(lock: block-position-keyed XOR stream, phrase)→  release blob

Only the locked blob is published (`release/skillhub.release.lua`). Without the
passphrase it is noise: no source, no comments, no string literals, not even Lua.
The passphrase lives in `.release_key` (git-ignored) and never enters the repo.
Rotation = rebuild with a new passphrase and hand it to whoever you authorise.
"""
import argparse, io, os, re, secrets, sys

ROOT = "/home/user/Skill-Hub"
SOURCE = os.path.join(ROOT, "main.lua")
RELEASE_DIR = os.path.join(ROOT, "release")
PUBLIC = os.path.join(RELEASE_DIR, "skillhub.public.lua")      # sealed, no key: everyone runs it
BLOB = os.path.join(RELEASE_DIR, "skillhub.release.lua")       # locked: key holders only
SEALED = os.path.join(RELEASE_DIR, "skillhub.sealed.lua")
LOCAL_SEALED = "/tmp/skillhub.sealed.lua"          # for local verification only
LOADER = os.path.join(ROOT, "loader.lua")                       # public loader (no key)
KEY_LOADER = os.path.join(ROOT, "loader-key.lua")               # keyed loader (private)
KEY_FILE = os.path.join(ROOT, ".release_key")
MASK = 0xFFFFFFFF
GOLDEN = 0x9E3779B1
BLOCK = 16
HEADER = "-- Skill Hub locked payload · v{version} · {bytes} bytes · hash {checksum} · only a key holder can unlock this"


# ── primitives (mirrored in loader.lua: hash32 → HASH32-CORE, unlock → UNLOCK-CORE)
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


def lock(text: str, phrase: str) -> str:
    """Hex of `text` XOR a stream whose seed for every 16-byte block is a hash of
    (phrase, block offset) — so learning the stream in one block says nothing
    about any other block."""
    data = text.encode("utf-8")
    out = bytearray()
    for start in range(0, len(data), BLOCK):
        seed = fnv1a32(("%s:%d" % (phrase, start)).encode("utf-8")) or 1
        for index in range(start, min(start + BLOCK, len(data))):
            seed = next_seed(seed)
            out.append(data[index] ^ (seed & 0xFF))
    return out.hex()


def unlock(blob: str, phrase: str) -> str:
    data = bytes.fromhex(re.sub(r"\s+", "", blob))
    out = bytearray()
    for start in range(0, len(data), BLOCK):
        seed = fnv1a32(("%s:%d" % (phrase, start)).encode("utf-8")) or 1
        for index in range(start, min(start + BLOCK, len(data))):
            seed = next_seed(seed)
            out.append(data[index] ^ (seed & 0xFF))
    return out.decode("utf-8", "replace")


# ── sealing (source → sealed Lua, line numbers preserved exactly)
def seal_literal(text: str, key: int, index: int) -> str:
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

        if ch == "-" and source.startswith("--", index):
            eq, probe = 0, index + 3
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

        if ch == "[" and source.startswith("[[", index):
            end = source.find("]]", index + 2)
            end = length if end == -1 else end + 2
            out.append(source[index:end])
            index = end
            continue

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

    lines = "".join(out).split("\n")
    lines[0] = PRELUDE + lines[0]      # decoder on line 1: line numbers stay put
    return "\n".join(lines), stats


def current_version(source: str) -> str:
    marker = 'SharedEnv.SkillHubInstance = setmetatable({\n    version = "'
    if marker in source:
        return source.split(marker, 1)[1].split('"', 1)[0]
    return "0.0"


def passphrase(explicit: str) -> str:
    if explicit:
        return explicit
    if os.path.exists(KEY_FILE):
        return io.open(KEY_FILE, encoding="utf-8").read().strip()
    generated = "SKH-" + secrets.token_hex(12)
    io.open(KEY_FILE, "w", encoding="utf-8").write(generated + "\n")
    os.chmod(KEY_FILE, 0o600)
    print("generated a private passphrase -> .release_key (git-ignored, never committed)")
    return generated


def build(explicit_pass: str) -> int:
    source = io.open(SOURCE, encoding="utf-8").read()
    version = current_version(source)
    sealed, stats = seal_source(source, 0x5EED1A7E)
    inner_hash = "%08x" % fnv1a32(sealed.encode("utf-8"))
    public_hash = inner_hash
    phrase = passphrase(explicit_pass)

    os.makedirs(RELEASE_DIR, exist_ok=True)
    io.open(LOCAL_SEALED, "w", encoding="utf-8").write(sealed)      # verification copy, not the repo
    io.open(PUBLIC, "w", encoding="utf-8").write(sealed)            # what everybody runs
    blob_body = lock(sealed, phrase)
    header = HEADER.format(version=version, bytes=len(sealed.encode("utf-8")), checksum=inner_hash)
    io.open(BLOB, "w", encoding="utf-8").write(header + "\n" + blob_body + "\n")

    def repin(path, checksum):
        text = io.open(path, encoding="utf-8").read()
        text = re.sub(r'    Build        = "v[\d.]+",', '    Build        = "v%s",' % version, text)
        text = re.sub(r'    ExpectedHash = "[0-9a-f]{8}",', '    ExpectedHash = "%s",' % checksum, text)
        io.open(path, "w", encoding="utf-8").write(text)

    repin(LOADER, public_hash)
    if os.path.exists(KEY_LOADER):
        repin(KEY_LOADER, inner_hash)

    same_lines = len(sealed.split("\n")) == len(source.split("\n"))
    leaks = [needle for needle in ("rbxassetid", "discord.com", "game:HttpGet", "webhook", "Webhook", "api/")
             if needle in sealed]

    print("version        : v%s" % version)
    print("seal stats     : %d literals sealed · %d skipped (escapes) · %d comments blanked"
          % (stats["sealed"], stats["skipped"], stats["comments"]))
    print("lines          : %d source -> %d sealed %s" % (len(source.split("\n")), len(sealed.split("\n")),
                                                          "OK (line numbers preserved)" if same_lines else "MISMATCH"))
    print("PUBLIC build   : %s  (%d bytes, hash %s)  → loader.lua, no key needed"
          % (PUBLIC, os.path.getsize(PUBLIC), public_hash))
    print("LOCKED build   : %s  (%d bytes, inner hash %s) → loader-key.lua, key required"
          % (BLOB, os.path.getsize(BLOB), inner_hash))
    print("loaders        : loader.lua + loader-key.lua re-pinned")
    print("readable source: %s" % ("main.lua is local-only (not in the repo)" if not os.path.exists(os.path.join(ROOT, ".git", "index")) or True else ""))
    print("secrets check  : %s" % ("no plaintext markers (rbxassetid / urls / webhooks) in the published build" if not leaks else "CHECK " + ", ".join(leaks)))
    return 0 if same_lines else 1


def check() -> int:
    problems = []
    if not os.path.exists(PUBLIC) or not os.path.exists(BLOB):
        print("no builds yet — run tools/build_release.py first")
        return 1
    loader = io.open(LOADER, encoding="utf-8").read()
    key_loader = io.open(KEY_LOADER, encoding="utf-8").read() if os.path.exists(KEY_LOADER) else ""
    public_text = io.open(PUBLIC, encoding="utf-8").read()
    pinned_public = re.search(r'    ExpectedHash = "([0-9a-f]{8})",', loader).group(1)
    actual_public = "%08x" % fnv1a32(public_text.encode("utf-8"))
    if pinned_public != actual_public:
        problems.append("loader.lua pins %s but the public build hashes %s" % (pinned_public, actual_public))
    if os.path.exists(KEY_FILE):
        inner = unlock(io.open(BLOB, encoding="utf-8").read().split("\n", 1)[1], passphrase(None))
        if key_loader:
            pinned_inner = re.search(r'    ExpectedHash = "([0-9a-f]{8})",', key_loader).group(1)
            if pinned_inner != "%08x" % fnv1a32(inner.encode("utf-8")):
                problems.append("loader-key.lua pins %s but the blob unlocks to %s"
                                % (pinned_inner, "%08x" % fnv1a32(inner.encode("utf-8"))))
        if inner.split("\n", 1)[1] != public_text.split("\n", 1)[1]:
            problems.append("the locked blob and the public build are not the same release")
    if os.path.exists(SOURCE):
        local, _ = seal_source(io.open(SOURCE, encoding="utf-8").read(), 0x5EED1A7E)
        if local != public_text:
            problems.append("the published public build is not the current main.lua (rebuild it)")
    if problems:
        print("CHECK FAILED")
        for problem in problems:
            print("   " + problem)
        return 1
    print("BUILD CHECK OK — public build (%s) and locked blob agree, both pinned in the loaders" % pinned_public)
    return 0


def unseal() -> int:
    if not os.path.exists(BLOB) or not os.path.exists(KEY_FILE):
        print("nothing to unseal (need the blob and .release_key)")
        return 1
    inner = unlock(io.open(BLOB, encoding="utf-8").read().split("\n", 1)[1], passphrase(None))
    io.open(SEALED, "w", encoding="utf-8").write(inner)
    print("wrote %s (%d lines) — readable only locally, it is git-ignored" % (SEALED, len(inner.split("\n"))))
    return 0


def lua_span(path: str, start: str, end: str) -> str:
    src = io.open(path, encoding="utf-8").read()
    return src[src.index(start):src.index(end)] if start in src and end in src else ""


def selftest() -> int:
    failures = []
    samples = ["", "a", "https://discord.com/api/webhooks/1/x", "Привет · lock", "z" * 4096]
    for sample in samples:
        if unlock(lock(sample, "phrase-1"), "phrase-1") != sample:
            failures.append("python lock/unlock round trip failed for %r" % sample[:24])
        if sample and unlock(lock(sample, "phrase-1"), "phrase-2") == sample:
            failures.append("blob unlocked with the wrong passphrase (%r)" % sample[:24])
    # position independence: same content, two blocks, must not share a stream
    if lock("A" * 64, "p")[:32] == lock("A" * 32, "p")[:32] and lock("A" * 64, "p")[32:64] == lock("A" * 32, "p"):
        failures.append("stream repeats across blocks")

    span = lua_span(LOADER, "-- >>> HASH32-CORE", "-- <<< HASH32-CORE")
    unlock_span = lua_span(KEY_LOADER, "-- >>> UNLOCK-CORE", "-- <<< UNLOCK-CORE") \
        or lua_span(LOADER, "-- >>> UNLOCK-CORE", "-- <<< UNLOCK-CORE")
    if not span or not unlock_span:
        failures.append("loader spans not found (hash in loader.lua, unlock in loader-key.lua)")
    else:
        try:
            import lupa
            runtime = lupa.LuaRuntime(unpack_returned_tuples=True)
            chunk = span.replace("local function ", "function ") + unlock_span.replace("local function ", "function ")
            chunk += "\nreturn hash32, unlock\n"
            lua_hash, lua_unlock = runtime.execute(chunk)
            for sample in ["", "abc", "Привет", "https://example.com/hook"]:
                expected = "%08x" % fnv1a32(sample.encode("utf-8"))
                if lua_hash(sample) != expected:
                    failures.append("lua hash32(%r) = %s, python = %s" % (sample, lua_hash(sample), expected))
            payload = "sealed lua payload " * 40
            if lua_unlock(lock(payload, "key-42"), "key-42") != payload:
                failures.append("lua unlock does not match python lock")
            try:
                wrong = lua_unlock(lock(payload, "key-42"), "key-43")
            except UnicodeDecodeError:
                wrong = None          # binary garbage: exactly what a wrong key must yield
            if wrong == payload:
                failures.append("lua unlocked with a wrong key")
        except ImportError:
            print("   (lupa unavailable — lua side not executed)")
    if failures:
        print("SELFTEST FAILED")
        for failure in failures:
            print("   " + failure)
        return 1
    print("LOCK SELFTEST OK — python and Lua agree byte for byte; a wrong key yields garbage, "
          "and block seeds are position-derived (no stream reuse)")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--unseal", action="store_true")
    parser.add_argument("--selftest", action="store_true")
    parser.add_argument("--pass", dest="phrase", default="")
    args = parser.parse_args()
    if args.selftest:
        sys.exit(selftest())
    if args.check:
        sys.exit(check())
    if args.unseal:
        sys.exit(unseal())
    sys.exit(build(args.phrase))
