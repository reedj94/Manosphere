# Opens this project in the Godot editor without requiring `godot` on PATH.
# Usage (from repo root or game folder):
#   powershell -File game/run-godot.ps1
#   powershell -File game/run-godot.ps1 -- --path "$PWD"  # not needed; path is set automatically

$ErrorActionPreference = "Stop"
$gameRoot = $PSScriptRoot

function Find-GodotMonoExe {
	$root = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
	if (-not (Test-Path $root)) { return $null }
	# Prefer newest matching Mono Win64 editor binary
	Get-ChildItem -Path $root -Recurse -Filter "Godot_*_mono_win64.exe" -ErrorAction SilentlyContinue |
		Sort-Object FullName -Descending |
		Select-Object -First 1
}

$exe = $null
if ($env:GODOT_EXE -and (Test-Path $env:GODOT_EXE)) {
	$exe = Get-Item $env:GODOT_EXE
}
if (-not $exe) {
	$exe = Find-GodotMonoExe
}
if (-not $exe) {
	Write-Error @"
Could not find Godot Mono under:
  $env:LOCALAPPDATA\Microsoft\WinGet\Packages

Install or repair:
  winget install GodotEngine.GodotEngine.Mono

Or set GODOT_EXE to your Godot_v*_mono_win64.exe full path.
"@
	exit 1
}

Write-Host "Using: $($exe.FullName)"
& $exe.FullName --editor --path $gameRoot @args
