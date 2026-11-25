#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
SKIP=0
ok() { printf '[PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
skip() { printf '[SKIP] %s\n' "$1"; SKIP=$((SKIP + 1)); }

if bash -n "$ROOT/install.sh" "$ROOT/setup.sh" "$ROOT/walix-launcher.sh" "$ROOT/uninstall.sh"; then ok 'shell syntax'; else bad 'shell syntax'; fi
if python3 -m py_compile "$ROOT/walix.py"; then ok 'bootstrap Python syntax'; else bad 'bootstrap Python syntax'; fi
if python3 "$ROOT/walix.py" --version >/dev/null; then ok 'CLI version'; else bad 'CLI version'; fi
if python3 "$ROOT/walix.py" --help >/dev/null; then ok 'CLI help'; else bad 'CLI help'; fi

PAYLOAD="$ROOT/payload.bin" ROOT="$ROOT" python3 - <<'PY'
import ast, base64, hashlib, os, zlib
p = os.environ['PAYLOAD']
raw = open(p, 'rb').read()
assert raw[:5] == b'WLPY1' and len(raw) >= 37
obf = 'ZGFlci10b24tb2Q6OmRhb2x5YXA6OjEuMXYtbm9nYXJkLXhpbGF3'
key = hashlib.sha256(base64.b64decode(obf)[::-1]).digest()
body = raw[37:]
stream = b''.join(hashlib.sha256(key + i.to_bytes(4, 'big')).digest()
                  for i in range((len(body) + 31) // 32))
compressed = bytes(a ^ b for a, b in zip(body, stream))
assert hashlib.sha256(compressed).digest() == raw[5:37]
plain = zlib.decompress(compressed)
pos = 0
modules = {}
packages = set()
while pos < len(plain):
    nl = int.from_bytes(plain[pos:pos + 4], 'big'); pos += 4
    name = plain[pos:pos + nl].decode(); pos += nl
    flags = plain[pos]; pos += 1
    sl = int.from_bytes(plain[pos:pos + 4], 'big'); pos += 4
    src = plain[pos:pos + sl].decode(); pos += sl
    ast.parse(src, filename=name)
    assert name not in modules
    modules[name] = src
    if flags & 1: packages.add(name)
assert len(modules) == 14
assert {'walix_core', 'walix_core.ui', 'walix_core.web'} <= packages
assert 'decoder.eof' in open(os.path.join(os.environ['ROOT'], 'walix.py')).read()
assert 'window.__walixState' in modules['walix_core.web.whatsapp_style']
assert 'pbkdf2-sha256' in modules['walix_core.settings']
print('payload/modules: OK')
PY
if [ "$?" -eq 0 ]; then ok 'payload integrity and embedded module AST'; else bad 'payload integrity and embedded module AST'; fi

if grep -q -- '--no-remove' "$ROOT/install.sh" \
   && ! grep -qE '(^|[[:space:]])rm[[:space:]]+-rf| -delete|exec[[:space:]]+rm|rm -f' "$ROOT/install.sh" \
   && ! grep -qE 'rm -rf "\$SRC_DIR"|old zips will vanish|SELF_CLEAN=1' "$ROOT/install.sh"; then
    ok 'zero-deletion installer and source preservation'
else
    bad 'zero-deletion installer and source preservation'
fi

if python3 - <<'PY'
import os
try:
    import PyQt5  # noqa: F401
    import PyQt5.QtWebEngineWidgets  # noqa: F401
except Exception:
    raise SystemExit(2)
PY
then
    ok 'PyQt5 + QtWebEngine available'
else
    skip 'PyQt5 + QtWebEngine unavailable (GUI smoke test not run)'
fi

printf '\nSummary: %d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
