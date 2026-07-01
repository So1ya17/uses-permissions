# Uses Permission Analyzer

![Android](https://img.shields.io/badge/Android-APK-blue)
![Bash](https://img.shields.io/badge/Bash-Script-green)
![PowerShell](https://img.shields.io/badge/PowerShell-Script-blue?logo=powershell)
![License](https://img.shields.io/badge/License-MIT-orange)

## Описание

Утилита для анализа Android APK-файлов. Автоматически извлекает список разрешений из манифеста приложения и проверяет наличие потенциально нежелательных пермишенов.

| Скрипт | Платформа |
|--------|-----------|
| `uses-permission.sh` | Linux / macOS |
| `uses-permission.ps1` | Windows |

## Возможности

- **Декомпиляция APK** — автоматическая распаковка APK-файла с помощью `apktool`
- **Извлечение пермишенов** — парсинг `AndroidManifest.xml` для получения списка всех разрешений
- **Проверка безопасности** — обнаружение нежелательных пермишенов:
  - `ACCESS_FINE_LOCATION` — доступ к точной геолокации
  - `REQUEST_INSTALL_PACKAGES` — установка пакетов
  - `QUERY_ALL_PACKAGES` — запрос всех установленных приложений
- **Группировка по категориям** — пермишены сортируются по типу (Location, Camera, Storage и т.д.)
- **Цветной вывод** — наглядное отображение результатов с эмодзи

## Требования

- **apktool** — должен быть доступен в `PATH`

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

## Пример вывода

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

## Как это работает

1. **Проверка зависимостей** — убедиться, что `apktool` установлен
2. **Валидация** — проверить существование APK-файла
3. **Декомпиляция** — распаковать APK во временную директорию
4. **Парсинг** — извлечь все `uses-permission` из `AndroidManifest.xml`
5. **Анализ** — сверить найденные пермишены со списком нежелательных
6. **Очистка** — удалить временные файлы при завершении

## Примечания

- Временные файлы автоматически удаляются после завершения скрипта
- Скрипт корректно обрабатывает прерывание (Ctrl+C)
- Все ошибки выводятся на stderr с красным выделением

## Лицензия

MIT License
