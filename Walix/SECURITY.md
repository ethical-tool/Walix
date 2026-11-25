# Security Policy — Walix

Walix is an **unofficial** desktop wrapper around `https://web.whatsapp.com`
for Kali Linux. It is **not** affiliated with, endorsed by, or connected to
WhatsApp LLC or Meta Platforms, Inc. It is designed to access **your own**
WhatsApp account and contains no spying, interception, extraction or
monitoring functionality — by design and by review.

## Reporting a vulnerability

Please open a GitHub issue titled `security: <summary>` (or contact the
maintainer privately if the issue includes account-sensitive detail). Include
the affected file, a minimal reproduction and the Kali version. Fixes ship in
the next release; this file documents the controls that a fix must preserve.

## Implemented controls (v1.1.0 Dragon Edition)

1. **Kali-only enforcement** — the app, the launcher and the installer all
   parse the exact `ID=` field of `/etc/os-release` and refuse missing,
   malformed or non-Kali systems. Identical rules in bash and python,
   covered by `tests/test_kali_detection.{py,sh}`.
2. **Never as root** — the launcher refuses root (harmless flags excepted);
   the WhatsApp session belongs to your normal user.
3. **Exact-origin render allow-list** — only the EXACT `about:blank`
   bootstrap URL and the exact `https://web.whatsapp.com:443` origin may
   load in a Walix window. Every other top-level target — chat links,
   `target=_blank` popups, redirects, plain `http:`, other `about:` pages
   (about:config, …), `javascript:`, `data:`, `file:` — is kept out of the
   app and routed to the system-browser path. Untrusted pages can never
   render inside Walix.
4. **Origin validation details** — the trust check verifies the scheme, the
   exact hostname, the default port (443 — `https://web.whatsapp.com:8443/`
   is NOT the app origin) and rejects URLs carrying user-information
   (`https://user@web.whatsapp.com/`), a classic phishing vector.
4b. **Why not `*.whatsapp.com` subdomains?** Arbitrary subdomains would widen
   the render surface for no user benefit; `web.whatsapp.com` is the app
   origin. Sub-frame assets (CDN hosts like `static.whatsapp.com`) keep
   working because Qt only polices top-level navigations. Documented
   decision, not an oversight — enforced in `walix_core/webview.py` and
   tested in `tests/test_permissions_mock.py`.
5. **Approved external schemes only** — the system browser receives ONLY
   `http:`, `https:` and `mailto:` URLs (`EXTERNAL_SCHEMES` +
   `is_allowed_external_url()`), enforced in BOTH external paths:
   `MainWindow._open_external` and the popup callback inside
   `WalixView.createWindow` (fixed in v1.2.2 — it previously called
   `QDesktopServices.openUrl` unfiltered). The popup dialog closes after
   every external navigation, allowed or blocked. `javascript:`, `data:`,
   `file:`, `about:`, `blob:` and unknown schemes are dropped — a crafted
   link cannot turn Walix into a launcher for dangerous targets, from the
   main window or a popup.
5b. **Blob-origin unwrapping** — `blob:` URLs carry their real origin inside
   (`blob:https://web.whatsapp.com/…`). The trust check unwraps and verifies
   the embedded origin, so a hostile `blob:http://evil.example/x` can never
   receive device permissions or pass as WhatsApp.
6. **User-controlled device permissions** — microphone, camera and desktop
   notifications are granted only to web.whatsapp.com, only for the feature
   requested, and only per the user's setting (ask / always allow / always
   deny; Settings → Privacy & Data). "Ask" shows a dialog with "Remember
   this choice". Offscreen/automation never grants.
7. **Hardened WebEngine settings** — JavaScript clipboard access disabled,
   media autostart requires a user gesture, **hyperlink auditing disabled
   (new in 1.0.0 — the engine cannot act as a tracking beacon)**, DevTools
   disabled by default (Settings opt-in), fullscreen support enabled so
   in-app video calls can go fullscreen, GPU compositing auto-disabled
   inside VMs (smart `hardware_accel` — full GPU only on real hardware).
7c. **Kali styling injection is cosmetics-only (v1.1.0)** — the injected
   WhatsApp Web script (`walix_core/web/whatsapp_style.py`) performs DOM/CSS
   changes only (border-radius on avatars, scrollbar colours, a decorative
   watermark div). It never touches message content, network traffic,
   cookies or storage, is served only from the local profile and can be
   disabled in Settings → Appearance.
7d. **Privacy Lock PIN (v1.1.0)** — the optional PIN is stored exclusively
   as a salted SHA-256 hash inside `~/.config/walix/settings.json` (which is
   chmod 0600); the plain PIN never touches disk. Wrong input keeps the
   shield up; keyboard shortcuts cannot bypass a PIN-protected shield.
7e. **Code protection, honestly labelled (v1.1.0)** — the release packs all
   Walix modules into one zlib-compressed, XOR-keystream-masked
   `payload.bin` with a SHA-256 integrity header, decrypted and compiled
   IN MEMORY by a source-free bootstrap. This is obfuscation against casual
   tampering, NOT cryptography against a determined reverse-engineer: the
   key material ships inside the bootstrap by necessity. The security
   posture does not depend on it — the controls above hold with or without
   readable sources, and every module stays reviewable in the source tree.
7b. **Call permission scope (v1.0.0, hardened in v1.1.0)** — in-app voice/video calls use the
   same permission machinery as before: only `MediaAudioCapture`,
   `MediaVideoCapture` and `MediaAudioVideoCapture` from the exact app
   origin can ever be granted, only per the user's stored mode, and the
   media itself never passes through Walix — calls remain WhatsApp's own
   end-to-end WebRTC stack. `walix --doctor` and the Settings → Calls
   device check only READ `/dev/video*` and run `pactl info`; they never
   open a camera or microphone.
8. **Session data protection** — `~/.config/walix` (settings + WebEngine
   profile with cookies) and cache dirs are `0700`; `settings.json` is
   written atomically with `0600` and re-chmodded if found loose.
9. **Downloads** — every download goes through a system save dialog; the
   app never writes outside the user-chosen path.
10. **Precise process management** — `walix --kill` and the uninstaller
    match python interpreters running exactly `walix.py`, verify each PID's
    `/proc/<pid>/cmdline` before signalling, and verify termination. No
    broad `pkill -f` that could hit unrelated processes.
11. **Conservative dependency handling** — apt packages from Kali's own
    repos first; an isolated venv under `/opt/walix/venv` second
    (integrity-checked, removed when broken); `--break-system-packages`
    only as a labelled last resort. The installer fails loudly instead of
    continuing with a broken engine.
12. **Clean logs** — `~/.cache/walix/error.log` holds tracebacks only; the
    installer logs environment variable NAMES (never values) when
    forwarding a graphical session; nothing session-related is logged.

## Data locations

| Path | Contents | Removal |
| --- | --- | --- |
| `~/.config/walix` | settings.json + WebEngine profile (cookies) | `walix-uninstall` session prompt, or `walix --reset` |
| `~/.cache/walix` | cache + error.log | uninstaller / `walix --reset` |
| `/opt/walix` | program files (incl. optional venv) | `walix-uninstall` |

## Known limitations

- Walix trusts WhatsApp's own page code as much as any browser does — it is
  a wrapper, not a sandbox around WhatsApp's JavaScript.
- Voice/video call media permissions are granted per user choice; calls
  themselves are WhatsApp's own WebRTC stack, not Walix code.
