#!/usr/bin/env bash
#
# runvard – Deinstallation
# Aufruf:  sudo bash uninstall.sh        (oder als root:  bash uninstall.sh)
#
set -euo pipefail

# ─────────────────────────── Farben & Symbole ───────────────────────────
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[0;31m'; GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'; CYAN=$'\033[0;36m'; PURPLE=$'\033[0;35m'; NC=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; CYAN=""; PURPLE=""; NC=""
fi
step()  { echo -e "\n${PURPLE}${BOLD}▸ $*${NC}"; }
info()  { echo -e "  ${DIM}$*${NC}"; }
ok()    { echo -e "  ${GREEN}✓${NC} $*"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $*"; }
die()   { echo -e "\n${RED}✗ $*${NC}\n" >&2; exit 1; }
trap 'die "Etwas ist schiefgelaufen (Zeile $LINENO)."' ERR

INSTALL_DIR="/opt/runvard"
SERVICE_FILE="/etc/systemd/system/runvard.service"
SERVICE="runvard"

# ─────────────────────────── Optionen ───────────────────────────
PURGE=0
ASSUME_YES=0
usage() {
  cat << USAGE
runvard – Deinstallation

Verwendung:
  sudo bash uninstall.sh [Optionen]

Optionen:
  --purge      Auch Daten/Konfiguration löschen (Konten, Schlüssel, Zertifikate)
               – ohne Sicherung! Standardmäßig werden die Daten vorher gesichert.
  -y, --yes    Ohne Rückfrage durchführen
  -h, --help   Diese Hilfe anzeigen

Was NICHT entfernt wird (bewusst):
  - Über apt installierte Pakete (Docker, Samba, libvirt …) – könnten anderswo
    genutzt werden.
  - System-Änderungen, die du IN runvard gemacht hast (Samba-/NFS-Freigaben,
    OS-Benutzer, sudo-Regeln, Cron-Jobs). Diese bleiben bestehen.
USAGE
}
while [ $# -gt 0 ]; do
  case "$1" in
    --purge)   PURGE=1; shift ;;
    -y|--yes)  ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)         die "Unbekannte Option: $1  (--help für Hilfe)" ;;
  esac
done

# ─────────────────────────── Banner ───────────────────────────
echo -e "\n${CYAN}${BOLD}  runvard – Deinstallation${NC}\n"

[ "$(id -u)" -eq 0 ] || die "Bitte als root ausführen:  ${BOLD}sudo bash uninstall.sh${NC}  (oder zuerst ${BOLD}su -${NC})"

# Nichts installiert?
if [ ! -e "$INSTALL_DIR" ] && [ ! -e "$SERVICE_FILE" ]; then
  ok "runvard ist nicht installiert – nichts zu tun."
  exit 0
fi

# ─────────────────────────── Bestätigung ───────────────────────────
echo -e "  Entfernt werden:"
echo -e "    • Dienst   ${BOLD}${SERVICE}${NC}  (stoppen, deaktivieren, Unit löschen)"
echo -e "    • Ordner   ${BOLD}${INSTALL_DIR}${NC}"
if [ "$PURGE" = "1" ]; then
  echo -e "    • Daten    ${RED}${BOLD}werden mitgelöscht (keine Sicherung!)${NC}"
else
  echo -e "    • Daten    ${GREEN}werden vorher gesichert${NC} ${DIM}(Konten, Schlüssel, Zertifikate)${NC}"
fi
echo
if [ "$ASSUME_YES" != "1" ]; then
  read -r -p "  Wirklich deinstallieren? (j/N) " ans </dev/tty || ans=""
  case "$ans" in j|J|y|Y|ja|Ja|yes) : ;; *) die "Abgebrochen. Es wurde nichts verändert." ;; esac
fi

# ─────────────────────────── 1. Dienst stoppen ───────────────────────────
step "[1/3] Dienst stoppen und entfernen"
if command -v systemctl >/dev/null 2>&1; then
  systemctl stop "$SERVICE" 2>/dev/null || true
  systemctl disable "$SERVICE" 2>/dev/null || true
fi
if [ -f "$SERVICE_FILE" ]; then
  rm -f "$SERVICE_FILE"
  command -v systemctl >/dev/null 2>&1 && systemctl daemon-reload 2>/dev/null || true
  ok "Dienst gestoppt und Unit entfernt."
else
  info "Keine systemd-Unit gefunden – übersprungen."
fi

# ─────────────────────────── 2. Daten sichern ───────────────────────────
BACKUP=""
step "[2/3] Daten"
if [ "$PURGE" = "1" ]; then
  warn "--purge: Daten werden NICHT gesichert."
elif [ -d "$INSTALL_DIR/data" ]; then
  BACKUP_DIR="${BACKUP_DIR:-/root}"
  [ -w "$BACKUP_DIR" ] || BACKUP_DIR="/tmp"
  BACKUP="${BACKUP_DIR}/runvard-data-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  if tar -czf "$BACKUP" -C "$INSTALL_DIR" data 2>/dev/null; then
    ok "Daten gesichert: ${BOLD}${BACKUP}${NC}"
  else
    BACKUP=""
    warn "Sicherung fehlgeschlagen – fahre fort (Daten werden mit dem Ordner entfernt)."
  fi
else
  info "Kein data-Verzeichnis vorhanden – nichts zu sichern."
fi

# ─────────────────────────── 3. Dateien entfernen ───────────────────────────
step "[3/3] Programmdateien entfernen"
if [ -e "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
  ok "${INSTALL_DIR} entfernt."
else
  info "${INSTALL_DIR} existierte nicht."
fi

# ─────────────────────────── Abschluss ───────────────────────────
echo
echo -e "${GREEN}${BOLD}  runvard wurde deinstalliert.${NC}"
echo
if [ -n "$BACKUP" ]; then
  echo -e "  💾  Daten-Sicherung: ${BOLD}${BACKUP}${NC}"
  echo -e "      ${DIM}Wiederherstellen nach einer Neuinstallation:${NC}"
  echo -e "      ${DIM}tar -xzf ${BACKUP} -C /opt/runvard && systemctl restart runvard${NC}"
  echo
fi
info "Nicht entfernt: apt-Pakete (Docker, Samba, libvirt …) sowie in runvard"
info "vorgenommene System-Änderungen (Freigaben, Benutzer, sudo-Regeln, Cron)."
echo
