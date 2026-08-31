# Uses Permission Analyzer

![Android](https://img.shields.io/badge/Android-APK-blue)
![iOS](https://img.shields.io/badge/iOS-Plist-lightgrey?logo=apple)
![Bash](https://img.shields.io/badge/Bash-Script-green)
![PowerShell](https://img.shields.io/badge/PowerShell-Script-blue?logo=powershell)
![License](https://img.shields.io/badge/License-MIT-orange)

## Описание

Утилиты для анализа разрешений мобильных приложений. Поддерживаются Android APK-файлы и iOS .app-бандлы.

| Скрипт | Платформа | Назначение |
|--------|-----------|------------|
| `uses-permission.sh` | Linux / macOS | Анализ пермишенов Android APK |
| `uses-permission.ps1` | Windows | Анализ пермишенов Android APK |
| `extract_permissions.ps1` | Windows | Извлечение privacy-ключей из iOS Info.plist |

## Возможности

- **Декомпиляция APK** — автоматическая распаковка APK-файла с помощью `apktool`
- **Извлечение пермишенов** — парсинг `AndroidManifest.xml` для получения списка всех разрешений
- **Проверка безопасности** — обнаружение нежелательных пермишенов:
  - `ACCESS_FINE_LOCATION` — доступ к точной геолокации
  - `REQUEST_INSTALL_PACKAGES` — установка пакетов
  - `QUERY_ALL_PACKAGES` — запрос всех установленных приложений
- **Группировка по категориям** — пермишены сортируются по типу (Location, Camera, Storage и т.д.)
- **Цветной вывод** — наглядное отображение результатов с эмодзи

### iOS (extract_permissions.ps1)

- **Извлечение privacy-ключей** — парсинг `Info.plist` для поиска всех `NS*UsageDescription` ключей
- **Поддержка бинарных plist** — автоматическая конвертация через Python (`plistlib`)
- **Гибкий ввод** — принимает путь к `.app` директории или напрямую к `.plist` файлу
- **28 известных ключей** — камера, микрофон, геолокация, контакты, Bluetooth, Face ID, HealthKit, NFC и другие

## Требования

- **apktool** — должен быть доступен в `PATH` (только для Android-скриптов)
- **Python 3** — необходим для обработки бинарных plist (только для `extract_permissions.ps1`)

### Установка apktool

```bash
# Ubuntu/Debian
sudo apt install apktool

# macOS (Homebrew)
brew install apktool

# Arch Linux
sudo pacman -S apktool

# Windows (winget)
winget install iBotPeaches.Apktool
```

## Использование

### Bash (Linux/macOS)

```bash
# Сделать скрипт исполняемым
chmod +x uses-permission.sh

# Запуск
./uses-permission.sh /path/to/your/app.apk
```

### PowerShell (Windows)

```powershell
# Запуск
.\uses-permission.ps1 C:\path\to\your\app.apk

# Только нежелательные пермишены
.\uses-permission.ps1 C:\path\to\your\app.apk -ShowUnwanted

# Без цветного вывода
.\uses-permission.ps1 C:\path\to\your\app.apk -NoColor
```

### iOS — extract_permissions.ps1 (Windows)

```powershell
# Указать путь к .app директории (Info.plist найдётся автоматически)
.\extract_permissions.ps1 "C:\path\to\Runner.app"

# Указать путь напрямую к plist-файлу
.\extract_permissions.ps1 "C:\path\to\Info.plist"

# По умолчанию ищет Info.plist в текущей директории
.\extract_permissions.ps1
```

## Пример вывода

### Android

```
  Запуск анализа приложения: sample.apk
  ======================================

  Разбор приложения...

  Пермишены приложения: (4 шт.)
  --------------------------------------

  [Network] (2)
    - android.permission.INTERNET
    - android.permission.ACCESS_NETWORK_STATE

  [Camera] (1)
    - android.permission.CAMERA

  [Location] (1)
    !! android.permission.ACCESS_FINE_LOCATION

  --------------------------------------

  Проверка на нежелательные пермишены...

  Найдены нежелательные пермишены: (1)
    !! android.permission.ACCESS_FINE_LOCATION
  --------------------------------------

  Готово!
```

### iOS

```
Permissions found in: C:\path\to\Runner.app\Info.plist
================================================================================

Permission                     Value
----------                     -----
NSCameraUsageDescription       Используется для съёмки документов
NSFaceIDUsageDescription       Face ID используется для входа в приложение
NSMicrophoneUsageDescription   The application does not use this feature
NSUserTrackingUsageDescription Для персонализации рекламы
```

## Как это работает

### Android

1. **Проверка зависимостей** — убедиться, что `apktool` установлен
2. **Валидация** — проверить существование APK-файла
3. **Декомпиляция** — распаковать APK во временную директорию
4. **Парсинг** — извлечь все `uses-permission` из `AndroidManifest.xml`
5. **Анализ** — сверить найденные пермишены со списком нежелательных
6. **Очистка** — удалить временные файлы при завершении

### iOS

1. **Определение пути** — если указана директория `.app`, найти `Info.plist` внутри
2. **Определение формата** — проверить заголовок файла (`bplist` = бинарный)
3. **Конвертация** — если бинарный plist, сконвертировать в XML через Python
4. **Парсинг** — сопоставить ключи со списком известных privacy-ключей
5. **Вывод** — отобразить найденные ключи и их описания в таблице

## Примечания

- Временные файлы автоматически удаляются после завершения скрипта
- Скрипт корректно обрабатывает прерывание (Ctrl+C)
- Все ошибки выводятся на stderr с красным выделением

## Лицензия

MIT License
