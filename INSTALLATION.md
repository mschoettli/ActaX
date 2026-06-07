# Installation

runvard can be installed on a Debian or Ubuntu server with one command.
Run the installer with root privileges on the target server.

```bash
curl -fsSL https://raw.githubusercontent.com/mschoettli/runvard/main/install.sh | sudo bash
```

The installer downloads the current runvard release when needed, installs required system packages, creates the Python virtual environment, installs Python dependencies, writes the systemd service, and starts runvard.
It asks for the admin username, admin password, and web port.
If the password is left empty, the installer generates a random password and prints it at the end.
The selected username, password, and port are stored in `/opt/runvard/data/runvard.env` and loaded by the systemd service.
After installation, runvard is available at the address printed by the installer; the default port is `8080`.

## Bundled Wheels

If the bundled `wheels/` directory is present, the installer uses those local wheel files first to speed up Python dependency installation.
The installer still uses the internet when required to update `pip`, install native Python bindings, and fetch system packages that are not available locally.
The bundled wheels are intended for Python 3.13 on x86_64 Linux.

## Service Management

```bash
systemctl status runvard
systemctl restart runvard
journalctl -u runvard -f
systemctl stop runvard
```

## Uninstall

Run the uninstall script from the runvard directory on the server.

```bash
sudo bash uninstall.sh
```

The default uninstall stops and removes the runvard service and backs up the data directory before removing `/opt/runvard`.
Use `--purge` to remove runvard and its data without creating a backup.

```bash
sudo bash uninstall.sh --purge
```

Packages installed through the system package manager and host changes made through runvard, such as shares, users, sudo policy, or cron entries, are not removed automatically.
