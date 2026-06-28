#!/bin/bash

# --- Configuration ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Functions ---

# Function to print error messages and exit
die() {
    echo -e "${RED}❌ Ошибка: $1${NC}" >&2
    exit 1
}

# Cleanup function to be called on exit
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo -e "\n${GREEN}🧹 Очистка временных файлов...${NC}"
        rm -rf "$TEMP_DIR"
    fi
}

# --- Main Script ---

# Set trap to call cleanup function on script exit (normal, Ctrl+C, or error)
trap cleanup EXIT

# Check for dependencies
if ! command -v apktool &> /dev/null; then
    die "apktool не найден. Пожалуйста, установите его и убедитесь, что он доступен в PATH."
fi

# Check for input file
APK_FILE="$1"
if [ -z "$APK_FILE" ]; then
    echo -e "${YELLOW}Использование: $0 /путь/к/вашему/app.apk${NC}"
    exit 1
fi

if [ ! -f "$APK_FILE" ]; then
    die "Файл '$APK_FILE' не найден."
fi

echo -e "${GREEN}🚀 Запуск скрипта для разбора приложения: ${YELLOW}$(basename "$APK_FILE")${NC}"
echo -e "${YELLOW}==============================================${NC}\n"

# Create a temporary directory for decompilation
TEMP_DIR=$(mktemp -d)

echo -e "${GREEN}⚒️ Разбираем приложение во временную директорию...${NC}"
if ! apktool d -f "$APK_FILE" -o "$TEMP_DIR/output" > /dev/null; then
    die "Не удалось разобрать APK. Проверьте файл и установку apktool."
fi

MANIFEST_FILE="$TEMP_DIR/output/AndroidManifest.xml"

if [ ! -f "$MANIFEST_FILE" ]; then
    die "AndroidManifest.xml не найден в разобранном приложении."
fi

echo -e "\n${GREEN}📋 Пермишены приложения:${NC}"
echo -e "${YELLOW}--------------------------------------${NC}"
# Using grep with Perl-compatible regex for cleaner extraction
grep -oP 'uses-permission android:name="\K[^"]+' "$MANIFEST_FILE" | sort | while read -r permission; do
  echo -e "  ${CYAN}- $permission${NC}"
done
echo -e "${YELLOW}--------------------------------------${NC}"

# --- Проверка на нежелательные пермишены ---

UNWANTED_PERMISSIONS=(
    "android.permission.ACCESS_FINE_LOCATION"
    "android.permission.REQUEST_INSTALL_PACKAGES"
    "android.permission.QUERY_ALL_PACKAGES"
)

echo -e "\n${GREEN}🔍 Проверка на нежелательные пермишены...${NC}"

FOUND_UNWANTED=()

for perm in "${UNWANTED_PERMISSIONS[@]}"; do
    if grep -q "android:name=\"$perm\"" "$MANIFEST_FILE"; then
        FOUND_UNWANTED+=("$perm")
    fi
done

if [ ${#FOUND_UNWANTED[@]} -gt 0 ]; then
    echo -e "${RED}🚨 Найдены нежелательные пермишены:${NC}"
    for perm in "${FOUND_UNWANTED[@]}"; do
        echo -e "  ${YELLOW}- $perm${NC}"
    done
    echo -e "${YELLOW}--------------------------------------${NC}"
else
    echo -e "${GREEN}✅ Нежелательные пермишены не найдены. Отлично!${NC}"
fi


echo -e "\n${GREEN}✅ Готово!${NC}"