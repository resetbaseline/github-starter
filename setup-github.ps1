# Run from this folder: powershell -ExecutionPolicy Bypass -File .\setup-github.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed or not on PATH. Install from https://git-scm.com/download/win"
}

if (-not (Test-Path .git)) {
    git init
}
git add .
$status = git status --porcelain
if ($status) {
    git commit -m "Initial commit"
} else {
    Write-Host "Nothing to commit (already clean)."
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh auth status 2>$null
    if ($LASTEXITCODE -eq 0) {
        $name = "github-starter"
        gh repo create $name --private --source=. --remote=origin --push 2>$null
        if ($LASTEXITCODE -ne 0) {
            $name = "github-starter-local"
            Write-Host "Retrying as $name ..."
            gh repo create $name --private --source=. --remote=origin --push
        }
        git remote -v
        exit 0
    }
}

Write-Host @"

GitHub CLI (gh) is not installed or not logged in.

1. Create an empty repo on https://github.com/new (no README if you already committed).
2. Then run (replace USER and REPO):

   git remote add origin https://github.com/USER/REPO.git
   git branch -M main
   git push -u origin main

Or install GitHub CLI: https://cli.github.com/
   winget install GitHub.cli
   gh auth login

"@
