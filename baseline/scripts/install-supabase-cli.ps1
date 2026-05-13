# Installs Supabase CLI binary into baseline/tools/supabase-cli/supabase.exe (not committed).
# Run from repo root or anywhere: powershell -ExecutionPolicy Bypass -File baseline/scripts/install-supabase-cli.ps1

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$destDir = Join-Path $root "tools\supabase-cli"
$version = "v2.98.2"
$asset = "supabase_windows_amd64.tar.gz"
$url = "https://github.com/supabase/cli/releases/download/$version/$asset"
$tmp = Join-Path $env:TEMP $asset

New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Write-Host "Downloading $url ..."
Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
Write-Host "Extracting to $destDir ..."
tar -xzf $tmp -C $destDir
$exe = Join-Path $destDir "supabase.exe"
if (-not (Test-Path $exe)) {
    throw "supabase.exe not found after extract. Check release layout for $version."
}
& $exe --version
Write-Host "Done. Add to PATH for this session:"
Write-Host "  `$env:Path = `"$destDir;`" + `$env:Path"
