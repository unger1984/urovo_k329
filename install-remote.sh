#!/bin/bash
#
# Удалённая установка драйвера Urovo K329 для macOS
#
# Использование:
#   curl -fsSL https://raw.githubusercontent.com/unger1984/urovo_k329/main/install-remote.sh | bash
#
set -e

REPO="https://raw.githubusercontent.com/unger1984/urovo_k329/main/driver"
TMP_DIR=$(mktemp -d)

echo "=== Установка драйвера Urovo K329 ==="

# Определяем homebrew prefix
if [ -d "/opt/homebrew" ]; then
    BREW_PREFIX="/opt/homebrew"
elif [ -d "/usr/local/Cellar" ]; then
    BREW_PREFIX="/usr/local"
else
    echo "Homebrew не найден. Установите: https://brew.sh"
    exit 1
fi
echo "Homebrew: $BREW_PREFIX"

# Зависимости
echo "Проверка зависимостей..."

command -v python3 >/dev/null || { echo "Python 3 не найден. Установите: xcode-select --install"; exit 1; }
echo "  Python 3: OK"

if ! command -v "$BREW_PREFIX/bin/gs" >/dev/null 2>&1; then
    echo "  Ghostscript не найден. Устанавливаю: brew install ghostscript"
    brew install ghostscript || { echo "Ошибка установки. Установите вручную: brew install ghostscript"; exit 1; }
fi
echo "  Ghostscript: OK"

if ! brew list libusb >/dev/null 2>&1; then
    echo "  libusb не найден. Устанавливаю: brew install libusb"
    brew install libusb || { echo "Ошибка установки. Установите вручную: brew install libusb"; exit 1; }
fi
echo "  libusb: OK"

if ! python3 -c "import usb" 2>/dev/null; then
    echo "  pyusb не найден. Устанавливаю: pip3 install --user pyusb"
    pip3 install --user pyusb || { echo "Ошибка установки. Установите вручную: pip3 install --user pyusb"; exit 1; }
fi
echo "  pyusb: OK"

if ! python3 -c "import serial" 2>/dev/null; then
    echo "  pyserial не найден. Устанавливаю: pip3 install --user pyserial"
    pip3 install --user pyserial || { echo "Ошибка установки. Установите вручную: pip3 install --user pyserial"; exit 1; }
fi
echo "  pyserial: OK"

# Скачиваем файлы
echo "Скачивание файлов..."
FILES="urovo-print-helper urovo-k329-backend urovo-k329 Urovo-K329.ppd com.urovo.k329.printer.plist"
for f in $FILES; do
    curl -fsSL "$REPO/$f" -o "$TMP_DIR/$f" || { echo "Ошибка скачивания $f"; exit 1; }
done
echo "OK"

# Helper
sudo cp -f "$TMP_DIR/urovo-print-helper" /usr/local/bin/urovo-print-helper
sudo chmod 755 /usr/local/bin/urovo-print-helper

# Backend
sudo cp -f "$TMP_DIR/urovo-k329-backend" /usr/libexec/cups/backend/urovo329
sudo chmod 700 /usr/libexec/cups/backend/urovo329

# Фильтр
sudo cp -f "$TMP_DIR/urovo-k329" /usr/libexec/cups/filter/urovo-k329
sudo chmod 755 /usr/libexec/cups/filter/urovo-k329

# PPD
sudo cp -f "$TMP_DIR/Urovo-K329.ppd" /Library/Printers/PPDs/Contents/Resources/Urovo-K329.ppd
sudo cp -f "$TMP_DIR/Urovo-K329.ppd" /private/etc/cups/ppd/Urovo_K329.ppd

# Spool
sudo mkdir -p /var/spool/urovo329
sudo chmod 777 /var/spool/urovo329

# Launchd daemon
sed "s|/opt/homebrew/lib|$BREW_PREFIX/lib|g" "$TMP_DIR/com.urovo.k329.printer.plist" > "$TMP_DIR/com.urovo.k329.printer.fixed.plist"
sudo launchctl unload /Library/LaunchDaemons/com.urovo.k329.printer.plist 2>/dev/null || true
sudo cp -f "$TMP_DIR/com.urovo.k329.printer.fixed.plist" /Library/LaunchDaemons/com.urovo.k329.printer.plist
sudo launchctl load /Library/LaunchDaemons/com.urovo.k329.printer.plist

# Принтер
sudo lpadmin -x Urovo_K329 2>/dev/null || true
sudo launchctl stop org.cups.cupsd
sudo launchctl start org.cups.cupsd
sleep 2
sudo lpadmin -p Urovo_K329 -E -v 'urovo329://USB' -P /Library/Printers/PPDs/Contents/Resources/Urovo-K329.ppd

# Очистка
rm -rf "$TMP_DIR"

echo ""
echo "=== Готово ==="
echo "Принтер 'Urovo_K329' добавлен. Печатайте из любого приложения."
echo ""
echo "Принтер должен быть в режиме TSPL (Settings → Command → TSPL)"
echo ""
echo "Удаление: curl -fsSL $REPO/../uninstall-remote.sh | bash"
