# Nexus

**Your server. Your control.**

Ein Web-Interface zur Verwaltung von Debian-Servern – im Stil von Umbrel OS.
System-Monitoring, Terminal, Dateimanager, Speicher/RAID, Docker, VMs, Backups,
Netzwerk-Freigaben und mehr, alles in einem Glassmorphism-Dashboard.

---

## Installation

```bash
# Auf den Debian-Server kopieren
scp -r nexus/ user@server:/tmp/

# Auf dem Server
cd /tmp/nexus
sudo bash install.sh
```

Der geführte Installations-Assistent installiert alle Abhängigkeiten
(vollständige Installation), richtet eine Python-Umgebung und einen
systemd-Service ein und fragt nach Benutzername, Passwort und Port. Ein leeres
Passwort erzeugt automatisch ein sicheres Zufallspasswort. Die Zugangsdaten und
der Port werden in `data/nexus.env` abgelegt und vom Dienst per `EnvironmentFile`
gelesen.

Danach erreichbar unter der am Ende angezeigten Adresse (Standard-Port `8080`).

### Offline-Installation

Liegt der Ordner `nexus/wheels/` im Paket, installiert `install.sh` die Python-Pakete
automatisch daraus – **ohne Internet** (passend für Python 3.13 / x86_64). Für eine
Online-Installation kann der Ordner gelöscht werden. VM-Funktionen (libvirt-python)
benötigen weiterhin Internet bzum Kompilieren.

### Deinstallation

```bash
sudo bash uninstall.sh           # Daten werden vorher gesichert
sudo bash uninstall.sh --purge   # inkl. Daten löschen (ohne Sicherung)
```
Entfernt Dienst und `/opt/nexus`. Über apt installierte Pakete und in Nexus
vorgenommene System-Änderungen (Freigaben, Benutzer, sudo, Cron) bleiben bestehen.

---

## Module

| Modul | Funktion |
|-------|----------|
| **Live-Widgets** | CPU, RAM, Disk, Netzwerk in Echtzeit |
| **Terminal** | Vollwertige Bash-Shell im Browser (WebSocket + PTY): Puffer-Suche, klickbare Links, Unicode 11, Kopieren/Einfügen, Schriftgröße, Status-Anzeige & Reconnect |
| **Dateien** | Explorer, Upload/Download, Markdown-Editor, Root-Schutz |
| **Speicher** | Disks, Partitionierung, Formatierung, RAID, SMART, Swap, LVM, LUKS-Verschlüsselung, ZFS-/Btrfs-Pools, iSCSI-Initiator, Dateisystem-Resize |
| **Docker** | Container (inkl. CPU-/RAM-Limits), Logs, Stats, Exec-Shell, Images, Registry-Suche, Compose, Volumes |
| **Services** | systemd-Services steuern |
| **VMs** | KVM/QEMU über libvirt: erstellen/klonen, Konsole, Snapshots, Hot-Edit von Disks/NICs, Storage-Pools & Volumes |
| **Backup** | RSync-Jobs, Verlauf |
| **Freigaben** | Samba, NFS, FTP |
| **Netzwerk** | Interfaces, Bond (LACP), Firewall |
| **Sicherheit** | Benutzer, Gruppen, SSL-Zertifikate, sudo-Policy, Passwort-Ablauf (chage) |
| **Monitoring** | Logs, Alerts, Benachrichtigungen |
| **System** | Info, Updates, Pakete (apt), AppArmor, Cron, Power, Wartung (unattended-upgrades, tuned, kdump, sosreport) |

---

## Architektur

```
/opt/nexus/
├── server.py          FastAPI-Hauptanwendung + alle Routen
├── modules/           Backend-Logik pro Modul
│   ├── system.py      psutil-Stats
│   ├── terminal.py    PTY-WebSocket
│   ├── files.py       Dateimanager
│   ├── storage.py     lsblk/parted/mdadm/smartctl
│   ├── docker_mgr.py  Docker SDK
│   ├── services.py    systemctl
│   ├── vms.py         libvirt
│   ├── backup.py      rsync
│   ├── shares.py      Samba/NFS/FTP
│   ├── network.py     ip/bond/ufw
│   ├── security.py    User/SSL
│   ├── monitoring.py  Logs/Alerts
│   └── system_mgr.py  Updates/Cron/Power/GPU
├── static/
│   └── index.html     Single-File Frontend
├── requirements.txt
├── install.sh
├── uninstall.sh
├── wheels/         (Offline-Python-Pakete, optional)
└── nexus.service
```

**Stack:** Python · FastAPI · uvicorn · xterm.js (+ fit/search/web-links/unicode11) · Chart.js · marked.js

---

## Sicherheit

- HTTP Basic Auth (Zugangsdaten via Umgebungsvariablen `NEXUS_USER` / `NEXUS_PASS`)
- Dateimanager: System-Verzeichnisse (`/proc`, `/sys`, `/etc` …) gesperrt/schreibgeschützt
- Disk-Operationen: Root-Device kann niemals verändert werden
- Läuft als root (für mdadm, parted, mount, libvirt etc. erforderlich)

> **Hinweis:** Nexus sollte nur im lokalen Netz oder hinter einem Reverse-Proxy
> mit HTTPS betrieben werden, nicht direkt öffentlich erreichbar.

---

## Befehle

```bash
systemctl status nexus      # Status
systemctl restart nexus     # Neustart
journalctl -u nexus -f      # Live-Logs
systemctl stop nexus        # Stoppen
```

## HTTPS / TLS (optional)

Nexus läuft standardmäßig per HTTP auf Port 8080. Für TLS:

1. Zertifikat erzeugen: in der Oberfläche unter **System → Sicherheit → SSL** ein
   Self-Signed-Zertifikat anlegen (landet unter `/opt/nexus/data/certs/<CN>.crt|.key`)
   oder ein eigenes Zertifikat dort ablegen.
2. In `/etc/systemd/system/nexus.service` die `ExecStart`-Zeile auf die in der Datei
   auskommentierte TLS-Variante umstellen (`--ssl-keyfile`/`--ssl-certfile`).
3. `systemctl daemon-reload && systemctl restart nexus` – Zugriff danach via `https://`.
