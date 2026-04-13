# Manosphere Asset Downloader
# Opens download pages for all free CC0 asset packs in your browser.
# After downloading each ZIP, extract it to the listed folder.
# Usage: powershell -ExecutionPolicy Bypass -File tools/download_assets.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$dest = Join-Path $root "game\assets\third_party"

if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }

# Create all target directories
$dirs = @(
    "kenney/city-kit-roads", "kenney/city-kit-suburban", "kenney/city-kit-commercial",
    "kenney/city-kit-industrial", "kenney/car-kit", "kenney/furniture-kit",
    "kenney/ui-pack", "kenney/modular-buildings", "kenney/nature-kit",
    "quaternius/buildings", "quaternius/cars", "quaternius/nature",
    "quaternius/characters", "quaternius/animations", "quaternius/streets",
    "quaternius/farm", "quaternius/furniture", "quaternius/animated-woman", "quaternius/animated-man",
    "kaykit/city-builder", "kaykit/dungeon", "kaykit/characters",
    "textures/concrete", "textures/asphalt", "textures/brick",
    "textures/metal", "textures/gravel", "textures/grass"
)
foreach ($d in $dirs) {
    $p = Join-Path $dest $d
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

# Download textures directly (these have stable URLs)
function Download-Texture {
    param([string]$Name, [string]$Url, [string]$SubDir)
    $target = Join-Path $dest $SubDir
    $fileCount = (Get-ChildItem $target -Recurse -File -ErrorAction SilentlyContinue).Count
    if ($fileCount -gt 0) { Write-Host "[SKIP] $Name (already present)" -ForegroundColor DarkGray; return }
    $zip = Join-Path $env:TEMP "$($SubDir.Replace('/','-')).zip"
    Write-Host "[DOWN] $Name..." -ForegroundColor Cyan
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath $target -Force
        Remove-Item $zip -ErrorAction SilentlyContinue
        Write-Host "[OK]   $Name" -ForegroundColor Green
    } catch { Write-Host "[FAIL] $Name - download manually from $Url" -ForegroundColor Red }
}

Write-Host ""
Write-Host "=== Manosphere Asset Downloader ===" -ForegroundColor White
Write-Host "Target: $dest" -ForegroundColor DarkGray
Write-Host ""

# --- Auto-download textures (stable URLs) ---
Write-Host "--- Auto-downloading textures (ambientCG, CC0) ---" -ForegroundColor Yellow
Download-Texture "Concrete" "https://ambientcg.com/get?file=Concrete022_1K-JPG.zip" "textures/concrete"
Download-Texture "Asphalt"  "https://ambientcg.com/get?file=Asphalt004_1K-JPG.zip"  "textures/asphalt"
Download-Texture "Brick"    "https://ambientcg.com/get?file=Bricks059_1K-JPG.zip"   "textures/brick"
Download-Texture "Metal"    "https://ambientcg.com/get?file=Metal034_1K-JPG.zip"    "textures/metal"
Download-Texture "Gravel"   "https://ambientcg.com/get?file=Gravel023_1K-JPG.zip"   "textures/gravel"
Download-Texture "Grass"    "https://ambientcg.com/get?file=Grass004_1K-JPG.zip"    "textures/grass"

Write-Host ""
Write-Host "--- Opening asset pack pages in your browser ---" -ForegroundColor Yellow
Write-Host "Download each ZIP and extract to the folder shown." -ForegroundColor White
Write-Host ""

$packs = @(
    @{ Name="Kenney City Kit (Roads)";       Url="https://kenney.nl/assets/city-kit-roads";       Dir="kenney/city-kit-roads" },
    @{ Name="Kenney City Kit (Suburban)";     Url="https://kenney.nl/assets/city-kit-suburban";     Dir="kenney/city-kit-suburban" },
    @{ Name="Kenney City Kit (Commercial)";   Url="https://kenney.nl/assets/city-kit-commercial";   Dir="kenney/city-kit-commercial" },
    @{ Name="Kenney City Kit (Industrial)";   Url="https://kenney.nl/assets/city-kit-industrial";   Dir="kenney/city-kit-industrial" },
    @{ Name="Kenney Car Kit";                 Url="https://kenney.nl/assets/car-kit";               Dir="kenney/car-kit" },
    @{ Name="Kenney Furniture Kit";           Url="https://kenney.nl/assets/furniture-kit";         Dir="kenney/furniture-kit" },
    @{ Name="Kenney UI Pack";                 Url="https://kenney.nl/assets/ui-pack";               Dir="kenney/ui-pack" },
    @{ Name="Kenney Modular Buildings";       Url="https://kenney.nl/assets/modular-buildings";     Dir="kenney/modular-buildings" },
    @{ Name="Kenney Nature Kit";              Url="https://kenney.nl/assets/nature-kit";            Dir="kenney/nature-kit" },
    @{ Name="Quaternius Buildings";           Url="https://quaternius.com/packs/buildings.html";    Dir="quaternius/buildings" },
    @{ Name="Quaternius Cars";                Url="https://quaternius.com/packs/cars.html";         Dir="quaternius/cars" },
    @{ Name="Quaternius Nature";              Url="https://quaternius.com/packs/ultimatenature.html"; Dir="quaternius/nature" },
    @{ Name="Quaternius Base Characters";     Url="https://quaternius.itch.io/universal-base-characters"; Dir="quaternius/characters" },
    @{ Name="Quaternius Animation Library";   Url="https://quaternius.itch.io/universal-animation-library"; Dir="quaternius/animations" },
    @{ Name="Quaternius Modular Streets";     Url="https://quaternius.com/packs/modularstreet.html"; Dir="quaternius/streets" },
    @{ Name="Quaternius Farm Buildings";      Url="https://quaternius.com/packs/farmbuildings.html"; Dir="quaternius/farm" },
    @{ Name="Quaternius Furniture";           Url="https://quaternius.com/packs/furniturelibrary.html"; Dir="quaternius/furniture" },
    @{ Name="Quaternius Animated Woman";      Url="https://quaternius.com/packs/animatedwoman.html"; Dir="quaternius/animated-woman" },
    @{ Name="Quaternius Animated Characters"; Url="https://quaternius.com/packs/animatedcharacter.html"; Dir="quaternius/animated-man" },
    @{ Name="KayKit City Builder Bits";       Url="https://kaylousberg.itch.io/city-builder-bits";  Dir="kaykit/city-builder" },
    @{ Name="KayKit Dungeon Pack";            Url="https://kaylousberg.itch.io/kaykit-dungeon";     Dir="kaykit/dungeon" },
    @{ Name="KayKit Adventurers";             Url="https://kaylousberg.itch.io/kaykit-adventurers"; Dir="kaykit/characters" }
)

foreach ($pack in $packs) {
    $target = Join-Path $dest $pack.Dir
    $fileCount = (Get-ChildItem $target -Recurse -File -ErrorAction SilentlyContinue).Count
    if ($fileCount -gt 0) {
        Write-Host "[DONE] $($pack.Name) ($fileCount files)" -ForegroundColor DarkGray
        continue
    }
    Write-Host "[OPEN] $($pack.Name)" -ForegroundColor Cyan
    Write-Host "       Extract to: $target" -ForegroundColor White
    Start-Process $pack.Url
    Start-Sleep -Milliseconds 800
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Green
$totalFiles = (Get-ChildItem $dest -Recurse -File -ErrorAction SilentlyContinue).Count
$totalMB = [math]::Round(((Get-ChildItem $dest -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB), 1)
Write-Host "Current: $totalFiles files, ${totalMB}MB in third_party/" -ForegroundColor White
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Yellow
Write-Host "  1. On each page, click Download (or 'No thanks, take me to downloads')" -ForegroundColor White
Write-Host "  2. Download the ZIP file" -ForegroundColor White
Write-Host "  3. Extract into the folder shown next to each pack above" -ForegroundColor White
Write-Host "  4. Re-run this script to check progress (already-downloaded packs are skipped)" -ForegroundColor White
Write-Host ""
Write-Host "TIP: For Kenney, get the All-in-1 bundle (free): https://kenney.itch.io/kenney-game-assets" -ForegroundColor Cyan
Write-Host "     It contains ALL Kenney packs in one download." -ForegroundColor Cyan
