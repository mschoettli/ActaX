# Installation

Nexus is installed on a Debian or Ubuntu server with the included `install.sh` script.
Copy the project directory to the target server, enter the directory, and run the installer with root privileges.

```bash
scp -r nexus/ user@server:/tmp/
ssh user@server
cd /tmp/nexus
sudo bash install.sh
```

The installer installs required system packages, creates the Python virtual environment, installs Python dependencies, writes the systemd service, and starts Nexus.
It asks for the admin username, admin password, and web port.
If the password is left empty, the installer generates a random password and prints it at the end.
The selected username, password, and port are stored in `/opt/nexus/data/nexus.env` and loaded by the systemd service.
After installation, Nexus is available at the address printed by the installer; the default port is `8080`.

## Offline Installation

If the bundled `wheels/` directory is present, `install.sh` installs Python packages from those local wheel files without internet access.
The bundled wheels are intended for Python 3.13 on x86_64 Linux.
For an online installation, the `wheels/` directory can be removed before running the installer.
Virtual machine support may still require internet access for the Python bindings if they are not available from the bundled files.

## Service Management

```bash
systemctl status nexus
systemctl restart nexus
journalctl -u nexus -f
systemctl stop nexus
```

## Uninstall

Run the uninstall script from the Nexus directory on the server.

```bash
sudo bash uninstall.sh
```

The default uninstall stops and removes the Nexus service and backs up the data directory before removing `/opt/nexus`.
Use `--purge` to remove Nexus and its data without creating a backup.

```bash
sudo bash uninstall.sh --purge
```

Packages installed through the system package manager and host changes made through Nexus, such as shares, users, sudo policy, or cron entries, are not removed automatically.
