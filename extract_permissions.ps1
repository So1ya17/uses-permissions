param(
    [Parameter(Position=0)]
    [string]$Path = "."
)

# Resolve .app directory or direct plist path
if (Test-Path $Path -PathType Container) {
    $PlistPath = Join-Path $Path "Info.plist"
} elseif ($Path -match '\.plist$' -and (Test-Path $Path -PathType Leaf)) {
    $PlistPath = $Path
} else {
    # Try treating as .app directory path even if Test-Path failed on container
    $candidate = Join-Path $Path "Info.plist"
    if (Test-Path $candidate -PathType Leaf) {
        $PlistPath = $candidate
    } else {
        Write-Error "Info.plist not found in '$Path'. Provide a path to a .app directory or an Info.plist file."
        exit 1
    }
}

if (-not (Test-Path $PlistPath -PathType Leaf)) {
    Write-Error "File not found: $PlistPath"
    exit 1
}

$fullPath = Resolve-Path $PlistPath

# Check if binary plist
$bytes = [System.IO.File]::ReadAllBytes($fullPath)
$header = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 6)

if ($header -eq "bplist") {
    # Convert binary plist to XML using Python
    $tempXml = [System.IO.Path]::GetTempFileName() + ".plist"
    $pythonScript = @"
import plistlib, sys
with open(sys.argv[1], 'rb') as f:
    data = plistlib.load(f)
with open(sys.argv[2], 'wb') as f:
    plistlib.dump(data, f, fmt=plistlib.FMT_XML)
"@
    $pyTempScript = [System.IO.Path]::GetTempFileName() + ".py"
    Set-Content -Path $pyTempScript -Value $pythonScript -Encoding UTF8

    $result = & python $pyTempScript $fullPath $tempXml 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to convert binary plist: $result"
        Remove-Item $pyTempScript -Force -ErrorAction SilentlyContinue
        exit 1
    }

    Remove-Item $pyTempScript -Force -ErrorAction SilentlyContinue
    [xml]$plist = Get-Content -Path $tempXml -Raw -Encoding UTF8
    Remove-Item $tempXml -Force -ErrorAction SilentlyContinue
} else {
    [xml]$plist = Get-Content -Path $fullPath -Raw
}

$dict = $plist.plist.dict

$keys = @()
$values = @()

foreach ($child in $dict.ChildNodes) {
    if ($child.Name -eq 'key') {
        $keys += $child.InnerText
    } else {
        if ($child.Name -eq 'true') {
            $values += 'true'
        } elseif ($child.Name -eq 'false') {
            $values += 'false'
        } elseif ($child.Name -eq 'array') {
            $items = @()
            foreach ($item in $child.ChildNodes) {
                $items += $item.InnerText
            }
            $values += ($items -join ', ')
        } else {
            $values += $child.InnerText
        }
    }
}

$permissionKeys = @(
    'NSCameraUsageDescription',
    'NSMicrophoneUsageDescription',
    'NSPhotoLibraryUsageDescription',
    'NSPhotoLibraryAddUsageDescription',
    'NSLocationWhenInUseUsageDescription',
    'NSLocationAlwaysAndWhenInUseUsageDescription',
    'NSLocationAlwaysUsageDescription',
    'NSContactsUsageDescription',
    'NSCalendarsUsageDescription',
    'NSRemindersUsageDescription',
    'NSBluetoothAlwaysUsageDescription',
    'NSBluetoothPeripheralUsageDescription',
    'NSMotionUsageDescription',
    'NSSpeechRecognitionUsageDescription',
    'NSAppleMusicUsageDescription',
    'NSMediaLibraryUsageDescription',
    'NSHealthShareUsageDescription',
    'NSHealthUpdateUsageDescription',
    'NSHomeKitUsageDescription',
    'NFCReaderUsageDescription',
    'NSFaceIDUsageDescription',
    'NSUserTrackingUsageDescription',
    'NSLocalNetworkUsageDescription',
    'NSNearbyInteractionUsageDescription',
    'NSSensorKitUsageDescription',
    'NSVideoSubscriberAccountUsageDescription',
    'NSGKFriendListUsageDescription',
    'ITSAppUsesNonExemptEncryption'
)

$results = @()

for ($i = 0; $i -lt $keys.Count; $i++) {
    foreach ($permKey in $permissionKeys) {
        if ($keys[$i] -eq $permKey) {
            $results += [PSCustomObject]@{
                Permission = $keys[$i]
                Value      = $values[$i]
            }
        }
    }
}

if ($results.Count -eq 0) {
    Write-Host "No permissions found in $PlistPath"
} else {
    Write-Host ""
    Write-Host "Permissions found in: $PlistPath" -ForegroundColor Cyan
    Write-Host ("=" * 80)
    $results | Format-Table -AutoSize -Wrap
}
