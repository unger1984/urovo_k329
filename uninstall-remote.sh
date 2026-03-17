#!/bin/bash
#
# Удалённое удаление драйвера Urovo K329
#
# Использование:
#   curl -fsSL https://raw.githubusercontent.com/unger1984/urovo_k329/main/uninstall-remote.sh | bash
#
echo "=== Удаление драйвера Urovo K329 ==="

sudo lpadmin -x Urovo_K329 2>/dev/null && echo "Принтер удалён" || echo "Принтер не найден"
sudo launchctl unload /Library/LaunchDaemons/com.urovo.k329.printer.plist 2>/dev/null
sudo rm -f /Library/LaunchDaemons/com.urovo.k329.printer.plist
sudo rm -f /usr/libexec/cups/backend/urovo329
sudo rm -f /usr/libexec/cups/filter/urovo-k329
sudo rm -f /usr/local/bin/urovo-print-helper
sudo rm -f /Library/Printers/PPDs/Contents/Resources/Urovo-K329.ppd
sudo rm -f /private/etc/cups/ppd/Urovo_K329.ppd
sudo rm -rf /var/spool/urovo329
sudo launchctl stop org.cups.cupsd
sudo launchctl start org.cups.cupsd

echo "=== Удаление завершено ==="
