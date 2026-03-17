#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

# Определяем homebrew prefix (ARM vs Intel Mac)
if [ -d "/opt/homebrew" ]; then
    BREW_PREFIX="/opt/homebrew"
elif [ -d "/usr/local/Cellar" ]; then
    BREW_PREFIX="/usr/local"
else
    echo "Homebrew не найден. Установите: https://brew.sh"
    exit 1
fi

echo "=== Установка драйвера Urovo K329 ==="
echo "Homebrew: $BREW_PREFIX"

# Зависимости
echo "Проверка зависимостей..."
command -v "$BREW_PREFIX/bin/gs" >/dev/null || { echo "Нужен Ghostscript: brew install ghostscript"; exit 1; }
brew list libusb >/dev/null 2>&1 || { echo "Нужен libusb: brew install libusb"; exit 1; }
pip3 install --user pyusb >/dev/null 2>&1 || { echo "Не удалось установить pyusb"; exit 1; }
echo "OK"

# Записываем brew prefix для helper
echo "$BREW_PREFIX" > "$DIR/.brew_prefix"

# Helper
sudo cp -f "$DIR/urovo-print-helper" /usr/local/bin/urovo-print-helper
sudo chmod 755 /usr/local/bin/urovo-print-helper

# Backend
sudo cp -f "$DIR/urovo-k329-backend" /usr/libexec/cups/backend/urovo329
sudo chmod 700 /usr/libexec/cups/backend/urovo329

# Фильтр
sudo cp -f "$DIR/urovo-k329" /usr/libexec/cups/filter/urovo-k329
sudo chmod 755 /usr/libexec/cups/filter/urovo-k329

# PPD
sudo cp -f "$DIR/Urovo-K329.ppd" /Library/Printers/PPDs/Contents/Resources/Urovo-K329.ppd
sudo cp -f "$DIR/Urovo-K329.ppd" /private/etc/cups/ppd/Urovo_K329.ppd

# Spool
sudo mkdir -p /var/spool/urovo329
sudo chmod 777 /var/spool/urovo329

# Launchd daemon — подставляем правильный DYLD_LIBRARY_PATH
sed "s|/opt/homebrew/lib|$BREW_PREFIX/lib|g" "$DIR/com.urovo.k329.printer.plist" > /tmp/com.urovo.k329.printer.plist
sudo launchctl unload /Library/LaunchDaemons/com.urovo.k329.printer.plist 2>/dev/null || true
sudo cp -f /tmp/com.urovo.k329.printer.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.urovo.k329.printer.plist

# Пересоздать принтер
sudo lpadmin -x Urovo_K329 2>/dev/null || true
sudo launchctl stop org.cups.cupsd
sudo launchctl start org.cups.cupsd
sleep 2
sudo lpadmin -p Urovo_K329 -E -v 'urovo329://USB' -P /Library/Printers/PPDs/Contents/Resources/Urovo-K329.ppd

echo "=== Готово ==="
echo "Принтер 'Urovo_K329' добавлен. Печатайте из любого приложения."
