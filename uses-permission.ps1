<#
.SYNOPSIS
    Анализатор пермишенов Android APK файлов.

.DESCRIPTION
    Разбирает APK с помощью apktool, извлекает uses-permission из AndroidManifest.xml
    и отображает их в удобном формате с проверкой на нежелательные пермишены.

.PARAMETER ApkPath
    Путь к APK файлу.

.PARAMETER NoColor
    Отключить цветной вывод.

.PARAMETER ShowUnwanted
    Показать только нежелательные пермишены.

.EXAMPLE
    .\uses-permission.ps1 C:\path\to\app.apk
    .\uses-permission.ps1 C:\path\to\app.apk -ShowUnwanted
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateScript({
        if (-not (Test-Path $_ -PathType Leaf)) {
            throw "Файл '$_' не найден."
        }
        $true
    })]
    [string]$ApkPath,

    [switch]$NoColor,
    [switch]$ShowUnwanted
)

# --- Configuration ---
$ErrorActionPreference = "Stop"

$Colors = @{
    Green  = if ($NoColor) { "" } else { "`e[0;32m" }
    Yellow = if ($NoColor) { "" } else { "`e[1;33m" }
    Red    = if ($NoColor) { "" } else { "`e[0;31m" }
    Cyan   = if ($NoColor) { "" } else { "`e[0;36m" }
    NC     = if ($NoColor) { "" } else { "`e[0m" }
}

# --- Unwanted Permissions ---
$UnwantedPermissions = @(
    "android.permission.ACCESS_FINE_LOCATION"
    "android.permission.REQUEST_INSTALL_PACKAGES"
    "android.permission.QUERY_ALL_PACKAGES"
)

# --- Permission Categories ---
$PermissionCategories = @{
    "Location"       = @("*LOCATION*")
    "Camera"         = @("*CAMERA*")
    "Microphone"     = @("*RECORD_AUDIO*", "*MICROPHONE*")
    "Storage"        = @("*STORAGE*", "*READ_EXTERNAL*", "*WRITE_EXTERNAL*", "*MANAGE_EXTERNAL*")
    "Phone"          = @("*READ_PHONE*", "*CALL_PHONE*", "*ANSWER_PHONE*", "*PROCESS_OUTGOING*")
    "Contacts"       = @("*READ_CONTACTS*", "*WRITE_CONTACTS*", "*GET_ACCOUNTS*")
    "Calendar"       = @("*READ_CALENDAR*", "*WRITE_CALENDAR*")
    "SMS"            = @("*READ_SMS*", "*SEND_SMS*", "*RECEIVE_SMS*")
    "Network"        = @("*INTERNET*", "*ACCESS_NETWORK*", "*ACCESS_WIFI*", "*CHANGE_WIFI*")
    "Bluetooth"      = @("*BLUETOOTH*")
    "Biometric"      = @("*BIOMETRIC*", "*FINGERPRINT*")
    "Notifications"  = @("*NOTIFICATION*")
    "System"         = @("*SYSTEM_ALERT*", "*WRITE_SETTINGS*", "*READ_LOGS*", "*DUMP*")
    "Install Apps"   = @("*INSTALL_PACKAGES*", "*REQUEST_INSTALL*")
    "Query Packages" = @("*QUERY_ALL_PACKAGES*", "*QUERY_*")
}

$TempDir = $null

# --- Functions ---

function Write-Color {
    param(
        [string]$Text,
        [string]$Color = "NC"
    )
    Write-Host "$($Colors[$Color])$Text$($Colors['NC'])" -NoNewline
}

function Write-ColorLine {
    param(
        [string]$Text,
        [string]$Color = "NC"
    )
    Write-Host "$($Colors[$Color])$Text$($Colors['NC'])"
}

function Get-PermissionCategory {
    param([string]$Permission)

    foreach ($category in $PermissionCategories.GetEnumerator()) {
        foreach ($pattern in $category.Value) {
            if ($Permission -like $pattern) {
                return $category.Key
            }
        }
    }
    return "Other"
}

function Test-UnwantedPermission {
    param([string]$Permission)
    return $Permission -in $UnwantedPermissions
}

# --- Cleanup ---
function Stop-Cleanup {
    if ($TempDir -and (Test-Path $TempDir -PathType Container)) {
        Write-ColorLine "`n  Очистка временных файлов..." "Green"
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Register cleanup on exit
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Stop-Cleanup }

# --- Main Script ---

# Check for apktool
$apktool = Get-Command apktool -ErrorAction SilentlyContinue
if (-not $apktool) {
    Write-ColorLine "  Ошибка: apktool не найден." "Red"
    Write-ColorLine "  Пожалуйста, установите его и убедитесь, что он доступен в PATH." "Yellow"
    exit 1
}

$ApkFileName = Split-Path $ApkPath -Leaf

Write-ColorLine "  Запуск анализа приложения: $ApkFileName" "Green"
Write-ColorLine "  ======================================" "Yellow"
Write-Host ""

# Create temp directory
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("apk_analysis_" + [System.Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -Path $TempDir -ItemType Directory -Force | Out-Null

# Decompile APK
Write-ColorLine "  Разбор приложения..." "Green"
try {
    $outputDir = Join-Path $TempDir "output"
    & apktool d -f $ApkPath -o $outputDir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Не удалось разобрать APK."
    }
}
catch {
    Write-ColorLine "  Ошибка: Не удалось разобрать APK. Проверьте файл и установку apktool." "Red"
    Stop-Cleanup
    exit 1
}

# Read manifest
$ManifestFile = Join-Path $outputDir "AndroidManifest.xml"
if (-not (Test-Path $ManifestFile -PathType Leaf)) {
    Write-ColorLine "  Ошибка: AndroidManifest.xml не найден." "Red"
    Stop-Cleanup
    exit 1
}

# Extract permissions
$ManifestContent = Get-Content $ManifestFile -Raw
$PermissionPattern = 'uses-permission android:name="([^"]+)"'
$AllPermissions = [regex]::Matches($ManifestContent, $PermissionPattern) |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique

if ($AllPermissions.Count -eq 0) {
    Write-ColorLine "  Пермишены не найдены." "Yellow"
    Stop-Cleanup
    exit 0
}

# --- Display Permissions ---

if (-not $ShowUnwanted) {
    Write-ColorLine "  Пермишены приложения: ($($AllPermissions.Count) шт.)" "Green"
    Write-ColorLine "  --------------------------------------" "Yellow"
    Write-Host ""

    # Group by category
    $Grouped = $AllPermissions | Group-Object { Get-PermissionCategory $_ } | Sort-Object Name

    foreach ($group in $Grouped) {
        $categoryName = $group.Name
        $count = $group.Count

        Write-ColorLine "  [$categoryName] ($count)" "Cyan"
        foreach ($perm in $group.Group) {
            $isUnwanted = Test-UnwantedPermission $perm
            $color = if ($isUnwanted) { "Red" } else { "NC" }
            $marker = if ($isUnwanted) { " !!" } else { "  -" }
            Write-ColorLine "    $marker $perm" $color
        }
        Write-Host ""
    }

    Write-ColorLine "  --------------------------------------" "Yellow"
}

# --- Check Unwanted Permissions ---

Write-ColorLine "  Проверка на нежелательные пермишены..." "Green"
Write-Host ""

$FoundUnwanted = @()
foreach ($perm in $UnwantedPermissions) {
    if ($perm -in $AllPermissions) {
        $FoundUnwanted += $perm
    }
}

if ($FoundUnwanted.Count -gt 0) {
    Write-ColorLine "  Найдены нежелательные пермишены: ($($FoundUnwanted.Count))" "Red"
    foreach ($perm in $FoundUnwanted) {
        Write-ColorLine "    !! $perm" "Red"
    }
    Write-ColorLine "  --------------------------------------" "Yellow"
}
else {
    Write-ColorLine "  Нежелательные пермишены не найдены." "Green"
}

Write-Host ""
Write-ColorLine "  Готово!" "Green"

# Cleanup
Stop-Cleanup
