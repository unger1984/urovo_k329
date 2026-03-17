#!/bin/bash
echo "=== Удаление драйвера Urovo K329 ==="

# Принтер
sudo lpadmin -x Urovo_K329 2>/dev/null && echo "Принтер удалён" || echo "Принтер не найден"

# Launchd daemon
sudo launchctl unload /Library/LaunchDaemons/com.urovo.k329.printer.plist 2>/dev/null
sudo rm -f /Library/LaunchDaemons/com.urovo.k329.printer.plist
echo "Launchd daemon удалён"

# Backend, фильтр, helper
sudo rm -f /usr/libexec/cups/backend/urovo329
sudo rm -f /usr/libexec/cups/filter/urovo-k329
sudo rm -f /usr/local/bin/urovo-print-helper
echo "Backend, фильтр, helper удалены"

# PPD
sudo rm -f /Library/Printers/PPDs/Contents/Resources/Urovo-K329.ppd
sudo rm -f /private/etc/cups/ppd/Urovo_K329.ppd
echo "PPD удалён"

# Spool
sudo rm -rf /var/spool/urovo329
echo "Spool удалён"

# Перезапуск CUPS
sudo launchctl stop org.cups.cupsd
sudo launchctl start org.cups.cupsd

echo "=== Удаление завершено ==="
