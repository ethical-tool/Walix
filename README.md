 <!-- complete README.md -->

<p align="center">
  <img src="banner.png" alt="Walix Banner" width="500%">
</p>

<h1 align="center">Walix — WhatsApp for Kali Linux</h1>

<p align="center">
  <strong>Dragon Edition · Version 1.2.5</strong>
  <br>
  An unofficial WhatsApp Web desktop client built for Kali Linux.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Kali%20Linux-blue?style=for-the-badge&logo=kalilinux&logoColor=white" alt="Kali Linux">
  <img src="https://img.shields.io/badge/Version-1.2.5-00b4d8?style=for-the-badge" alt="Version 1.2.5">
  <img src="https://img.shields.io/badge/License-GPL--3.0-green?style=for-the-badge" alt="GPL-3.0 License">
  <img src="https://img.shields.io/badge/Status-Active-success?style=for-the-badge" alt="Active">
</p>

---

## Overview

**Walix** is an unofficial desktop client that brings WhatsApp Web to Kali Linux through a dedicated graphical application.

Built with Python, PyQt5 and Qt WebEngine, Walix provides a desktop experience with a Kali-inspired interface, persistent WhatsApp sessions, system-tray integration, desktop notifications, media playback, privacy controls and customizable themes.

Walix is designed to work with the official WhatsApp Web service. It does not provide WhatsApp account hacking, message interception, surveillance or unauthorized access functionality.

> **Important:** Walix is an independent community project. It is not affiliated with, endorsed by, or officially supported by WhatsApp or Meta Platforms, Inc.

## Features

### WhatsApp Desktop Experience

- Dedicated WhatsApp Web window.
- QR-code login through the official WhatsApp Web page.
- Persistent session between application restarts.
- Send and receive messages through WhatsApp Web.
- View images, videos and other supported media.
- Play voice notes and supported video content.
- Download media through a system save dialog.
- Offline status indication and automatic reconnection checks.

### Kali-Inspired Interface

- Animated Dragon Edition startup splash.
- Five built-in interface themes:
  - Kali Night
  - Dragon Cyan
  - AMOLED
  - Classic Green
  - Light
- Custom application icons.
- Customizable toolbar.
- Optional Kali-inspired WhatsApp page styling.
- Circular profile avatars.
- Optional decorative Dragon watermark.
- Custom scrollbar styling.

### System Integration

- Kali application-menu entry.
- System-tray support.
- Hide-to-tray behavior.
- Tray unread-message counter.
- Desktop notifications.
- Persistent application settings.
- X11 and Wayland session support.

### Privacy and Protection

- Optional privacy shield.
- Optional PIN-protected lock.
- Automatic idle locking.
- Hide message previews in notifications.
- Optional stealth window title.
- User-controlled camera and microphone permissions.
- User-controlled desktop notification permissions.
- Protected application session and configuration directories.

### Media and Calls

- WhatsApp voice and video calls through WhatsApp Web.
- Camera and microphone permission controls.
- Audio diagnostics.
- Test sound feature.
- Media-engine diagnostics.
- Video playback support through the available Qt WebEngine engine.
- Fullscreen video support.

### Productivity Tools

- Find-in-page.
- Adjustable zoom.
- Fullscreen mode.
- Always-on-top toggle.
- Performance HUD.
- Built-in Kali Console.
- Keyboard shortcuts.
- Settings and About dialogs.
- Optional Developer Tools access.

---

## Requirements

Walix is specifically designed for **Kali Linux**.

| Requirement | Details |
|---|---|
| Operating system | Kali Linux |
| Python | Python 3 |
| GUI framework | PyQt5 |
| Browser engine | Qt WebEngine |
| Package manager | APT |
| Permissions | Root access for installation |
| Network | Required for installation and WhatsApp Web |
| WhatsApp account | Required for login |

**Important requirements:**

- Walix checks the operating system and refuses to run on non-Kali distributions.
- The application must run as a normal desktop user, not as root.
- A working graphical desktop session is required.
- A working internet connection is required to use WhatsApp Web.

The installer handles the required runtime dependencies. It first attempts to use Kali's APT packages and can use an isolated Python virtual environment as a fallback when explicitly permitted.

---

## Installation

There are two ways to obtain the project.

### Method 1 — Download ZIP

1. Open the [Walix GitHub repository](https://github.com/ethical-tool/Walix).
2. Download the repository ZIP archive.
3. Extract the downloaded ZIP file.
4. Open a terminal.
5. Enter the nested Walix project directory:

```bash
cd Walix-main/Walix
```

6. Start the installer:

```bash
sudo bash install.sh
```

Alternatively, use the setup wrapper:

```bash
bash setup.sh
```

The setup wrapper prepares the required script permissions and launches the installer.

### Method 2 — Git Clone

Clone the repository:

```bash
git clone https://github.com/ethical-tool/Walix.git
```

Enter the nested project directory:

```bash
cd Walix/Walix
```

Run the installer:

```bash
sudo bash install.sh
```

### Installation Process

The installer automatically performs the following operations:

1. Checks the operating system.
2. Verifies Kali Linux compatibility.
3. Checks the required Python environment.
4. Refreshes package information.
5. Installs the required runtime and audio libraries.
6. Installs PyQt5 and Qt WebEngine dependencies.
7. Verifies the available GUI engine.
8. Uses an isolated virtual environment fallback when permitted.
9. Installs Walix application files into `/opt/walix`.
10. Creates the application launcher.
11. Installs the desktop entry and application icons.
12. Checks installation paths and file permissions.
13. Verifies the launcher as the desktop user.
14. Offers to start Walix.

The installer is designed to preserve the extracted project directory, setup scripts, downloaded ZIP archives and unrelated Kali tools.

### Optional: Allow the pip Fallback

By default, the installer does not silently switch to an unpinned pip fallback when the Kali APT Qt engine cannot be installed.

If you understand and accept this trade-off, you can explicitly allow the isolated pip fallback:

```bash
sudo bash install.sh --allow-pip
```

The pip packages are installed inside Walix's own virtual environment rather than modifying the system Python environment.

**Media note:** The pip Qt WebEngine wheels may not include the H.264/AAC codecs available in Kali's packaged engine. Video playback can therefore be limited when the fallback engine is used.

---

## Launching Walix

After successful installation, start Walix from the terminal:

```bash
walix
```

You can also launch it from the Kali application menu:

**Kali → Internet → Walix**

The installed application files are located in:

```text
/opt/walix/
```

---

## Command-Line Options

Walix provides the following command-line options:

| Command | Description |
|---|---|
| `walix` | Launch Walix |
| `walix --help` | Display available command-line options |
| `walix --version` | Display the installed version |
| `walix --doctor` | Diagnose Python, Qt, Kali, camera and audio environment |
| `walix --settings` | Open Settings immediately after startup |
| `walix --reset` | Remove settings and the WhatsApp session |
| `walix --kill` | Stop another running Walix instance |
| `walix --smoke` | Run the headless UI self-test |

### Examples

Check the installed version:

```bash
walix --version
```

Check system compatibility and dependencies:

```bash
walix --doctor
```

Open settings directly:

```bash
walix --settings
```

Stop a running instance:

```bash
walix --kill
```

Start Walix again:

```bash
walix
```

**Warning:** `walix --reset` removes the Walix settings and WhatsApp session. You may need to scan the QR code again to log in.

---

## Keyboard Shortcuts

Walix includes keyboard shortcuts for common application actions.

| Shortcut | Action |
|---|---|
| `F1` | Open keyboard shortcut help |
| `Ctrl + F` | Find text on the page |
| `Ctrl + R` | Reload WhatsApp Web |
| `Ctrl + +` | Zoom in |
| `Ctrl + -` | Zoom out |
| `Ctrl + 0` | Reset zoom |
| `F11` | Toggle fullscreen |
| `Ctrl + Shift + T` | Toggle always-on-top |
| `Ctrl + L` | Activate privacy lock |
| `Ctrl + K` | Open Kali Console |
| `Ctrl + Shift + H` | Toggle Performance HUD |

Some shortcuts may depend on the focused application control or active page.

---

## Kali Console

Walix includes a built-in console for application shortcuts and quick actions.

Open it using:

```text
Ctrl + K
```

Available console commands include:

| Command | Action |
|---|---|
| `:help` | Display console commands |
| `:theme dragon` | Switch to Dragon theme |
| `:hud` | Toggle Performance HUD |
| `:zoom in` | Increase page zoom |
| `:lock` | Activate privacy lock |
| `:settings` | Open application settings |
| `:calls` | Open call-related settings |

The console also includes harmless built-in responses for selected demonstration commands.

---

## Themes and Appearance

Walix includes five interface themes.

| Theme | Description |
|---|---|
| Kali Night | Dark interface with Kali-inspired blue accents |
| Dragon Cyan | Cyan-themed interface |
| AMOLED | Deep black interface |
| Classic Green | WhatsApp-inspired green accents |
| Light | Light interface with grey surfaces |

Themes can be changed through Settings or the application toolbar.

The selected theme is saved and restored when Walix starts again.

### WhatsApp Page Styling

Optional appearance features include:

- Circular profile avatars.
- Kali-inspired scrollbar styling.
- Custom text-selection colors.
- Decorative Dragon watermark.

These options modify the appearance of the WhatsApp page and can be disabled in Settings.

---

## Privacy Lock

Walix provides an optional privacy shield to hide the application content when needed.

Available options include:

- Manual privacy locking.
- Optional PIN protection.
- Automatic locking after inactivity.
- Locking when the application loses focus.
- Privacy locking from the system tray.

The optional PIN is stored as a salted SHA-256 hash in the Walix settings file. The plain PIN is not stored there.

**Note:** A privacy shield is an application-level protection feature. It is not a replacement for operating-system account security or full-disk encryption.

---

## Permissions and Device Access

Walix provides user-controlled permission settings for supported WhatsApp Web features.

| Permission | Purpose |
|---|---|
| Microphone | Voice notes and voice calls |
| Camera | Video calls |
| Notifications | WhatsApp desktop notifications |

Permission modes include:

- Ask every time.
- Always allow.
- Always deny.

The default permission behavior is designed to ask the user before granting access.

Permission requests are restricted to the trusted WhatsApp Web origin.

---

## Audio and Video

Walix uses Qt WebEngine to display WhatsApp Web content.

Audio and video playback depend on the available Qt WebEngine build and system multimedia libraries.

The application includes:

- Audio diagnostics.
- Test sound functionality.
- Audio status indication.
- Media-engine checks.
- Video playback support.
- Fullscreen video support.

For troubleshooting, run:

```bash
walix --doctor
```

You can also use the application's audio help and test sound options.

**Codec limitation:** The isolated pip Qt WebEngine fallback may lack H.264/AAC codec support. The Kali APT Qt WebEngine build is preferred for media compatibility.

---

## Security

Walix includes several security and reliability controls.

### Operating-System Restrictions

- Kali Linux-only enforcement.
- Exact operating-system ID validation.
- Refuses to launch the graphical application as root.
- Installer and launcher use matching Kali checks.

### Web Navigation Restrictions

- The trusted application origin is `https://web.whatsapp.com`.
- Exact origin and port validation.
- Untrusted top-level navigation is not loaded inside the application.
- External navigation is restricted to approved URL schemes.
- Dangerous URL schemes are rejected.

### Permission Restrictions

- Camera, microphone and notification permissions are controlled by user settings.
- Permission grants are restricted to the trusted WhatsApp Web origin.
- Offscreen automation does not receive device permissions.

### Local Data Protection

Walix stores its configuration and session data in user-specific directories.

- Configuration directory permissions are restricted.
- Settings are written atomically.
- The WebEngine profile stores the WhatsApp session.
- Downloads are saved through a system save dialog.

### Process Management

Walix uses precise process matching for its stop and uninstall operations. It does not rely on a broad process-kill pattern that could terminate unrelated applications.

### Protected Application Payload

The release package includes a `payload.bin` containing compressed and obfuscated application modules. The launcher validates the payload's integrity and loads the modules in memory.

This is an obfuscation and packaging mechanism, **not cryptographic protection against a determined reverse engineer**.

For more information, see:

- [Security Policy](Walix/SECURITY.md)
- [Security Audit](Walix/SECURITY_AUDIT.md)

---

## Data and Installation Locations

| Location | Contents |
|---|---|
| `/opt/walix` | Installed application files |
| `/usr/local/bin/walix` | Application launcher |
| `/usr/local/bin/walix-uninstall` | Uninstaller command |
| `/usr/share/applications/walix.desktop` | Desktop application entry |
| `~/.config/walix` | Settings and WhatsApp Web profile/session |
| `~/.cache/walix` | Cache and application error log |

The application error log is located at:

```bash
~/.cache/walix/error.log
```

The installer also creates a temporary installation log under `/tmp`.

---

## Troubleshooting

### Walix Does Not Start

Check the application environment:

```bash
walix --doctor
```

Check the application error log:

```bash
cat ~/.cache/walix/error.log
```

Try stopping any existing Walix instance:

```bash
walix --kill
```

Then launch again:

```bash
walix
```

### Qt WebEngine Is Missing

The application requires a working PyQt5 and Qt WebEngine environment.

On Kali Linux, the installer attempts to install the required APT packages. If the installation fails, review the installer log and run the installer again after resolving the package issue.

### Application Files Are Not Readable

If an existing installation has incorrect read permissions, the release's documented repair command is:

```bash
sudo chmod -R a+rX /opt/walix
```

Then launch Walix again:

```bash
walix
```

### WhatsApp Videos Have No Sound

Run:

```bash
walix --doctor
```

Check that the system audio server and required audio libraries are available. The application also provides a **View → Test sound** option and audio troubleshooting information.

### WhatsApp Session Is Lost

If the session data has been removed or corrupted, open Walix again and scan the QR code displayed by WhatsApp Web.

---

## Uninstallation

Walix includes a dedicated uninstaller.

Run:

```bash
sudo walix-uninstall
```

The uninstaller:

1. Stops running Walix processes.
2. Verifies process termination.
3. Removes the installed application files.
4. Removes the installed launcher and desktop integration.
5. Asks whether you also want to remove your WhatsApp session and settings.

By default, the session is preserved unless you explicitly choose to remove it.

You can also run the uninstaller directly from the extracted project directory:

```bash
sudo bash uninstall.sh
```

---

## Testing

Walix includes an automated test runner.

Enter the project directory:

```bash
cd Walix-main/Walix
```

Run:

```bash
bash run_tests.sh
```

The test runner checks areas including:

- Shell script syntax.
- Python bootstrap syntax.
- CLI version and help commands.
- Payload integrity.
- Embedded module structure.
- Installer source-preservation behavior.
- Available headless application checks.

The test runner reports results separately as:

- **PASS** — the test passed.
- **FAIL** — the test failed.
- **SKIP** — the test could not run in the current environment.

Some graphical tests require PyQt5, Qt WebEngine and a working desktop session. Automated headless tests cannot replace manual testing with a real WhatsApp account, camera, microphone or graphical session.

For manual verification, see:

[MANUAL_TESTS.md](Walix/MANUAL_TESTS.md)

---

## Project Structure

The downloaded repository has a nested directory structure.

```text
Walix-main/
│
├── banner.png
├── LICENSE
├── README.md
│
└── Walix/
    │
    ├── assets/
    │   ├── banner.png
    │   ├── icon.png
    │   ├── icon-16.png
    │   ├── icon-24.png
    │   ├── icon-32.png
    │   ├── icon-48.png
    │   ├── icon-64.png
    │   ├── icon-128.png
    │   ├── icon-256.png
    │   ├── icon-tray.png
    │   ├── splash-logo.png
    │   └── icons/
    │
    ├── walix.py
    ├── payload.bin
    ├── walix-launcher.sh
    ├── walix.desktop
    │
    ├── install.sh
    ├── setup.sh
    ├── uninstall.sh
    ├── run_tests.sh
    │
    ├── README_UR.md
    ├── CHANGELOG.md
    ├── MANUAL_TESTS.md
    ├── SECURITY.md
    └── SECURITY_AUDIT.md
```

### Important Files

| File | Purpose |
|---|---|
| `walix.py` | Python application bootstrap and payload loader |
| `payload.bin` | Protected application modules |
| `install.sh` | Main installation script |
| `setup.sh` | Setup wrapper |
| `uninstall.sh` | Application uninstaller |
| `walix-launcher.sh` | Installed application launcher |
| `walix.desktop` | Kali desktop integration |
| `run_tests.sh` | Automated test runner |
| `CHANGELOG.md` | Version history and changes |
| `MANUAL_TESTS.md` | Manual desktop test checklist |
| `SECURITY.md` | Security policy and implemented controls |
| `SECURITY_AUDIT.md` | Security audit notes |
| `README_UR.md` | Urdu documentation reference |

---

## Version Information

**Current Version:** 1.2.5

**Edition:** Dragon Edition

The 1.2.5 release focuses on fixing the application launch failure caused by restrictive installation permissions.

It also includes improvements to:

- Installed file permissions.
- Desktop-user launcher verification.
- Application icon permissions.
- Installation log accessibility.
- Virtual environment readability.
- Launcher diagnostics.
- Smoke-test version validation.

For the complete version history, see:

[CHANGELOG.md](Walix/CHANGELOG.md)

---

## License

Walix is distributed under the **GNU General Public License v3.0 (GPL-3.0)**.

You can review the complete license in the repository:

[LICENSE](LICENSE)

---

## Disclaimer

Walix is an unofficial third-party desktop wrapper for the official WhatsApp Web service.

- It is not developed, maintained or endorsed by WhatsApp or Meta.
- It does not provide unauthorized access to WhatsApp accounts.
- It does not intercept, extract, record or monitor private conversations or calls.
- Users are responsible for complying with applicable laws and WhatsApp's terms of service.
- Use Walix only with accounts and devices you are authorized to access.

---

<p align="center">
  <strong>Walix — Dragon Edition</strong>
  <br>
  Built for Kali Linux.
  <br><br>
  <a href="https://github.com/ethical-tool/Walix">GitHub Repository</a>
</p>

