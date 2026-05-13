# github-starter

Baseline backend work lives under [`baseline/`](baseline/). Supabase CLI, migrations, and Edge Functions use **`baseline/supabase/`** only.

## Workflow (proposed)

1. Print component from Claude, copy it.
2. Paste into Cursor.
3. Wait for debug or comments; fix in Cursor. If something is unclear, send output to Haiku, then paste back.
4. Wait for commit.
5. Once committed, push to `main`.
6. Open Claude Chat (GitHub push history on `main`) and skim the latest pushes to understand the code.
7. If you need to reprompt, repeat the process; wait for the commit, then push to `main`.
8. Move on to the next component.

## Windows setup (before C1)

### 1) Supabase CLI

This repo vendors an install script (GitHub release tarball). From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\baseline\scripts\install-supabase-cli.ps1
```

Then:

```powershell
& ".\baseline\tools\supabase-cli\supabase.exe" --version
```

Alternatives when available on your machine: `winget install Supabase.Supabase`, or [Scoop](https://supabase.com/docs/guides/local-development/cli/getting-started).

Add `baseline\tools\supabase-cli` to your PATH if you want to run `supabase` without a full path.

### 2) Create the Supabase cloud project

1. Open [Supabase Dashboard](https://supabase.com/dashboard) and sign in.
2. **New project** — save the **database password** you set.
3. **Project Settings → API**: copy **Project URL** (`SUPABASE_URL`), **anon public** key, **service_role** key (secret).
4. **Project Settings → General**: copy **Reference ID** (used with `supabase link`).

### 3) Anthropic API key

1. Go to [Anthropic Console](https://console.anthropic.com/) → **API keys** → create a key (`ANTHROPIC_API_KEY`).

### 4) Initialize Supabase in this repo (already done)

The `baseline/supabase/` layout is created with `supabase init`. Work in:

```powershell
cd C:\Users\dowb\Projects\github-starter\baseline
```

### 5) Environment files

- [`baseline/.env.example`](baseline/.env.example) — committed template with comments.
- **`baseline/.env.local`** — copy from `.env.example`, fill in secrets; file is gitignored.

Production Edge Functions use **Dashboard → Project Settings → Edge Functions → Secrets**; `.env.local` is mainly for local `supabase functions serve`.

### 6) Link CLI to your project

```powershell
cd C:\Users\dowb\Projects\github-starter\baseline
& ".\tools\supabase-cli\supabase.exe" login
& ".\tools\supabase-cli\supabase.exe" link --project-ref YOUR_PROJECT_REF
```

Or from `baseline` if `supabase` is on PATH:

```powershell
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

Verify:

```powershell
powershell -ExecutionPolicy Bypass -File .\baseline\scripts\verify-supabase-link.ps1
```

You should see your project in `supabase projects list`.

### Next

When setup is finished, say **“setup done, build C1”** to add the full schema migration, shared Edge Function utilities, and verification SQL.

## Git remote

```bash
git remote add origin https://github.com/resetbaseline/github-starter.git
git branch -M main
git push -u origin main
```
