## v1.2.5 — THE LAUNCH FIX (Kali field report: "tool launch nahi ho raha")

Field report: the installer finished all green, `Start Walix now? y` printed
"The Walix process exited immediately", and no window ever appeared.

> **Based on the v1.2.4 application code** — every v1.2.4 app fix is carried
> over (PIN record keeper, pactl "Mute: yes" sound-check parsing, idle
> auto-lock, Kali Console `:dragon`, About-dialog egg lookup) plus the two
> v1.2.4 installer fixes (helper functions defined before the argument case;
> the `pulseaudio` server package is skipped when PipeWire/PulseAudio is
> already running, so the working sound stack is never replaced).

### Fixed — the installer that killed its own app (THE launch bug)
- **Root cause found and fixed**: `install.sh` runs with `umask 077`, so every
  file copied to `/opt/walix` landed **root-only** (`0600` files, `0700`
  directories). The follow-up `chmod -R go-w` only removes write bits — it
  never restores read access. Result: the desktop user could not even enter
  `/opt/walix`, the launcher failed `-f /opt/walix/walix.py` and died with
  "App files not found" **before Qt could load** — a silent instant exit.
- The root self-test `walix --version` kept passing (root reads everything),
  which is why the installer printed all-green checks. Permissions are now
  normalised explicitly: directories `0755`, files `0644`, entry scripts
  `0755` — still root-owned and non-writable (same security model, now
  actually readable). A final step **proves** the desktop user can read
  `payload.bin` and aborts the install otherwise.
- The launcher smoke-check now runs **as the desktop user** as well
  (`sudo -u "$SUDO_USER" walix --version`) — a root-only pass no longer
  counts as success.
- **Every installed hicolor icon** is `0644` again — under umask 077 the menu
  icon landed `0600` and silently vanished from the Kali menu.
- `install-launch.log` is created **owned by the desktop user** (`0644`) —
  it used to be root-only, so the user could not read the very error log the
  installer told them to read. The installer's own `/tmp` log is `0644` too.
- The optional pip venv is `chmod -R a+rX` after creation (it used to be
  root-only `0700` under umask 077 — unusable by the desktop user).

### Fixed — misleading launcher diagnostics
- `walix-launcher.sh` now distinguishes **"files missing"** from **"files
  unreadable"**: on a root-only `/opt/walix` it prints the actual directory
  permissions and the exact repair command (`sudo chmod -R a+rX /opt/walix`)
  instead of the old misleading "App files not found". A unreadable
  `payload.bin` is caught before Python can show a raw traceback.

### Fixed — brittle smoke test
- `run_smoke()` asserted `APP_VERSION == "1.2.3"` **hardcoded** — the
  self-test failed on every new release. It now validates the version
  format instead of pinning one exact number.

### Upgrade notes
- Existing installs can be repaired without reinstalling:
  `sudo chmod -R a+rX /opt/walix` — then start `walix` normally.
- Or reinstall from this package: `sudo bash install.sh` (installer now
  verifies the launcher **as your user**, so this bug can never ship again).

## v1.2.3 — GUI & lifecycle hardening

- Fixed clean WebEngine shutdown/profile ownership and popup-window leaks.
- Settings now apply toolbar, fullscreen, HUD, theme, zoom and audio state immediately.
- Dialogs resize safely on small Kali VM/laptop screens.
- Permission controls now consistently describe the fail-closed `Ask` default.

# Changelog — Walix

All notable changes to Walix are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions are SemVer-style.
Walix is an unofficial community project — not affiliated with WhatsApp or Meta.

## [1.2.1] — 2026-11-25

The **sound hotfix** — field report on 1.1.1: *"video to chal gaya lekin
awaaz nahi aa rahi"* (the video now plays but the sound is missing), plus
an installer that died with `E: Regex compilation error - Unmatched [`.
Every 1.1.1 fix is carried over.

### Fixed — the installer that broke its own audio stack
- **Root cause found and fixed**: `filter_available()` in `install.sh` runs
  inside `$( )` command substitution, but its `warn` diagnostics were printed
  to **stdout** — so the captured "package list" contained literal words like
  `skipping`, `unavailable`, `package:` and the ANSI `[ ! ]` colour codes.
  `apt-get install` then failed with `E: Regex compilation error - Unmatched [`,
  **every** package (including PulseAudio/ALSA) stayed uninstalled, and the
  silent pip fallback took over — videos decoded but had no audio server to
  play through. All filter diagnostics now go to **stderr**.
- **Two-phase apt install**: phase A installs the *audio + runtime libraries*
  (`libasound2`/`libasound2t64`, `pulseaudio`, `pulseaudio-utils`, `libpulse*`,
  X/GL/NSS stack) **first**, so even when the Qt engine must come from the pip
  fallback, the sound stack is already on disk. Phase B installs
  `python3-pyqt5 + qtwebengine` and now *proves the import* before calling it
  a success.
- `pulseaudio-utils` ships in every install — `pactl` backs all audio checks.

### Fixed — videos play but the sound is silent
- **XDG_RUNTIME_DIR is the PulseAudio socket path**, and it was never
  inherited by the launch chain (`sudo -u kira env DISPLAY=… walix` only
  passed DISPLAY/DBUS/XAUTHORITY — and only set the runtime dir for
  *Wayland* launches). Chromium could not find `…/pulse/native`, fell back
  to raw ALSA and played **silently**. Now:
  1. the installer launch env always carries `XDG_RUNTIME_DIR` (+ `PULSE_SERVER`),
  2. `walix-launcher.sh` exports it for the real user when missing,
  3. `walix.py::_apply_audio_env()` defaults it before QApplication as the
     last safety net.
- **Test sound (View menu)** plays a generated two-tone WAV *inside the
  WhatsApp page* — the same Chromium audio path voice notes and status
  videos take. A true end-to-end check, no QtMultimedia needed.
- **Audio help / no-sound fix (View menu + status-bar Sound badge)**: a
  non-modal troubleshooter that live-probes root session, XDG_RUNTIME_DIR,
  audio server, muted sink, ALSA library and the media engine — and prints
  the exact fix command for every failing check (`pactl set-sink-mute
  @DEFAULT_SINK@ 0`, `pulseaudio --start`, engine swap, …).
- The badge turns green ("Sound: on") / grey ("muted") / red ("check me")
  based on a one-shot probe 2.5 s after the first successful load; a
  one-time status hint names the broken check (`audio_warn_shown`).
- **`walix --doctor` gained an Audio output section** with the same checks.
- User-supplied `QTWEBENGINE_CHROMIUM_FLAGS` keep working, but the autoplay
  policy flag is appended when missing (the status-video guarantee).

### Added — Kali-style GUI (the "like other Kali apps" request)
- **A proper main toolbar** — Home / Reload / Lock / Theme / Console /
  Settings, one click each, fully themed by all five palettes, hideable via
  View → Show toolbar (`toolbar` setting).
- **Theme button on the toolbar** cycles dark → dragon → amoled → classic
  green → light without opening Settings.

### Changed
- `install.sh` VERSION/banner/final-box → 1.2.1 with the sound line.
- New test suite `tests/test_v120_fixes.py`:
  installer capture bug (stderr redirect), runtime-phase + libasound names,
  launcher/app XDG env, `_apply_audio_env` preservation, `audio_diagnostics()`
  shape, real-WAV tone, toolbar QSS in all five themes, settings keys.

## [1.1.1] — 2026-11-25

The **media hotfix** — field reports on 1.1.0: "status videos do not open or
play", "the tool feels laggy", "the icon is still the old one", "many small
bugs". All four are addressed head-on; every 1.1.0 feature is carried over.

### Fixed — status & chat videos (the big one)
- **Root cause found and fixed**: two independent blockers stopped every
  WhatsApp video.
  1. `PlaybackRequiresUserGesture` was set **True** in the profile — WhatsApp
     starts status videos and call ringtones *programmatically*, so those
     videos sat frozen on the first frame. It is now **False** (in sync with
     the `--autoplay-policy=no-user-gesture-required` Chromium flag; the
     Mute audio setting still silences everything on request).
  2. **The pip wheel engine cannot decode H.264/AAC at all** (probed via
     `canPlayType`: h264 = "", vp9/opus = "probably"): pip wheels of
     PyQtWebEngine are built without the proprietary codecs, and the
     launcher/installer used to *prefer* that engine. The Kali **apt build**
     (`python3-pyqt5.qtwebengine`, `-proprietary-codecs`) has them. So:
- **The launcher now prefers the system apt engine** and only falls back to
  the venv when the system Qt is really broken (with an on-screen hint).
- **The installer verifies the codec** with an offscreen `canPlayType` probe
  ("Media codecs verified — status/chat videos WILL play") and switches away
  from a codec-less venv automatically.
- **Walix self-checks after the first load**: a one-time warning dialog with
  the exact fix commands appears when the running engine cannot decode
  H.264 (`media_warn_shown` setting); the status bar shows a persistent note.
- **`walix --doctor` prints the media engine verdict** — "pip wheel — NO
  H.264 ✘" with the fix command, or "Kali apt build — H.264 ✔".

### Fixed — lag on software rendering
- **Smooth scrolling now follows the GPU decision**: the scroll animator is
  disabled whenever Chromium runs on the software rasteriser (VMs / GPU off,
  where `--disable-gpu` is set) — that combination was the "tool feels
  laggy" report. GPU-accelerated machines keep the smooth animation.

### Fixed — the stale icon
- **All bitmap assets are regenerated from the Dragon emblem** (scripted,
  not hand-stale): `assets/icon.png` 512 px, `icon-256/128/64/48/32/24/16`,
  tray, splash and the README banner now all show the same fresh mark.
- **The installer ships the icon into EVERY hicolor size**
  (512→16 px `walix.png`) so menu, taskbar, alt-tab and notifications can
  never fall back to a stale icon; the uninstaller cleans all sizes.
- **Popups now carry the dragon icon too** (the taskbar used to show a
  generic Qt icon for popup windows).

### Fixed — bug hardening
- **Renderer crash auto-recovery**: a crashed renderer process (heavy status
  viewer, OOM in a VM) no longer leaves a dead grey window — Walix logs it,
  reloads automatically (max 3 consecutive attempts) and resets on success.
- The stealth-title status line now uses the real `APP_VERSION` (was a
  hardcoded string).

### Changed
- `install.sh` VERSION strings, banner and installer messages → 1.1.1.
- New test suite `tests/test_v111_fixes.py` — playback policy, codec probe,
  engine detection, installer/launcher logic, asset integrity (pixel-level
  Kali-blue check) and the doctor media section.

## [1.1.0] — 2026-11-25

The **Dragon Edition** — the full Kali redesign + the call fix users asked
for. Built on the 1.0.0 Call Edition foundation; every 1.2.2/1.0.0 security
control is carried over.

### Fixed — calls (the big one)
- **Calls now work out of the box** — microphone/camera/notifications default
  to **Always allow** for web.whatsapp.com (was "ask", which users missed).
  A one-time migration upgrades existing installs (`migrated_v11` marker);
  explicit user choices are never overridden.
- **The permission flow is attached to EVERY page** (main view + popups) via
  `attach_media_permissions()` — previously a voice-note/call popup could
  never get device access.
- **Silent audio-server autostart** (`ensure_pulseaudio()`) before WhatsApp
  loads — voice calls no longer fail in minimal sessions/VMs.
- **`--autoplay-policy=no-user-gesture-required`** — incoming call rings
  actually play sound.
- **Settings → Calls gets a real troubleshooter**: a live in-page
  `getUserMedia` test ("Test mic & camera inside WhatsApp"), a
  **Reset permissions → Allow** button and a 3-probe device check
  (audio server, microphone capture sources, camera).

### Added — Dragon Edition look
- **The Walix Dragon** — an original low-poly dragon mark drawn in the
  official Kali colours (cyan #23BAC2 → Kali blue #2777FF, verified from the
  official kali.org artwork), rendered as SVG via QSvgRenderer with a pure
  QPainter fallback; used as app icon, tray icon, splash emblem and shield.
- **The full UI now speaks Kali** — every theme rebuilt on the official
  palette: cyan→blue gradient primary buttons, glowing focus rings, cyber
  menus/tabs/tooltips, slim neon scrollbars.
- **Kali boot splash recoloured** — blue/cyan matrix rain, Kali gradient
  progress bar, dragon emblem, "KALI DRAGON" tagline.

### Added — WhatsApp Web styling (injected, live)
- **Circular profile avatars** inside WhatsApp Web (chat list, header,
  profile panel) — stable attribute selectors + a careful size/squareness
  heuristic for blob: avatars, via a MutationObserver.
- **Kali styling inside the page** — neon scrollbars, Kali-blue selection.
- **Dragon watermark** — a small Walix dragon on the chat canvas.
- All three are toggles in Settings → Appearance and apply WITHOUT a reload
  (QWebEngineScript at DocumentCreation + live `runJavaScript` re-apply).

### Added — Kali Console (Ctrl+K)
- Terminal-flavoured **command palette**: `:lock`, `:unlock`, `:theme <key>`,
  `:hud`, `:reload`, `:clear`, `:zoom in/out/100`, `:fullscreen`, `:mute`,
  `:top`, `:settings`, `:calls`, `:about`, `:help`, `:quit` + easter eggs.
- Dispatch lives in `MainWindow.console_cmd()`; every command returns a
  status line shown inside the console.

### Added — privacy
- **Privacy Lock PIN** — optional 4–8 char PIN; the shield only opens for
  the correct PIN (raw keys/clicks can never bypass it). Stored ONLY as a
  salted SHA-256 hash (`settings.py:hash_pin/verify_pin`).
- **Idle auto-lock** — hides chats after N idle minutes (0–120, default 5).
- **Hide notification previews** — tray/notify-send alerts become
  "New message — previews hidden in Walix".
- **Stealth title** — the window shows `walix@kali: ~` instead of "WhatsApp".

### Added — packaging
- **Code protection** — the release ships as a zlib+XOR keystream-encrypted
  `payload.bin` (SHA-256 integrity header) with a tiny source-free
  `walix.py` bootstrap that decrypts and compiles modules in memory. No
  readable Walix sources are included in the zip; the installer verifies
  this and refuses to finish a payload install with `*.py` leftovers.
- **Auto-cleanup installer** — Step 0 sweeps every old Walix trace
  (previous /opt installs, duplicate menu entries, old zips); after a
  successful install the extracted folder and remaining zips are removed
  automatically (`--keep-source` opts out).

### Changed
- Five themes now: **Kali Night** (default, official Kali blue), **Dragon
  Cyan**, AMOLED Black, Classic Green, Light.
- `walix --doctor` also prints the call-permission state.
- `run_tests.sh` and the suites updated for v1.1.0 (11 PASS / 0 FAIL).

## [1.0.0] — 2026-11-24

The **Call Edition** — a new foundation release built on the hardened 1.2.2
line (the 1.2.x security work is fully carried over). Everything below is new
in this build.

### Added — Calls
- **In-app voice & video calls** — Walix runs the real WhatsApp Web engine, so
  the call buttons in chats now work inside the window like WhatsApp Desktop.
- **Settings → Calls tab** — one place for call information, the microphone &
  camera permission modes (ask / always allow / always deny) and a one-click
  **camera & audio device check**.
- **`walix --doctor`** — head-less health check (works without a GUI): Python,
  PyQt5, QtWebEngine, Kali gate, VM detection, root check, audio server
  (PulseAudio/PipeWire via `pactl`), camera devices (`/dev/video*`), config
  paths and the active GPU flags.
- **Call stack in the installer** — `pulseaudio`, `libpulse0` and
  `libpulse-mainloop-glib0` are now installed (auto-skipped when unavailable).
- **WebRTC screen sharing on Wayland** — `WebRTCPipeWireCapturer` is enabled
  automatically for Wayland sessions.
- **Fullscreen support is ON** so in-app video calls can go fullscreen (F11).

### Added — Privacy Lock
- **Ctrl+L / menu / tray instant lock** — a full-cover privacy shield with a
  drawn padlock hides all chats from onlookers; one click or Enter unlocks.
- **Auto Privacy Lock** (Settings → General) — the shield engages by itself
  whenever the window loses focus and re-arms when focus returns.

### Added — Themes
- **Four UI themes** — Kali Dark (default), AMOLED Black, Classic Green
  (WhatsApp classic teal) and Light; the whole QSS is generated from the
  palette (`build_qss`), applied instantly from Settings → Appearance, with
  hover/pressed shades derived per accent.

### Added — Performance HUD
- **Live status-bar HUD** (Ctrl+Shift+H) — network down/up speed (from
  `/proc/net/dev`), Walix RAM (VmRSS), UI frame rate and optional CPU; one
  tick per second, fully stopped when disabled.

### Changed — Speed & smoothness
- **Smart GPU acceleration** — `hardware_accel` setting (auto / on / off):
  auto enables GPU compositing on real hardware and keeps the classic
  `--disable-gpu` black-screen fix inside VMs (DMI/`/proc/cpuinfo` detection).
  A user-set `QTWEBENGINE_CHROMIUM_FLAGS` always wins.
- **128 MB disk HTTP cache** — WhatsApp Web static assets reload from disk.
- **`AA_CompressHighFrequencyEvents`** — high-frequency mouse/paint events are
  compressed to keep the event loop at full frame rate.
- **Faster boot** — the window builds after 120 ms instead of 200 ms; the
  splash fade-out dropped to 320 ms; scroll animation stays on.
- **Kali-cyber splash** — matrix glyph rain (deterministic, no RNG cost),
  CRT scanline sweep, HUD corner brackets, typewriter status with blinking
  cursor and a neon progress bar, at the same 30 FPS budget.

### Changed — Security hardening (carried + new)
- **Hyperlink auditing disabled** — the engine can no longer be used as a
  tracking beacon (new in 1.0.0).
- Everything from 1.2.2 still holds: exact-origin allow-list, scheme-filtered
  popups and external links, permission policy scoped to web.whatsapp.com,
  0600 settings / 0700 profile directories, Kali-only and no-root gates.

### Testing
- New `tests/test_v1_features.py` — version/edition branding, theme palette
  completeness, QSS generation for all four themes, HUD formatting and
  rendering, Privacy Shield paint coverage, splash paint coverage, call
  readiness probe shape, `--doctor` output.
- Updated `test_webview_mock.py` (5 profile settings + 128 MB cache +
  HyperlinkAuditingEnabled), `verify_walix.py` (5 tabs, theme combo, new
  settings sanitisation) and `run_tests.sh` (1.0.0 strings).

## [1.2.2] — 2026-11-24

Final popup security fix. No redesign, no removed features.

### Security
- **Popup callback now uses the scheme filter (walix_core/webview.py)** —
  `WalixView.createWindow()`'s nested `_external()` callback called
  `QDesktopServices.openUrl(url)` directly, bypassing the v1.2.1 filter: a
  popup navigating to `javascript:`, `data:`, `file:` or any other scheme
  would have reached the system browser unfiltered. It now:
  - calls `is_allowed_external_url()` first — only `http:`, `https:` and
    `mailto:` ever reach `QDesktopServices`;
  - drops `javascript:`, `data:`, `file:`, `blob:`, `about:` and unknown
    schemes — they never open in ANY external application;
  - closes the popup dialog after EVERY external navigation (allowed or
    blocked — `try/finally`), so no empty window lingers.
- **Full external-opening audit** — the whole project was searched for
  other direct external URL calls (`QDesktopServices.openUrl`, `xdg-open`,
  `webbrowser`, `QProcess`): the only remaining call is
  `MainWindow._open_external` (already filtered in v1.2.1). No other bypass.

### Testing
- **Actual popup callback verified** in `tests/test_webview_mock.py`:
  - a mocked-engine section runs the REAL `createWindow()`/`_external()`
    code with real QDialog show/close behaviour and real Qt signal
    machinery — allowed schemes recorded, blocked schemes never opened,
    dialog closed in both cases, exactly one popup dialog visible at a time;
  - a real-QtWebEngine section (runs when the environment can start
    Chromium, e.g. a desktop) exercises the same callback end-to-end in a
    subprocess and reports POPUP-OK; in containers that cannot run Chromium
    it is a SKIP with the exact reason — never a false FAIL;
  - main-window external navigation regression kept (approved schemes still
    open, blocked schemes still dropped).
- 10 popup cases covered: https/http/mailto allowed; javascript/data/file/
  blob/about:blank/about:config/ftp blocked.

### Honesty note
This release is verified by the automated suite (see run_tests.sh output in
the release notes); real-browser popup behaviour additionally needs a Kali
desktop run — MANUAL_TESTS.md covers what automation cannot. No claim of
complete security beyond the tested scope.

## [1.2.1] — 2026-11-24

Final security and reliability fixes on top of v1.2.1. No redesign, no
removed features — hardening, CLI robustness and a sharper test suite.

### Security
- **URL allow-list tightened (walix_core/webview.py)**:
  - `about:blank` is the ONLY `about:` URL that may navigate — every other
    `about:` page (about:config, about:plugins, fragments variants) is
    rejected and handed to the system-browser path.
  - The trusted origin is now the exact `https://web.whatsapp.com:443`:
    unexpected ports (`https://web.whatsapp.com:8443/`) and URLs carrying
    user-information (`https://user@web.whatsapp.com/`, a phishing vector)
    are rejected before any trust decision.
  - New `is_allowed_external_url()` — only `http:`, `https:` and `mailto:`
    ever reach the system default browser. `javascript:`, `data:`, `file:`,
    `about:`, `blob:` and unknown schemes are dropped, so a crafted link can
    never turn Walix into a launcher for dangerous targets. Enforced in
    `MainWindow._open_external`; device permissions still require the exact
    trusted origin (unchanged from 1.2.1, now port/user-info safe too).

### CLI robustness (walix.py)
- **`--version` and `--help` (and `--kill`) now work WITHOUT PyQt5**: the
  module-level PyQt5 import no longer kills the process — the failure is
  captured (`QT_AVAILABLE`/`QT_ERROR`) and main() enforces Qt only on the
  GUI path, after the CLI-only commands have run.
- `MainWindow` stays importable without Qt via an `object` fallback base;
  it can only ever be instantiated on the Qt path.
- GUI flags without PyQt5 fail politely with the install hint — no traceback.
- **No security bypass**: `WALIX_SKIP_GATES` (an automation-only flag) is now
  honoured ONLY in a head-less offscreen session — it can no longer bypass
  the Kali/root gates in a normal desktop run. Kali-only enforcement and the
  root restriction are unchanged for normal execution.

### Installer / uninstaller
- The installer now **verifies every installed path** (program modules,
  assets, launcher, uninstaller, menu entry, icon) and dies with the missing
  path if anything did not land — it never claims success with missing files.
- Process matching, SIGTERM→SIGKILL escalation and termination verification
  (v1.2.1) unchanged and re-checked; session data still preserved unless the
  user explicitly asks for removal.

### Testing
- `run_tests.sh` reports **PASS / FAIL / SKIP separately** with a final
  counter line; suites that cannot run because an optional dependency is
  missing exit 2 = SKIP — visible, never silently passed, never a false FAIL.
- New `tests/test_cli_pure.py`: `--version`/`--help`/`--kill` verified in
  subprocesses with PyQt5 deliberately BLOCKED (stub module), the GUI flag
  failing politely, module import hygiene without Qt, and the with-Qt
  variant when PyQt5 exists. The pure suites run even without PyQt5.
- New URL-security cases: exact `about:blank` bootstrap, `about:` variants,
  ports, user-information and the external-scheme filter (helper + real
  `MainWindow._open_external` with a patched `QDesktopServices`).
- Verified live: with PyQt5 blocked, all Qt suites report SKIP and the pure
  suites still pass; with PyQt5 present, 12 suites report PASS.

### Documentation
- SECURITY.md: origin/port/user-info and external-scheme controls documented.
- README.md / README_UR.md: v1.2.1. This changelog and RELEASE.md updated.

## [1.2.1] — 2026-11-24

Security, robustness and professional-release upgrade from v1.1.0, driven by
a complete code audit. Ships with an automated test suite: `bash run_tests.sh`.

### Security (P0)
- **Blob-origin permission bug (fixed)**: `is_trusted_whatsapp_url()` trusted
  ANY `blob:`, `data:`, `javascript:` or `about:` URL. Device permissions are
  granted per origin, so a hostile iframe origin such as
  `blob:http://evil.example/x` could have received microphone/camera grants.
  Now only `https://web.whatsapp.com` (blob origins are unwrapped and the
  embedded origin is checked) can ever receive a permission.
- **Exact-origin allow-list**: arbitrary `*.whatsapp.com` subdomains are no
  longer trusted for main-frame navigation — the app origin is exactly
  `web.whatsapp.com` (rationale documented in SECURITY.md).
- **Strict main-frame navigation**: only `https://web.whatsapp.com` and
  `about:blank` load in-app; `javascript:`, `data:`, `file:`, plain `http:`
  and every other host are handed to the system default browser.
- **User-controlled device permissions**: camera, microphone and desktop
  notifications go only to web.whatsapp.com and only according to the user's
  per-permission setting (Ask every time / Always allow / Always deny,
  Settings → Privacy & Data). "Ask" opens a confirmation dialog with a
  "Remember this choice" checkbox. Under automation (offscreen) nothing is
  ever granted.
- Session storage stays `0700`, `settings.json` `0600` (atomic tmp-file write).

### Installer (P1)
- **Kali gate rewritten**: exact `ID=` field parsing (`os_id()`), quoted
  values, CRLF, malformed files and a MISSING `/etc/os-release` are rejected
  with a precise reason. Identical rules in app, launcher and installer —
  tested against 14 synthetic os-release files (python + extracted bash).
- **Graphical session forwarding**: the post-install auto-launch now forwards
  `DISPLAY`, `WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`, `DBUS_SESSION_BUS_ADDRESS`
  and `XAUTHORITY` (user file → inherited path → GNOME runtime copy), so
  Wayland sessions launch instead of dying quietly. Only variable NAMES are
  logged, never values.
- **venv integrity**: `venv_ok()` verifies `PyQt5.QtCore` + `QtWidgets` +
  `QtWebEngineWidgets` import inside the venv; a half-built or broken venv is
  removed (safe: installer-created) instead of being preferred over a working
  system python. pip failures clean up; the installer still fails loudly when
  no usable engine remains — it never silently continues.
- `engine_ok()` checks the complete GUI stack, not a single module.
- An installer run with no desktop user (plain `su`/root) no longer starts a
  process doomed by the launcher's root guard — it explains what to do.

### Application (P1/P2)
- **`walix --kill` precise process matching**: argv[0] must be a python
  interpreter and argv[1] exactly `walix.py` (same discipline as the
  uninstaller) — an editor or grep merely holding the string is never killed.
- **Uninstaller termination verification**: after SIGTERM, remaining confirmed
  PIDs get SIGKILL and a final `pgrep` verifies "All Walix processes stopped
  (verified)" instead of assuming.
- `Settings.save()` is self-sufficient: it recreates missing config dirs, so
  a save can never crash on a fresh or messed-up machine.
- Carried from the 1.2.1 development line and now covered by tests: start
  minimized to tray, DevTools lifecycle cleanup, offline auto-reconnect probe
  (4 s transfer timeout, immediate first probe, tight state machine).

### Testing & tooling (new)
- `run_tests.sh` — one command runs every head-less suite: python + bash
  syntax, Kali detection (14 cases, python + extracted bash functions), URL
  allow-list + permission policy matrix, settings persistence/validation/
  permissions, WebEngine import layouts (A and B), Qt symbol audit against
  the real PyQt5/QtWebEngine modules, splash paint probe, real-network probe
  wiring, `walix --smoke` and `walix --version`.
- Suites that cannot run in a given environment report **SKIP** — never a
  silent pass. Everything ships in `tests/` with relative paths.
- `MANUAL_TESTS.md` — the desktop-only checklist (QR login, tray, calls,
  Wayland session, permissions, uninstaller, long-run).

### Documentation
- New: SECURITY.md (threat model + controls), RELEASE.md (GitHub release
  notes), this changelog. README.md and README_UR.md refreshed (permissions,
  testing, structure, Wayland row).

## [1.1.0] — 2026-11-24
Feature release: centered boot, offline banner + auto-reconnect, F1 shortcut
help, Ctrl+Shift+T always-on-top toggle, PEP 668-aware installer with
per-package apt simulation filtering (`libasound2` → `libasound2t64`), all
user-facing text English.

## [1.0.0] — 2026-11-24
First public release: animated splash, QtWebEngine WhatsApp Web client with
persistent session, tray with unread counter, desktop notifications, Settings
and About dialogs, ethical-use agreement, find-in-page, media downloads,
opt-in DevTools, user-agent selector, single-instance guard, animated
installer + uninstaller, Kali-only enforcement.
