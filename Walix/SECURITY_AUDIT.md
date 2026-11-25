# Walix 1.2.1 Security Audit

This release is a hardening update based on a source-level review of v1.2.0.

## Fixed

- Popup WebEngine pages now use the same stored camera, microphone, and notification policy as the main page. Unconfigured popup permission requests fail closed instead of being silently granted.
- New installs default device permissions to **Ask**. Upgrades no longer silently turn an existing `ask` choice into `allow`; explicit saved choices are preserved.
- The protected-payload bootstrap validates size limits, module names, lengths, duplicates, UTF-8, compression errors, and empty payloads, and reports a clean reinstall message for malformed data.
- Audio-server startup no longer invokes a shell command; `systemctl` is called with an argument array.
- The privileged installer sets a restrictive umask and makes `/opt/walix` root-owned and non-writable by normal users after copying files.
- The uninstaller resolves the invoking user through `SUDO_USER`/passwd instead of relying on root's `HOME`, so session cleanup targets the correct account.

## Verification

- Python compilation: PASS
- Bash syntax for installer, launcher, and uninstaller: PASS
- Payload round-trip rebuild and integrity header: PASS
- Release archive contains no extracted `_payload_src` or readable application modules.

The wrapper still intentionally loads the official `https://web.whatsapp.com` origin only, does not inspect or record chats/calls, and retains the Kali-only and non-root runtime gates.

- Deep pass: exact-path process termination, symlink-safe data paths, corrected smoke version, and quoted installer cleanup globs.
