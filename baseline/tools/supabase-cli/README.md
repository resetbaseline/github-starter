# Supabase CLI (Windows, amd64)

The `supabase.exe` binary is **not committed** (too large). Install it once:

```powershell
cd C:\Users\dowb\Projects\github-starter
powershell -ExecutionPolicy Bypass -File .\baseline\scripts\install-supabase-cli.ps1
```

Then either add `baseline\tools\supabase-cli` to your PATH, or invoke:

```powershell
& ".\baseline\tools\supabase-cli\supabase.exe" --version
```

Alternative installs: `winget install Supabase.Supabase` (when available) or [Scoop](https://supabase.com/docs/guides/local-development/cli/getting-started).
