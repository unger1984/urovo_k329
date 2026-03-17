# Urovo K329 — драйвер печати для macOS

CUPS-драйвер для термопринтера этикеток Urovo K329, позволяющий печатать PDF из любого приложения macOS через стандартный диалог печати.

> **[English version](README.md)**

## Содержание

- [Как это работает](#как-это-работает)
- [Требования](#требования)
- [Установка](#установка)
- [Удаление](#удаление)
- [Печать](#печать)
- [Настройка принтера](#настройка-принтера)
- [Структура проекта](#структура-проекта)
- [Решение проблем](#решение-проблем)
- [Технические детали](#технические-детали)

## Как это работает

Прошивка Urovo K329 не поддерживает стандартные графические команды (ZPL ^GFA, TSPL BITMAP, CPCL EG) через USB на macOS. Драйвер обходит это ограничение:

1. CUPS принимает PDF и передаёт его в backend
2. Backend сохраняет PDF в spool-папку `/var/spool/urovo329/`
3. Launchd daemon обнаруживает файл и запускает helper
4. Helper растеризует PDF через Ghostscript (203 DPI, монохром)
5. Конвертирует растр в TSPL2 BITMAP команду
6. Отправляет на принтер через USB чанками по 64 байта (требование прошивки K329)

## Требования

- macOS (Apple Silicon или Intel)
- [Homebrew](https://brew.sh)
- Ghostscript: `brew install ghostscript`
- libusb: `brew install libusb`
- Python 3 (встроен в macOS)
- pyusb: устанавливается автоматически при установке драйвера

## Установка

### Одной командой (без скачивания репозитория)

```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/urovo_k329/main/install-remote.sh | bash
```

### Из репозитория

```bash
git clone https://github.com/unger1984/urovo_k329.git
cd urovo/driver
./install.sh
```

Скрипт:
- Проверит и установит зависимости (pyusb)
- Скопирует backend, фильтр, helper, PPD
- Настроит launchd daemon
- Добавит принтер в CUPS

После установки принтер **Urovo_K329** появится в системных настройках.

## Удаление

```bash
# Локально
./uninstall.sh

# Удалённо
curl -fsSL https://raw.githubusercontent.com/unger1984/urovo_k329/main/uninstall-remote.sh | bash
```

Полностью удаляет все компоненты драйвера.

## Печать

Печатайте из любого приложения через стандартный диалог печати, выбрав принтер **Urovo_K329**.

### Поддерживаемые размеры этикеток

| Размер       | PPD имя    |
|-------------|------------|
| 40 × 30 мм  | w113h85    |
| 50 × 40 мм  | w142h113   |
| 55 × 39 мм  | w156h110 (по умолчанию) |
| 58 × 40 мм  | w164h113   |
| 60 × 40 мм  | w170h113   |
| 80 × 50 мм  | w227h142   |
| 80 × 60 мм  | w227h170   |
| Произвольный | Custom     |

### Печать из командной строки

```bash
# Через CUPS
lp -d Urovo_K329 file.pdf

# Напрямую (минуя CUPS)
urovo-print-helper file.pdf [copies]
```

## Настройка принтера

Принтер должен быть в режиме **TSPL** (переключается в меню принтера: Settings → Command → TSPL).

### Калибровка области печати

Параметры области печати задаются в файле `/usr/local/bin/urovo-print-helper`:

```python
WIDTH = 420      # ширина в точках (203 DPI, ~52 мм)
HEIGHT = 260     # высота в точках (~32 мм)
Y_OFFSET = 16    # отступ сверху в точках (~2 мм)
```

Подберите значения под ваши этикетки.

## Структура проекта

```
driver/
├── install.sh              — установщик
├── uninstall.sh            — деинсталлятор
├── urovo-k329              — CUPS фильтр (передаёт PDF в backend)
├── urovo-k329-backend      — CUPS backend (spool + ожидание helper)
├── urovo-print-helper      — конвертация PDF→TSPL2 и отправка на USB
├── Urovo-K329.ppd          — описание принтера для CUPS
└── com.urovo.k329.printer.plist — launchd daemon (следит за spool)
```

## Решение проблем

### Принтер не печатает
1. Проверьте что принтер в режиме TSPL
2. Переподключите USB кабель
3. Посмотрите лог: `cat /tmp/urovo-print-helper.log`
4. Посмотрите лог CUPS: `tail -50 /var/log/cups/error_log | grep urovo`

### Задание висит в очереди
```bash
sudo cupsenable Urovo_K329
```

### Переустановка
```bash
./uninstall.sh && ./install.sh
```

## Технические детали

- **Протокол**: TSPL2 (команда `BITMAP x,y,width_bytes,height,mode,data`)
- **Подключение**: USB (VID=0x1fc9, PID=0x009b, CODEK PRINTER)
- **Передача**: чанки по 64 байта с паузой 50мс каждые 1024 байта
- **Растеризация**: Ghostscript, 203 DPI, монохромный PBM
- **DPI принтера**: 203 (8 точек/мм)
