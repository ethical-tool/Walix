#!/usr/bin/env bash
# ============================================================
#  Walix — uninstaller  (sudo ./uninstall.sh  or  walix-uninstall)
#  Keeps your WhatsApp session in ~/.config/walix unless --purge.
# ============================================================
PREFIX="/opt/walix"
BIN="/usr/local/bin/walix"
UNINSTALL_BIN="/usr/local/bin/walix-uninstall"
DESKTOP="/usr/share/applications/walix.desktop"
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)"
TARGET_HOME="${TARGET_HOME:-${HOME:-/root}}"

if [ -t 1 ]; then
  G='\033[1;32m'; GG='\033[1;92m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; W='\033[1;97m'; D='\033[2m'; N='\033[0m'
else
  G=''; GG=''; Y=''; R=''; C=''; W=''; D=''; N=''
fi

ok()   { printf "%b\n" "${GG}[ ✔ ]${N} $*"; }
warn() { printf "%b\n" "${Y}[ ! ]${N} $*"; }
fail() { printf "%b\n" "${R}[ ✘ ]${N} $*"; }

if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo bash "$0" "$@"
  else
    fail "Please run as root:  sudo ./uninstall.sh"
    exit 1
  fi
fi

printf "%b\n" "${C}::${N} Walix uninstaller"
printf "  ${W}Remove Walix from this system?${N} [y/N] "
read -r ans
case "$ans" in
  y*|Y*) ;;
  *) warn "Aborted."; exit 0 ;;
esac

# stop Walix precisely: match the INSTALLED app path (not any "walix.py"
# string), then verify each PID really belongs to Walix before killing it —
# a broad pkill -f could take down unrelated processes
PIDS="$(pgrep -f -- "${PREFIX}/walix\.py" 2>/dev/null || true)"
for pid in $PIDS; do
  [ "$pid" = "$$" ] && continue
  if tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -Eq "(^| )${PREFIX}/walix\.py( |$)"; then
    if kill "$pid" 2>/dev/null; then
      ok "Stopped Walix process (PID $pid)"
    else
      warn "Could not stop process $pid (already gone?)"
    fi
  fi
done

# verify the processes really terminated; escalate to SIGKILL only for
# PIDs that were confirmed (via /proc cmdline) to be Walix
sleep 1
for pid in $(pgrep -f -- "${PREFIX}/walix\.py" 2>/dev/null || true); do
  tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -Eq "(^| )${PREFIX}/walix\.py( |$)" || continue
  warn "Process $pid survived SIGTERM — sending SIGKILL"
  kill -9 "$pid" 2>/dev/null || true
done
sleep 1
if pgrep -f -- "${PREFIX}/walix\.py" >/dev/null 2>&1; then
  warn "Some Walix processes may still be running — they will exit on their own."
else
  ok "All Walix processes stopped (verified)"
fi

rm -rf "$PREFIX"          && ok "Removed $PREFIX"
rm -f  "$BIN"             && ok "Removed $BIN"
rm -f  "$UNINSTALL_BIN"   && ok "Removed $UNINSTALL_BIN"
rm -f  "$DESKTOP"         && ok "Removed menu entry"
# every hicolor size the v1.1.1 installer ships the dragon mark into
for size in 512x512 256x256 128x128 64x64 48x48 32x32 24x24 16x16; do
  rm -f "/usr/share/icons/hicolor/$size/apps/walix.png" 2>/dev/null
done
ok "Removed icons (all sizes)"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database >/dev/null 2>&1

printf "  ${W}Also delete your WhatsApp session & settings (~/.config/walix)?${N} [y/N] "
read -r ans2
case "$ans2" in
  y*|Y*)
    rm -r -f "$TARGET_HOME/.config/walix" "$TARGET_HOME/.cache/walix"
    ok "Removed ~/.config/walix and ~/.cache/walix (logged out everywhere)"
    ;;
  *)
    warn "Session kept — future installs will not need the QR scan again."
    ;;
esac

printf "%b\n" "${GG}Walix removed. Take care!${N}"
