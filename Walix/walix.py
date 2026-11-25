#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Walix launcher — protected distribution (v1.2.3 GUI & Security Edition).

This file contains NO application logic. Every Walix module lives encrypted
inside payload.bin next to this launcher; modules are decrypted, compiled
and executed in MEMORY only. Nothing is written to disk, so there is no
readable Walix source code anywhere on the machine.

If payload.bin is missing or corrupted the launcher refuses to run —
reinstall with:  sudo ./install.sh
"""

import base64
import hashlib
import importlib.abc
import importlib.machinery
import os
import sys
import types
import zlib

_HERE = os.path.dirname(os.path.realpath(__file__))
# The protected modules cannot derive a filesystem path from their virtual
# walix:// __file__. Publish the real asset root before importing them.
os.environ.setdefault("WALIX_ASSETS", os.path.join(_HERE, "assets"))
_PAYLOAD = os.path.join(_HERE, "payload.bin")
_MAGIC = b'WLPY1'
_OBF = 'ZGFlci10b24tb2Q6OmRhb2x5YXA6OjEuMXYtbm9nYXJkLXhpbGF3'

sys.path.insert(0, _HERE)


def _key():
    return hashlib.sha256(base64.b64decode(_OBF)[::-1]).digest()


def _keystream(n):
    key = _key()
    out = bytearray()
    counter = 0
    while len(out) < n:
        out.extend(hashlib.sha256(key + counter.to_bytes(4, "big")).digest())
        counter += 1
    return bytes(out[:n])


def _unmask(data):
    return bytes(a ^ b for a, b in zip(data, _keystream(len(data))))


def _load_payload():
    # Treat the payload as untrusted input: a damaged or replaced payload must
    # fail cleanly instead of producing an IndexError/Unicode traceback or
    # allocating unbounded decompressed data.
    MAX_RAW = 64 * 1024 * 1024
    MAX_PLAIN = 128 * 1024 * 1024
    try:
        with open(_PAYLOAD, "rb") as fh:
            raw = fh.read(MAX_RAW + 1)
    except OSError:
        sys.stderr.write("[Walix] payload.bin is missing next to walix.py — "
                         "reinstall with: sudo ./install.sh\n")
        raise SystemExit(1)
    if len(raw) > MAX_RAW:
        sys.stderr.write("[Walix] payload.bin is unexpectedly large — reinstall with: sudo ./install.sh\n")
        raise SystemExit(1)
    if raw[:len(_MAGIC)] != _MAGIC:
        sys.stderr.write("[Walix] payload.bin is not a Walix payload — "
                         "reinstall with: sudo ./install.sh\n")
        raise SystemExit(1)
    digest, body = raw[len(_MAGIC):len(_MAGIC) + 32], raw[len(_MAGIC) + 32:]
    plain = _unmask(body)
    if hashlib.sha256(plain).digest() != digest:
        sys.stderr.write("[Walix] payload.bin is corrupted — "
                         "reinstall with: sudo ./install.sh\n")
        raise SystemExit(1)
    try:
        decoder = zlib.decompressobj()
        plain = decoder.decompress(plain, MAX_PLAIN + 1)
        if len(plain) > MAX_PLAIN or decoder.unconsumed_tail or not decoder.eof or decoder.unused_data:
            raise ValueError("payload exceeds decompressed size limit")
        modules, packages = {}, set()
        pos = 0
        while pos < len(plain):
            if len(plain) - pos < 4:
                raise ValueError("truncated module name length")
            nl = int.from_bytes(plain[pos:pos + 4], "big"); pos += 4
            if nl == 0 or nl > 512 or pos + nl + 5 > len(plain):
                raise ValueError("invalid module name length")
            name = plain[pos:pos + nl].decode("utf-8"); pos += nl
            if not name or any(part in ("", ".", "..") or not part.isidentifier()
                               for part in name.split(".")):
                raise ValueError("invalid module name")
            flags = plain[pos]; pos += 1
            sl = int.from_bytes(plain[pos:pos + 4], "big"); pos += 4
            if sl > MAX_PLAIN or pos + sl > len(plain):
                raise ValueError("invalid module source length")
            src = plain[pos:pos + sl].decode("utf-8"); pos += sl
            if name in modules:
                raise ValueError("duplicate module")
            modules[name] = src
            if flags & 1:
                packages.add(name)
        if not modules:
            raise ValueError("empty payload")
        return modules, packages
    except (ValueError, UnicodeError, zlib.error) as exc:
        sys.stderr.write("[Walix] payload.bin is invalid (%s) — reinstall with: sudo ./install.sh\n" % exc)
        raise SystemExit(1)


_MODULES, _PACKAGES = _load_payload()


class _MemLoader(importlib.abc.Loader):
    """Compile the decrypted source IN MEMORY and exec it — no temp files."""

    def __init__(self, src):
        self._src = src

    def create_module(self, spec):
        return None                        # default module creation

    def exec_module(self, module):
        module.__file__ = "walix://<protected>"
        code = compile(self._src, "walix://<protected>", "exec")
        exec(code, module.__dict__)


class _MemFinder(importlib.abc.MetaPathFinder):
    def find_spec(self, fullname, path=None, target=None):
        src = _MODULES.get(fullname)
        if src is None:
            return None
        spec = importlib.machinery.ModuleSpec(
            fullname, _MemLoader(src), is_package=fullname in _PACKAGES)
        return spec


sys.meta_path.insert(0, _MemFinder())
os.environ.setdefault("WALIX_PACKED", "1")

if __name__ == "__main__":
    import walix_main
    sys.exit(walix_main.main())
