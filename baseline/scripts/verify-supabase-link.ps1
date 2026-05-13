# Verifies Supabase CLI login and linked project. Run from repo root.
# Prerequisites: install CLI (install-supabase-cli.ps1), then:
#   supabase login
#   supabase link --project-ref <YOUR_PROJECT_REF>

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$exe = Join-Path $root "tools\supabase-cli\supabase.exe"
if (-not (Test-Path $exe)) {
    throw "supabase.exe not found. Run baseline/scripts/install-supabase-cli.ps1 first."
}
Set-Location $root
Write-Host "Using: $exe"
& $exe projects list
Write-Host ""
Write-Host "If empty or error, run: supabase login"
Write-Host "Then from baseline/: supabase link --project-ref <ref from Dashboard -> General -> Reference ID>"
