#!/usr/bin/env bash
# ============================================================
#  Walix launcher (walix command)
#  - never runs as root (the WhatsApp session belongs to your normal user)
#  - checks the graphical session before starting
#  - prefers the isolated venv the installer may have created
#  - shows the real error instead of dying silently
# ============================================================
APP_HOME="__WALIX_HOME__"
APP="$APP_HOME/walix.py"
# Protected Python modules use a virtual walix:// __file__; explicitly pass
# the installed asset directory so splash/icons/theme assets always resolve.
export WALIX_ASSETS="$APP_HOME/assets"
LOG="$HOME/.cache/walix/error.log"

G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; N='\033[0m'
if [ ! -t 1 ]; then G=''; Y=''; R=''; C=''; N=''; fi

# --- harmless args (--version / --help / --kill) may run as root too ---
case "${1:-}" in
  --version|--help|-h) SKIP_ROOT_GUARD=1 ;;
  *) SKIP_ROOT_GUARD=0 ;;
esac

# --- root guard ---
if [ "$SKIP_ROOT_GUARD" != "1" ] && [ "$(id -u)" = "0" ]; then
  printf "%b\n" "${R}[Walix]${N} Never run Walix as root — the WhatsApp session belongs to your normal user (it breaks under root)."
  printf "%b\n" "${R}[Walix]${N} Run it from your own account:   walix"
  exit 1
fi

# --- Kali-only guard (exact ID=kali — same rules as installer and app) ---
os_id() {
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
  printf "%b\n" "${R}[Walix]${N} Walix is built only for Kali Linux (Kali-only tool)."
  if [ ! -r /etc/os-release ]; then
    printf "%b\n" "${R}[Walix]${N} /etc/os-release is missing — the OS cannot be identified."
  elif [ -z "$OS_ID" ]; then
    printf "%b\n" "${R}[Walix]${N} /etc/os-release is malformed — no usable ID field."
  else
    printf "%b\n" "${R}[Walix]${N} Detected OS ID '$OS_ID' is not Kali."
  fi
  exit 1
fi

# --- app present? ---
# v1.2.5: distinguish "files missing" from "files unreadable" — a root-only
# /opt/walix (the v1.2.4-and-earlier installer bug) used to show up as the
# misleading 'App files not found' and made the app look dead.
if [ ! -f "$APP" ]; then
  if [ -e "$APP" ] || [ -e "$APP_HOME/walix.py" ]; then
    printf "%b\n" "${R}[Walix]${N} App files exist but are NOT readable by your user:"
    ls -ld "$APP_HOME" "$APP_HOME/walix.py" 2>&1 | sed 's/^/[Walix] /'
    printf "%b\n" "${R}[Walix]${N} This is the old installer permission bug — repair with:"
    printf "%b\n" "${Y}[Walix]${N}   sudo chmod -R a+rX /opt/walix"
    printf "%b\n" "${Y}[Walix]${N} then start again:  walix"
  elif [ ! -e "$APP_HOME" ]; then
    printf "%b\n" "${R}[Walix]${N} App directory not found: $APP_HOME"
    printf "%b\n" "${Y}[Walix]${N} Reinstall with:  sudo ./install.sh"
  else
    printf "%b\n" "${R}[Walix]${N} App files not found: $APP"
    printf "%b\n" "${Y}[Walix]${N} Reinstall with:  sudo ./install.sh"
  fi
  exit 1
fi
# v1.2.5: also catch a payload the user cannot read before Python shows a
# raw traceback (payload.bin is what the whole app lives inside).
if [ -f "$APP_HOME/payload.bin" ] && [ ! -r "$APP_HOME/payload.bin" ]; then
  printf "%b\n" "${R}[Walix]${N} payload.bin is not readable by your user (old installer permission bug)."
  printf "%b\n" "${Y}[Walix]${N} Repair with:  sudo chmod -R a+rX /opt/walix"
  exit 1
fi

# --- graphical session guard ---
if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
  printf "%b\n" "${R}[Walix]${N} No graphical session found (DISPLAY is empty)."
  printf "%b\n" "${Y}[Walix]${N} Log in to the desktop and run it again."
  exit 1
fi

# --- v1.2.0 SOUND FIX: audio session env ---
# Chromium talks to PulseAudio/PipeWire over $XDG_RUNTIME_DIR/pulse/native.
# When this variable is missing (launched from a cron, an SSH display
# forward, some terminals, or via sudo), Chromium falls back to raw ALSA
# and WhatsApp videos play SILENT. Defaulting it to the per-user runtime
# directory restores sound — only for the real (non-root) user.
U_ID="$(id -u 2>/dev/null || echo 1000)"
if [ "$U_ID" != "0" ] && [ -z "${XDG_RUNTIME_DIR:-}" ] && [ -d "/run/user/$U_ID" ]; then
  export XDG_RUNTIME_DIR="/run/user/$U_ID"
fi

mkdir -p "$(dirname "$LOG")" 2>/dev/null

# --- python: prefer the engine that can actually PLAY WhatsApp videos ---
# v1.1.1 fix: the isolated venv holds pip wheels of PyQtWebEngine, and those
# wheels ship WITHOUT the proprietary H.264/AAC codecs — WhatsApp status
# videos and chat videos refuse to play there. The Kali apt build carries
# the codecs. So: system engine first (if it really imports), venv fallback.
PY="python3"
if ! python3 -c "import PyQt5.QtCore, PyQt5.QtWidgets, PyQt5.QtWebEngineWidgets" \
      >/dev/null 2>&1; then
  if [ -x "$APP_HOME/venv/bin/python" ]; then
    PY="$APP_HOME/venv/bin/python"
    printf "%b\n" "${Y}[Walix]${N} Using the isolated venv engine (system Qt is broken — videos may not play)."
    printf "%b\n" "${Y}[Walix]${N} Fix:  sudo apt install python3-pyqt5 python3-pyqt5.qtwebengine"
  fi
fi

# --- run ---
# Used by the precise --kill implementation; prevents matching an unrelated
# Python program that happens to be named walix.py.
export WALIX_APP_PATH="$APP"
"$PY" "$APP" "$@"
rc=$?

if [ "$rc" -ne 0 ] && [ "$rc" -ne 130 ] && [ "$rc" -ne 2 ]; then
  printf "%b\n" "${R}[Walix]${N} Walix exited with an error (exit code $rc)."
  if [ -f "$LOG" ]; then
    printf "%b\n" "${C}[Walix]${N} Last error lines (full log: $LOG):"
    tail -n 12 "$LOG" | sed 's/^/    /'
  fi
  printf "%b\n" "${Y}[Walix]${N} Fix: reinstall dependencies →  sudo ./install.sh"
  printf "%b\n" "${Y}[Walix]${N}      or stop a stuck instance →    walix --kill"
fi
exit "$rc"
