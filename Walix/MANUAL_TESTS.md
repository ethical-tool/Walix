# Walix — Manual Desktop Test Checklist (v1.2.0 Dragon Edition)

The automated suites (`bash run_tests.sh`) run head-less: they verify
detection logic, settings, the URL allow-list, permissions policy, WebEngine
imports, themes, the HUD and every Qt symbol — but they **cannot** exercise
real hardware, a real WhatsApp account, a real camera or a real graphical
session. The checks below must be done by hand on a real Kali Linux desktop,
in the order a normal user hits them. Tick each line only after you actually
see the expected result.

## Session A — X11 (Kali desktop running X11)

1. `sudo ./install.sh` — finishes, prints "Launcher verified → Walix 1.2.0"
   and "Media codecs verified — status/chat videos WILL play (H.264 OK)".
2. Walix auto-launches: **Kali-cyber splash** (matrix rain, scanlines,
   typewriter status) → main window, centered on first boot.
3. QR code renders; scanning with the phone logs WhatsApp Web in.
4. Close and reopen Walix — the session persists (no second QR scan).
5. Send and receive messages; images and voice notes render and play.
6. Download an image/video — a save dialog appears; the file lands where chosen.
7. New message while the window is hidden → desktop notification appears.
8. Close (X) → Walix hides to the tray; tray icon tooltip shows unread count;
   double-click reopens; tray menu Quit really exits (`pgrep -f walix.py` empty).
9. Shortcuts: Ctrl+F find bar, Ctrl+/-/0 zoom (persisted), F11 fullscreen,
   Ctrl+R reload, F1 shortcuts dialog, Ctrl+Shift+T always-on-top toggle.
10. Settings → all five tabs save and survive a restart (zoom, theme, UA…).
11. External link (e.g. an wa.me invite link in chat) opens in Firefox and
    NEVER loads inside the Walix window.
12. `walix --kill` stops the app; `walix` starts it again.

## Status & chat videos (v1.1.1 — THE hotfix, needs a logged-in session)

1. Open a contact's or your own **status** with a video in it → the video
   viewer opens and the video starts playing by itself (no frozen first
   frame). Scroll to the next status with a video → plays too.
2. Open any chat that contains a shared **video** → it plays inside the
   chat (tap the play button; audio audible unless Mute audio is on).
3. `walix --doctor` → the **Media engine** line reads "Kali apt build —
   H.264 ✔ (videos can play)". On a broken (pip) engine it prints
   "pip wheel — NO H.264 ✘" with the exact fix command.
4. Simulate the wrong engine (only if you know what you are doing: run
   `walix.py` with a pip-installed PyQt5/PyQtWebEngine) → after load a
   one-time dialog "Walix — video codec fix" appears with the exact
   commands; the status bar shows the codec warning. It never repeats in
   the same profile.
5. Icon check: the Kali menu entry, the taskbar, alt-tab, the tray and a
   desktop notification all show the SAME fresh dragon mark (v1.1.1
   regenerates every size). Popups (target=_blank windows) also carry it.
6. Smoothness check inside a VM (no GPU): scrolling the chat list feels
   responsive — the scroll animator is off on the software-rendered path.
7. Crash recovery (optional): kill the QtWebEngineProcess subprocess while
   Walix shows chats → within ~1.5 s the page reloads itself instead of
   staying grey.

## Calls (v1.1.0 — needs a working camera + mic + audio server)

0. Fresh install → Settings → Calls: Microphone/Camera show **Always allow**
   (the v1.0.0→1.1.0 migration upgraded old "ask" values once).

1. `walix --doctor` — reports PyQt5/QtWebEngine OK, the audio server and
   `/dev/video*` devices; fix anything it marks missing.
2. Settings → Calls → **Check camera & audio devices** — ✔ rows for audio
   server, microphone source and camera (✘ with the exact reason when missing).
2b. Settings → Calls → **Test mic & camera inside WhatsApp** — after Allow,
   the report says WhatsApp CAN open your mic; ✘ names the exact error.
2c. **Reset permissions → Allow** returns both combos to Always allow.
3. Set Microphone and Camera to **Always allow** (Settings → Calls).
4. Open a chat → tap the **voice-call button** → the call panel opens INSIDE
   the Walix window, connects, audio works both ways, no permission prompt.
5. Open a chat → tap the **video-call button** → same, with your camera
   preview in the panel; hang-up works.
6. During a video call press **F11** → fullscreen video; F11 again returns.
7. Set Camera to **Ask every time** → the next call shows the Walix
   permission dialog; "No" keeps the camera dark, "Yes" allows, "Remember"
   stops future prompts.
8. Nothing is recorded: after a call there are no new files in
   `~/.config/walix` (the call is WhatsApp's own, end-to-end).

## Privacy Lock (v1.1.0 — PIN + idle lock)

1. Press **Ctrl+L** → the whole window is covered by the privacy shield
   (padlock + hints); clicking it or pressing Enter reveals the chats again.
2. Enable Settings → General → Privacy Lock → click another window: Walix
   covers itself the instant it loses focus; clicking back re-arms the shield.
3. Tray menu → "Lock chats (Privacy Shield)" — same behaviour as Ctrl+L.
4. Settings → Privacy & Data → **Set PIN…** (e.g. 4242) → Ctrl+L → the shield
   now shows a PIN field; wrong PIN keeps the shield (red hint), Ctrl+L,
   Enter, Space or clicking can NOT bypass it; the correct PIN unlocks.
5. Remove the PIN → one-click unlock returns.
6. Settings → General → **Auto-lock after idle: 1 min** → leave the window
   untouched for 1 minute → the shield locks itself with a status note.
7. **Hide message previews** → ask a contact to message you → the desktop
   notification shows "New message — previews hidden in Walix", no text.
8. **Stealth title** → the window/taskbar shows `walix@kali: ~`; disable it
   → "WhatsApp — Walix" returns.

## Performance HUD (v1.0.0, unchanged in 1.1.0)

1. Press **Ctrl+Shift+H** → a monospace readout appears in the status bar:
   ⇩/↑ speeds, RAM, UI fps — it updates about once per second.
2. Start a large download in a chat → the ⇩ speed visibly rises.
3. Toggle Settings → General → "Include CPU" → the CPU value appears.
4. Toggle the HUD off → the readout disappears and CPU drops (HUD timer
   fully stopped).

## Themes (v1.1.0 — five Kali themes)

1. Default boot shows **Kali Night** — deep blue-black with Kali-blue
   accents and gradient primary buttons; no restart needed when switching.
2. Settings → Appearance → switch to **Dragon Cyan** → the UI flips to the
   official Kali cyan; AMOLED → pure black; Classic Green → WhatsApp teal;
   Light → readable light greys. The choice survives a restart.
3. **Kali Console (Ctrl+K)** → type `:theme dragon` + Enter → the theme
   switches live; `:hud`, `:zoom in`, `:lock`, `:settings`, `:calls` behave
   the same as their menu actions; `:help` lists all commands; typing
   `whoami` or `sudo rm -rf /` shows the easter-egg replies.

## WhatsApp Web styling (v1.1.0 — needs a logged-in session)

1. Settings → Appearance keeps **Circular profile avatars** on → after the
   chats load, every avatar in the chat list, header and profile panel is
   perfectly round (default silhouettes included).
2. **Kali styling** on → the WhatsApp scrollbars become slim and neon blue;
   selected text highlights in Kali blue.
3. **Dragon watermark** on → a small, faint dragon sits in the bottom-left
   corner of the chat canvas; it never blocks clicks.
4. Toggle all three OFF → the page returns to stock WhatsApp; NO reload
   needed for any of the toggles (they apply live).
5. Theme switch in Walix → the injected styling re-applies with the new
   accent colour instantly.

## Session B — Wayland (Kali GNOME/KDE Wayland session)

1. Run the installer again in the Wayland session — Walix auto-launches.
2. If the auto-launch window does not appear, run `walix` manually — it must
   open (Qt falls back to XWayland) and report no crash in `~/.cache/walix/error.log`.
3. Tray icon + notifications work (needs the D-Bus env the installer forwards).
4. Screen-share INSIDE a WhatsApp video call — the PipeWire/WebRTC flag is
   active on Wayland (WebRTCPipeWireCapturer).
5. `~/.cache/walix/error.log` stays free of Wayland/platform errors.

## Permissions (privacy — carried from 1.2.0, now in Calls + Privacy tabs)

1. Settings → Calls shows the Microphone and Camera rows and Settings →
   Privacy & Data shows the Notifications row — all defaulting to
   "Ask every time".
2. Start a WhatsApp voice-note recording with Microphone = "Ask every time" →
   a Walix dialog asks; "No" denies (WhatsApp shows its own error), "Yes"
   allows; ticking "Remember" stops future prompts for that permission.
3. Set Microphone = "Always deny" → no dialog ever appears, recording fails.
4. Set Microphone = "Always allow" → recording starts with no prompt.
5. Visit nothing but WhatsApp — no site other than web.whatsapp.com can
   trigger a permission dialog (the app never asks for other origins).

## Uninstaller

1. `sudo walix-uninstall` → processes stop (verified line in output),
   files removed, session kept by default → reinstall needs NO new QR scan.
2. Run it again with session removal → `~/.config/walix` is gone.
3. Install → uninstall → install → app still works (no broken state).

## Long-run

1. Leave Walix open overnight; memory stays roughly stable (no runaway).
2. Drop the network (Wi-Fi off): the offline banner appears, the app probes
   every 6 s, and when the network returns it reloads by itself.
