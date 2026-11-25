#!/usr/bin/env bash
# ============================================================
#  Walix — WhatsApp for Kali Linux (Dragon Edition)  •  animated installer
#  KALI-ONLY tool: blocks non-Kali distros. Any Kali version works.
#  Unofficial, ETHICAL TOOL: your own account only.
#
#  v1.1.0: installs the bytecode payload build (NO readable app sources).
#  Installation is non-destructive: extracted setup files and downloaded
#  archives are always preserved.
#  v1.2.1: SOUND FIX — (1) the package filter no longer leaks its
#  diagnostics INTO the apt package list (the v1.1.1 bug that made apt
#  fail with 'Regex compilation error' and left the audio libraries
#  uninstalled → silent videos), (2) audio/runtime libs install in their
#  own phase so even the pip fallback gets sound, (3) the launch env now
#  carries XDG_RUNTIME_DIR on X11 too (PulseAudio socket path).
#  v1.2.5: LAUNCH FIX — the installer ran with umask 077, so EVERY file
#  copied to /opt/walix landed as root-only (0600/0700) and the normal
#  desktop user could not even ENTER /opt/walix. The root self-test
#  'walix --version' still passed (root reads everything), so the
#  installer printed all green — then the real user's launch died within
#  milliseconds: 'App files not found'. Files are now explicitly
#  normalised (dirs 755 / files 644 / scripts 755), the menu icons and
#  the launcher smoke-check run AS the desktop user, and the launch log
#  belongs to the user again so they can read their own errors.
# ============================================================
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="/opt/walix"
BIN="/usr/local/bin/walix"
UNINSTALL_BIN="/usr/local/bin/walix-uninstall"
DESKTOP_DST="/usr/share/applications/walix.desktop"
ICON_DIR="/usr/share/icons/hicolor/512x512/apps"
LOG="${TMPDIR:-/tmp}/walix-install.$$.log"
VERSION="1.2.5"
umask 077
# The log itself must stay readable by the desktop user — the installer
# quotes 'full log: $LOG' in its failure messages (v1.2.5).
touch "$LOG" 2>/dev/null && chmod 644 "$LOG" 2>/dev/null || true
ALLOW_PIP=0

# ---------- colors ----------
if [ -t 1 ]; then
  G='\033[1;32m'; GG='\033[1;92m'; Y='\033[1;33m'; R='\033[1;31m'
  C='\033[1;36m'; W='\033[1;97m'; D='\033[2m'; N='\033[0m'
else
  G=''; GG=''; Y=''; R=''; C=''; W=''; D=''; N=''
fi

msg()  { printf "%b\n" "${C}::${N} $*"; }
ok()   { printf "%b\n" "${GG}[ ✔ ]${N} $*"; }
warn() { printf "%b\n" "${Y}[ ! ]${N} $*"; }
fail() { printf "%b\n" "${R}[ ✘ ]${N} $*"; }
die()  { fail "$*"; exit 1; }

# BUGFIX (v1.2.4, ported into v1.2.5): these helpers are defined BEFORE the
# argument case — the old order called warn() from the '--clean-source'
# branch before the function existed ('warn: command not found' on screen).
case "${1:-}" in
  --clean-source) warn "--clean-source is deprecated and ignored; source files are always preserved" ;;
  --allow-pip) ALLOW_PIP=1 ;;
  --keep-source|--no-clean) : ;;
esac

# Destructive operations are permitted only inside Walix's own installation
# directory. This prevents a regression from touching Kali or user files.
type_text() {
  local text="$1" i
  for ((i = 0; i < ${#text}; i++)); do
    printf "%s" "${text:i:1}"
    sleep 0.011
  done
  printf "\n"
}

spinner() {
  # spinner <pid> <label>  — braille spinner while a background job runs
  local pid="$1" label="$2" delay=0.09 i=0
  local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  printf "  ${G}%s${N} %s " "${frames[0]}" "$label"
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i + 1) % ${#frames[@]} ))
    printf "\r  ${G}%s${N} %s " "${frames[$i]}" "$label"
    sleep "$delay"
  done
  wait "$pid" 2>/dev/null
  local rc=$?
  printf "\r"
  if [ "$rc" -eq 0 ]; then ok "$label"; else fail "$label (see $LOG)"; fi
  return "$rc"
}

bar() {
  local label="$1" width=34 i fill rest
  printf "  ${D}%s${N}\n" "$label"
  for ((i = 0; i <= width; i++)); do
    local pct=$(( i * 100 / width ))
    fill=$(printf "%*s" "$i" "");  fill="${fill// /█}"
    rest=$(printf "%*s" "$((width - i))" ""); rest="${rest// /░}"
    printf "\r  ${GG}%-36s${N} ${G}%3d%%${N}" "$fill$rest" "$pct"
    sleep 0.014
  done
  printf "\n"
}

banner() {
printf "%b" "
${GG} ██     ██   █████   ██       ██  █████${N}
${GG} ██     ██  ██   ██  ██       ██ ██   ██${N}
${GG} ██  █  ██  ███████  ██   █   ██  █████${N}
${GG} ██ ███ ██  ██   ██  ██ ███ ██  ██${N}
${GG}  ███ ███   ██   ██   ███ ███   ██${N}
${G}         WhatsApp for Kali Linux${D}  •  v${VERSION}  •  ETHICAL TOOL${N}
"
}

# ---------- root ----------
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    warn "Installer needs root — re-running with sudo…"
    exec sudo bash "$0" "$@"
  else
    die "Please run as root:  sudo ./install.sh"
  fi
fi

# ---------- Kali-only gate (exact ID=kali — same rules as the app) ----------
os_id() {
  # Parse the exact ID field of an os-release file (quoted values ok).
  # Prints the ID, or fails when the file is missing, malformed (a line that
  # is not KEY=VALUE, a bad KEY) or has no ID field — mirrors the Python
  # parse_os_release()/is_kali() in walix.py.
  local file="${1:-/etc/os-release}" line key val found=""
  [ -r "$file" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in ''|\#*) continue ;; esac
    case "$line" in *=*) ;; *) return 1 ;; esac
    key="${line%%=*}"; val="${line#*=}"
    case "$key" in ''|*[!A-Za-z0-9_]*) return 1 ;; esac
    case "$key" in [!A-Za-z]*) return 1 ;; esac
    val="${val%\"}"; val="${val#\"}"; val="${val%\'}"; val="${val#\'}"
    [ "$key" = "ID" ] && found="$val"
  done < "$file"
  [ -n "$found" ] || return 1
  printf "%s" "$found"
}

OS_ID="$(os_id 2>/dev/null || true)"
if [ "$OS_ID" != "kali" ]; then
  fail "Walix is built only for KALI LINUX (Kali-only tool)."
  if [ ! -r /etc/os-release ]; then
    fail "/etc/os-release is missing — the operating system cannot be identified."
  elif [ -z "$OS_ID" ]; then
    fail "/etc/os-release is malformed — no usable ID field was found."
  else
    fail "Detected OS ID '$OS_ID' is not Kali."
  fi
  exit 1
fi

banner
echo
type_text "  Walix Dragon Edition installer — old files swept, new payload, launch!"
echo

# ---------- 0. PRE-INSTALL CHECK: never delete user files ----------
cleanup_old_files() {
  # Do not remove extracted folders, ZIP files, desktop entries, or any
  # user-owned files. Existing managed paths are replaced atomically below.
  ok "Safety check — existing files and extracted tools will be preserved"
}

msg "Step 0/4 — Checking installation safety…"
bar "non-destructive install check"
cleanup_old_files

# ---------- 1. system check ----------
msg "Step 1/4 — Checking your system…"
bar "system check"
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  ok "Detected distro: ${PRETTY_NAME:-unknown} (any Kali version is fine)"
  PKG_MGR="apt"
else
  PKG_MGR="apt"
  warn "Could not read /etc/os-release — assuming apt"
fi

if ! command -v python3 >/dev/null 2>&1; then
  warn "python3 not found — will try to install it"
fi

# ---------- 2. dependencies ----------
msg "Step 2/4 — Installing the Qt web engine + runtime libraries + call stack…"
# v1.2.1 SOUND FIX — TWO phases instead of one fragile list:
#   phase A — audio + runtime libraries. These MUST land even when the
#             PyQt5 apt stack fails, because the isolated pip venv
#             fallback still needs them for sound (v1.1.1 field report:
#             'video chal gaya lekin awaaz nahi' — exactly this gap).
#   phase B — the PyQt5 + QtWebEngine engine itself.
# libasound2 AND libasound2t64: Kali's rolling repo renamed the package —
# filter_available() keeps whichever actually exists on this system.
# pulseaudio-utils provides `pactl`, the probe behind every audio check.
# BUGFIX (v1.2.4, ported into v1.2.5): the `pulseaudio` SERVER package is
# only requested when NO audio server exists yet. Modern Kali ships
# PipeWire (pipewire-pulse), and `pulseaudio` CONFLICTS with pipewire-pulse
# — forcing it in made apt either fail the whole phase ('broken packages')
# or REPLACE the working PipeWire sound stack. Protecting the user's audio
# server also protects WhatsApp sound, which flows through it.
AUDIO_SERVER_PKGS="pulseaudio"
if dpkg -s pipewire-pulse >/dev/null 2>&1 \
   || dpkg -s pulseaudio >/dev/null 2>&1 \
   || dpkg -s pipewire >/dev/null 2>&1; then
  AUDIO_SERVER_PKGS=""
  msg "  Audio server already present (PipeWire/PulseAudio) — it will not be touched"
fi
RUNTIME_PKGS="libxtst6 libxkbcommon-x11-0 libxkbcommon0 libnss3 \
libasound2 libasound2t64 libxcomposite1 libxdamage1 libxrandr2 libxrender1 \
libxi6 libgl1 libegl1 libfontconfig1 libdbus-1-3 \
${AUDIO_SERVER_PKGS:+$AUDIO_SERVER_PKGS }pulseaudio-utils libpulse0 libpulse-mainloop-glib0 libnotify-bin"
QT_PKGS="python3 python3-pyqt5 python3-pyqt5.qtwebengine python3-venv"

show_log_tail() {
  warn "Last error lines (full log: $LOG):"
  tail -n 6 "$LOG" 2>/dev/null | sed 's/^/    /'
}

filter_available() {
  # Kali is a rolling distro — packages get renamed (libasound2 → libasound2t64)
  # and some names turn VIRTUAL with no installable candidate (apt-cache show
  # still exits 0 for those, so simulate the real install per package instead).
  # v1.2.1 BUGFIX: this function runs inside $( ) command substitution —
  # the old diagnostics were printed to STDOUT and got CAPTURED INTO THE
  # PACKAGE LIST. apt then received literal words like 'skipping',
  # 'unavailable', 'package:' and the ANSI '[ ! ]' brackets — producing
  # 'E: Regex compilation error - Unmatched [' and failing the WHOLE
  # install (which silently removed the audio libraries too). All
  # diagnostics now go to STDERR and can never pollute the list again.
  local list="$1" avail="" p
  for p in $list; do
    if apt-get install -s -y "$p" >/dev/null 2>&1; then
      avail="$avail $p"
    else
      warn "  apt: skipping unavailable package: $p" >&2
    fi
  done
  printf "%s" "$avail"
}

apt_install_list() {
  # apt_install_list <spinner label> <package list> → 0 on success
  local label="$1" pkgs
  pkgs="$(filter_available "$2")"
  if [ -z "$pkgs" ]; then
    warn "  no installable packages left in this group — skipping" >&2
    return 1
  fi
  (export DEBIAN_FRONTEND=noninteractive
   apt-get install --no-remove -y $pkgs >>"$LOG" 2>&1) &
  if spinner $! "$label"; then
    return 0
  fi
  show_log_tail
  return 1
}

install_apt() {
  msg "  Refreshing package lists first (apt-get update)…"
  (export DEBIAN_FRONTEND=noninteractive
   apt-get update -y >>"$LOG" 2>&1) &
  if ! spinner $! "apt-get update"; then
    warn "apt-get update failed — continuing with the cached package lists"
  fi
  # v1.2.1 phase A: audio + runtime libs FIRST — even when the Qt engine
  # has to come from pip, the sound stack is already in place.
  apt_install_list "apt-get install audio + runtime libraries" "$RUNTIME_PKGS" \
    || warn "Some runtime libraries failed — audio may need View → Audio help inside Walix"
  # v1.2.1 phase B: the Qt engine itself, then PROVE it imports — a
  # half-installed engine must not count as success.
  if apt_install_list "apt-get install pyqt5 + qtwebengine" "$QT_PKGS"; then
    if python3 -c "import PyQt5.QtCore, PyQt5.QtWidgets, PyQt5.QtWebEngineWidgets" \
         >/dev/null 2>>"$LOG"; then
      return 0
    fi
    warn "apt Qt stack installed but QtWebEngine does not import — falling back to pip"
  fi
  return 1
}

PIP_DONE=0
VENV_DIR="$PREFIX/venv"

venv_ok() {
  # A venv is only usable when its own python can import the complete GUI
  # stack the app starts with (core + widgets + web engine).
  [ -x "$VENV_DIR/bin/python" ] || return 1
  "$VENV_DIR/bin/python" -c "import PyQt5.QtCore, PyQt5.QtWidgets, PyQt5.QtWebEngineWidgets" \
    >/dev/null 2>>"$LOG"
}

install_pip() {
  # Isolated virtual-environment fallback: pip wheels of PyQt5 + PyQtWebEngine
  # land INSIDE /opt/walix/venv — the system Python is never modified.
  warn "Falling back to an isolated pip venv (needs network)…"
  mkdir -p "$PREFIX"
  (python3 -m venv "$VENV_DIR" >>"$LOG" 2>&1) &
  if ! spinner $! "python3 -m venv (isolated env)"; then
    show_log_tail
  fi
  if [ ! -x "$VENV_DIR/bin/python" ]; then
    warn "python3 -m venv failed — python3-venv is probably missing"
    warn "Refusing a system-wide --break-system-packages fallback."
    return 1
  fi
  ("$VENV_DIR/bin/pip" install --quiet --upgrade pip >>"$LOG" 2>&1
   "$VENV_DIR/bin/pip" install --quiet PyQt5 PyQtWebEngine >>"$LOG" 2>&1) &
  if spinner $! "pip install PyQt5 PyQtWebEngine (inside venv)"; then
    if venv_ok; then
      # v1.2.5: a venv built under umask 077 is root-only (0700) — the
      # desktop user could never execute it. Make it traversable/readable
      # for everyone while keeping write access root-only.
      chmod -R a+rX "$VENV_DIR" 2>>"$LOG" || true
      PIP_DONE=1
      return 0
    fi
    warn "venv exists but QtWebEngine does not import inside it — cleaning up"
    warn "The incomplete venv was preserved at $VENV_DIR; repair it manually or reinstall after reviewing it."
    show_log_tail
    PIP_DONE=1
    return 1
  fi
  show_log_tail
  warn "venv pip install failed — the incomplete environment was preserved at $VENV_DIR"
  PIP_DONE=1
  warn "venv pip install failed — the environment was cleaned up"
  return 1
}

if install_apt; then
  :
elif [ "$ALLOW_PIP" -eq 1 ]; then
  warn "Using explicitly requested pip fallback; packages are installed only in the root-owned Walix venv."
  install_pip || die "The pip fallback failed (see $LOG)"
else
  die "The Kali apt Qt stack could not be installed. Refusing an unpinned pip fallback; re-run with --allow-pip only if you accept that trade-off."
fi

# ---------- verify ----------
engine_ok() {
  "$PY_EXE" -c "import PyQt5.QtCore, PyQt5.QtWidgets, PyQt5.QtWebEngineWidgets" \
    >/dev/null 2>>"$LOG"
}

set_py_exe() {
  # Prefer the venv ONLY when it actually works; a broken one (interrupted
  # install, disk full) is removed so the system python is evaluated instead.
  PY_EXE="python3"
  if [ -x "$VENV_DIR/bin/python" ]; then
    if venv_ok; then
      PY_EXE="$VENV_DIR/bin/python"
    else
      warn "Found a broken venv at $VENV_DIR — removing it (installer-created)"
      warn "The existing unusable venv was preserved at $VENV_DIR."
    fi
  fi
}

msg "Verifying the engine…"
set_py_exe
if ! engine_ok; then
  warn "The system Qt WebEngine is not importable"
  if [ "$PIP_DONE" -eq 0 ]; then
    warn "Rescuing with the isolated pip venv…"
    install_pip
    set_py_exe
  fi
  if engine_ok; then
    ok "Qt WebEngine import verified (via venv)"
  else
    fail "Qt WebEngine is NOT importable — Walix cannot run (see $LOG)"
    die "Fix the Qt installation, then re-run this installer."
  fi
else
  ok "Qt WebEngine import verified"
fi

# ---------- v1.1.1 MEDIA CODEC VERIFICATION (the status-video fix) ----------
# pip wheels of PyQtWebEngine ship WITHOUT the proprietary H.264/AAC codecs:
# on that engine WhatsApp status videos and chat videos silently refuse to
# play. The Kali apt build (python3-pyqt5.qtwebengine) HAS them. When both
# engines exist the launcher now prefers the codec-capable one, and this
# check tells the user exactly which engine won and what to do otherwise.
media_probe() {
  # media_probe <python>  → prints OK | MISSING | SKIP
  QT_QPA_PLATFORM=offscreen "$1" - <<'PYEOF' 2>>"$LOG"
import json, os, sys
try:
    from PyQt5.QtCore import Qt, QTimer, QUrl
    from PyQt5.QtWidgets import QApplication
    QApplication.setAttribute(Qt.AA_ShareOpenGLContexts, True)
    import PyQt5.QtWebEngineWidgets  # noqa: F401
    from PyQt5.QtWebEngineWidgets import QWebEnginePage
except Exception:
    print("SKIP")
    sys.exit(0)

JS = """
(function(){var v=document.createElement('video');
 return JSON.stringify({h264:v.canPlayType('video/mp4; codecs="avc1.42E01E"')});
})()
"""
res = {"done": False}

app = QApplication([])
page = QWebEnginePage()

def done(r):
    res["val"] = r
    res["done"] = True

def on_load(_ok):
    try:
        page.runJavaScript(JS, 0, done)
    except TypeError:
        page.runJavaScript(JS, done)

page.loadFinished.connect(on_load)
page.load(QUrl("data:text/html,<title>x</title>"))
QTimer.singleShot(20000, app.quit)

def tick():
    if res["done"]:
        app.quit()
        return
    QTimer.singleShot(200, tick)

QTimer.singleShot(200, tick)
app.exec_()
try:
    ok = bool(json.loads(res.get("val") or "{}").get("h264"))
except Exception:
    ok = False
print("OK" if ok else "MISSING")
PYEOF
}

engine_ok_system() {
  python3 -c "import PyQt5.QtCore, PyQt5.QtWidgets, PyQt5.QtWebEngineWidgets" \
    >/dev/null 2>>"$LOG"
}

PROBE_PY="$PY_EXE"
PROBE_RESULT="SKIP"
if [ "$PROBE_PY" = "python3" ] || [ -x "$PROBE_PY" ]; then
  PROBE_RESULT="$(media_probe "$PROBE_PY" 2>>"$LOG" | tail -n 1)"
fi
case "$PROBE_RESULT" in
  OK)
    ok "Media codecs verified — status/chat videos WILL play (H.264 OK)" ;;
  MISSING)
    if [ "$PY_EXE" != "python3" ]; then
      warn "pip venv engine has NO H.264 — switching to the Kali apt engine"
      if engine_ok_system; then
        PY_EXE="python3"
        if [ "$(media_probe python3 2>>"$LOG" | tail -n 1)" = "OK" ]; then
          ok "Media codecs verified on the apt engine — videos WILL play"
        else
          warn "apt engine probe did not answer — continuing with the apt engine"
        fi
      fi
    else
      warn "Media codecs MISSING on the apt engine — try: sudo apt install libqt5webengine-data"
    fi ;;
  *)
    warn "Media codec probe skipped here — Walix will self-check on first run" ;;
esac

# ---------- 3. files ----------
msg "Step 3/4 — Installing files…"
bar "copying files"
mkdir -p "$PREFIX"
# Copy whatever build layout is present:
#   * source build: walix.py + walix_core/ (+ assets…)
#   * payload build (v1.1.0 release): walix.py bootstrap + encrypted payload.bin
COPY_OK=1
for item in walix.py assets walix.desktop walix-launcher.sh uninstall.sh README.md; do
  [ -e "$SRC_DIR/$item" ] && { cp -r "$SRC_DIR/$item" "$PREFIX/" 2>>"$LOG" || COPY_OK=0; }
done
[ -d "$SRC_DIR/walix_core" ] && { cp -r "$SRC_DIR/walix_core" "$PREFIX/" 2>>"$LOG" || COPY_OK=0; }
[ -f "$SRC_DIR/payload.bin" ] && { cp -r "$SRC_DIR/payload.bin" "$PREFIX/" 2>>"$LOG" || COPY_OK=0; }
[ "$COPY_OK" -eq 1 ] || die "Could not copy files to $PREFIX (see $LOG)"
# The app is executed by an unprivileged user but installed by root. Make the
# program tree root-owned and non-writable by normal users.
chown -R root:root "$PREFIX" 2>>"$LOG" || die "Could not secure ownership of $PREFIX (see $LOG)"
chmod -R go-w "$PREFIX" 2>>"$LOG" || die "Could not secure permissions of $PREFIX (see $LOG)"
# v1.2.5 LAUNCH FIX — the REAL bug behind 'the process exited immediately':
# this installer runs with umask 077, so every cp above landed root-only
# (0600 files / 0700 dirs) and the desktop user could not read /opt/walix at
# all — the launcher died with 'App files not found' before Qt even loaded.
# 'chmod -R go-w' alone never restores read access. Normalise explicitly:
#   directories  0755 — traversable by everyone, writable only by root
#   regular files 0644 — readable by everyone, writable only by root
#   the three entry scripts 0755 — directly executable
# The tree stays root-owned and non-writable by normal users (unchanged
# security model); it just becomes READABLE again.
find "$PREFIX" -type d -exec chmod 755 {} + 2>>"$LOG" || die "Could not set directory permissions of $PREFIX (see $LOG)"
find "$PREFIX" -type f -exec chmod 644 {} + 2>>"$LOG" || die "Could not set file permissions of $PREFIX (see $LOG)"
chmod 755 "$PREFIX/walix.py" "$PREFIX/walix-launcher.sh" "$PREFIX/uninstall.sh" 2>>"$LOG" || true
# Final proof, not hope: the desktop user must be able to read the payload.
if [ -n "${SUDO_USER:-}" ] && ! sudo -u "$SUDO_USER" head -c 1 "$PREFIX/payload.bin" >/dev/null 2>&1; then
  die "$PREFIX is still unreadable for user $SUDO_USER — aborting instead of shipping a broken install"
fi
# Never delete source files or caches. If a previous installation contains
# readable app sources, fail closed and leave everything untouched.
LEFTOVER_SOURCE="$(find "$PREFIX/walix_core" -type f -name "*.py" 2>/dev/null | head -n 1 || true)"
[ -z "$LEFTOVER_SOURCE" ] || die "Readable source detected at $LEFTOVER_SOURCE; nothing was deleted. Review the existing installation manually."

# real launcher (NOT a symlink): guards root/display, shows real errors
if ! sed "s|__WALIX_HOME__|$PREFIX|g" "$SRC_DIR/walix-launcher.sh" > "$BIN" 2>>"$LOG"; then
  die "Could not write the launcher to $BIN (see $LOG)"
fi
chmod 755 "$BIN"
cp "$SRC_DIR/uninstall.sh" "$UNINSTALL_BIN"
chmod 755 "$UNINSTALL_BIN"

mkdir -p "$ICON_DIR"
if [ -f "$SRC_DIR/assets/icon.png" ]; then
  cp "$SRC_DIR/assets/icon.png" "$ICON_DIR/walix.png"
  chmod 644 "$ICON_DIR/walix.png"
  # v1.1.1: every hicolor size ships the SAME fresh dragon mark — the menu,
  # taskbar, alt-tab and the notification icon can never show a stale icon.
  # v1.2.5: every icon is installed world-readable (umask 077 used to make
  # them 0600 root — the Kali menu icon silently disappeared).
  for size in 256 128 64 48 32 24 16; do
    sizedir="${ICON_DIR/512x512/${size}x${size}}"
    src=""; [ -f "$SRC_DIR/assets/icons/walix-$size.png" ] && src="$SRC_DIR/assets/icons/walix-$size.png"
    [ -z "$src" ] && src="$SRC_DIR/assets/icon.png"
    mkdir -p "$sizedir" && chmod 755 "$sizedir" && cp "$src" "$sizedir/walix.png" 2>>"$LOG" && chmod 644 "$sizedir/walix.png"
  done
fi

# desktop entry with real install path
sed "s|__WALIX_HOME__|$PREFIX|g" "$SRC_DIR/walix.desktop" > "$DESKTOP_DST"
chmod 644 "$DESKTOP_DST"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database >/dev/null 2>&1
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f "$ICON_DIR/../../" >/dev/null 2>&1

# verify every installed path — never claim success with missing files.
# Payload build: walix.py + payload.bin. Source build: the walix_core tree.
VERIFY_FILES=("$PREFIX/walix.py" "$PREFIX/assets/icon.png" "$PREFIX/walix-launcher.sh" \
              "$PREFIX/uninstall.sh" "$BIN" "$UNINSTALL_BIN" "$DESKTOP_DST" \
              "$ICON_DIR/walix.png")
if [ -f "$PREFIX/payload.bin" ]; then
  VERIFY_FILES+=("$PREFIX/payload.bin")
else
  VERIFY_FILES+=("$PREFIX/walix_core/ui/dialogs.py" "$PREFIX/walix_core/ui/styles.py" \
                 "$PREFIX/walix_core/ui/splash.py" "$PREFIX/walix_core/ui/hud.py" \
                 "$PREFIX/walix_core/web/whatsapp_style.py")
fi
for f in "${VERIFY_FILES[@]}"; do
  [ -e "$f" ] || die "Installation incomplete — missing $f (see $LOG)"
done
# v1.1.0 code protection: after install the app dir must hold zero *.py
# inside walix_core (payload build) — assert it when payload.bin exists.
if [ -f "$PREFIX/payload.bin" ]; then
  LEFTOVER=$(find "$PREFIX/walix_core" -type f -name "*.py" 2>/dev/null | head -n 1)
  [ -z "$LEFTOVER" ] || die "Code protection violated — readable source at $LEFTOVER"
  ok "Code protection verified — app ships as encrypted bytecode only"
fi
ok "All installed paths verified"

ok "App files        → $PREFIX"
ok "Launcher command → $BIN (with root/display guards + error log)"
ok "Menu entry       → $DESKTOP_DST (Kali menu → Internet → Walix)"
ok "Uninstaller      → $UNINSTALL_BIN"

# launcher smoke-check: --version proves imports + wrapper wiring work.
# v1.2.5: run it AS THE DESKTOP USER too — a root-only check used to pass
# even when the app tree was unreadable for the user (the silent-kill bug).
if "$BIN" --version >>"$LOG" 2>&1; then
  ok "Launcher verified (root) → $("$BIN" --version 2>/dev/null | head -n1)"
else
  warn "Launcher self-test failed — run 'walix'; the error will show there"
fi
if [ -n "${SUDO_USER:-}" ]; then
  USER_HOME_CHK="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)"
  [ -n "$USER_HOME_CHK" ] || USER_HOME_CHK="/home/$SUDO_USER"
  if sudo -u "$SUDO_USER" env HOME="$USER_HOME_CHK" "$BIN" --version >>"$LOG" 2>&1; then
    ok "Launcher verified as $SUDO_USER — the desktop user can really run it"
  else
    die "Launcher check FAILED for user $SUDO_USER (see $LOG) — check permissions of $PREFIX and re-run"
  fi
fi

# ---------- 4. ethics + launch ----------
echo
msg "Step 4/4 — One thing before launch…"
type_text "  Walix v1.2.5 Dragon Edition — LAUNCH FIXED, permissions repaired!"
type_text "  Fixed in 1.2.5: the installer made /opt/walix root-only — 'walix' died"
type_text "  instantly with 'App files not found'. Now verified as YOUR user too."
type_text "  No sound? View menu → 'Test sound' — or click 'Sound' in the status bar."
type_text "  Walix is an ETHICAL TOOL: only your own WhatsApp account, nothing hidden."
type_text "  On first launch a QR code appears — scan it with your phone and enjoy!"

printf "  ${W}Start Walix now?${N} [Y/n] "
read -r ans
case "$ans" in
  n*|N*) ;;
  *)
    # find the graphical session of the real (non-root) user and forward
    # exactly the environment a GUI session needs — nothing more
    USER_NAME="${SUDO_USER:-}"
    U_ID="$(id -u "${USER_NAME:-root}" 2>/dev/null || true)"
    RT="/run/user/${U_ID:-0}"
    ENVARGS=()
    # X11: scan the X sockets first, fall back to the inherited DISPLAY
    DISP=""
    for xsock in /tmp/.X11-unix/X*; do
      [ -S "$xsock" ] || continue
      DISP=":${xsock##*X}"
      break
    done
    if [ -n "$DISP" ]; then
      ENVARGS+=("DISPLAY=$DISP")
    elif [ -n "${DISPLAY:-}" ]; then
      ENVARGS+=("DISPLAY=$DISPLAY")
    fi
    # Wayland: session socket + runtime dir (Qt needs XDG_RUNTIME_DIR to
    # find the Wayland socket — without it every Wayland launch fails)
    WLD=""
    if [ -d "$RT" ]; then
      for wsock in "$RT"/wayland-*; do
        [ -e "$wsock" ] || continue
        WLD="${wsock##*/}"
        break
      done
    fi
    if [ -n "$WLD" ]; then
      ENVARGS+=("WAYLAND_DISPLAY=$WLD")
      ENVARGS+=("XDG_RUNTIME_DIR=$RT")
    fi
    # v1.2.1 SOUND FIX: PulseAudio lives at $XDG_RUNTIME_DIR/pulse/native.
    # Without this variable Chromium cannot find the audio server and
    # videos play SILENT — the exact field report of v1.1.1. It used to
    # be passed only for Wayland launches; now EVERY launch carries it.
    if [ -d "$RT" ]; then
      ENVARGS+=("XDG_RUNTIME_DIR=$RT")
    fi
    [ -n "${PULSE_SERVER:-}" ] && ENVARGS+=("PULSE_SERVER=$PULSE_SERVER")
    # D-Bus session bus (system tray + notifications under Wayland)
    if [ -S "$RT/bus" ]; then
      ENVARGS+=("DBUS_SESSION_BUS_ADDRESS=unix:path=$RT/bus")
    fi
    # X authority: the user's file, an inherited path, or the runtime copy
    USER_HOME="$(getent passwd "$USER_NAME" 2>/dev/null | cut -d: -f6)"
    [ -n "$USER_HOME" ] || USER_HOME="/home/$USER_NAME"
    XAUTH_F=""
    for cand in "$USER_HOME/.Xauthority" "${XAUTHORITY:-}" \
                "$RT"/.mutter-Xwaylandauth.* "$RT"/xauth_*; do
      [ -n "$cand" ] && [ -f "$cand" ] || continue
      XAUTH_F="$cand"
      break
    done
    [ -n "$XAUTH_F" ] && ENVARGS+=("XAUTHORITY=$XAUTH_F")

    if [ "${#ENVARGS[@]}" -eq 0 ]; then
      warn "No graphical session found — run 'walix' in your terminal."
    elif [ -z "$USER_NAME" ]; then
      # started via 'su' with no SUDO_USER: Walix refuses root by design
      warn "No desktop user detected — run 'walix' as your normal user."
    else
      msg "Launching as ${USER_NAME} with session env: ${ENVARGS[*]%%=*}…"
      LAUNCH_LOG="$USER_HOME/.cache/walix/install-launch.log"
      sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.cache/walix" 2>>"$LOG" || true
      # v1.2.5: the redirect below runs as root and used to create the log
      # root-owned 0600 — the user could not read their own launch errors.
      touch "$LAUNCH_LOG" 2>>"$LOG" && chown "$USER_NAME" "$LAUNCH_LOG" 2>>"$LOG" && chmod 644 "$LAUNCH_LOG" 2>>"$LOG"
      sudo -u "$USER_NAME" env HOME="$USER_HOME" USER="$USER_NAME" LOGNAME="$USER_NAME" \
        PATH="${PATH:-/usr/local/bin:/usr/bin:/bin}" "${ENVARGS[@]}" \
        nohup "$BIN" >>"$LAUNCH_LOG" 2>&1 &
      LAUNCH_PID=$!
      sleep 3
      if kill -0 "$LAUNCH_PID" 2>/dev/null; then
        ok "Walix is running — scan the QR code!"
      else
        warn "The Walix process exited immediately — that is why no window appeared."
        warn "The launch output was saved to: $LAUNCH_LOG"
        warn "The application error log is: $USER_HOME/.cache/walix/error.log"
        warn "Run 'walix' as your normal user to see the error directly."
      fi
    fi
    ;;
esac

echo
bar "installation complete"
printf "%b\n" "${G}  ┌──────────────────────────────────────────────┐${N}"
printf "%b\n" "${G}  │${W}  Walix v1.2.5 Dragon Edition installed!        ${G}│${N}"
printf "%b\n" "${G}  │${D}  Terminal : ${N}walix${D}                        ${G}│${N}"
printf "%b\n" "${G}  │${D}  Menu     : ${N}Kali → Internet → Walix${D}       ${G}│${N}"
printf "%b\n" "${G}  │${D}  Sound?   : ${N}View → Test sound${D} / status bar   ${G}│${N}"
printf "%b\n" "${G}  │${D}  Console  : ${N}Ctrl+K${D}  → try ${N}:theme dragon${D}     ${G}│${N}"
printf "%b\n" "${G}  │${D}  Doctor?  : ${N}walix --doctor${D}                  ${G}│${N}"
printf "%b\n" "${G}  │${D}  Stuck?   : ${N}walix --kill${D}  then ${N}walix${D}     ${G}│${N}"
printf "%b\n" "${G}  │${D}  Errors?  : ${N}~/.cache/walix/error.log${D}       ${G}│${N}"
printf "%b\n" "${G}  │${D}  Remove   : ${N}sudo walix-uninstall${D}         ${G}│${N}"
printf "%b\n" "${G}  └──────────────────────────────────────────────┘${N}"
echo

msg "Source-preservation mode — extracted folder, setup tools, and ZIP archives were not deleted"
echo
