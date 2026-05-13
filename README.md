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

## C1 — schema, shared utilities, verify

1. **Apply migration** (linked project):

   ```powershell
   cd C:\Users\dowb\Projects\github-starter\baseline
   supabase db push
   ```

   Or paste [`baseline/supabase/migrations/001_initial_schema.sql`](baseline/supabase/migrations/001_initial_schema.sql) into **SQL Editor** and run once on a fresh project.

2. **SQL checks**: open and run [`baseline/supabase/C1_VERIFICATION.sql`](baseline/supabase/C1_VERIFICATION.sql) — expect **20** public tables, **8** `reflection_questions` rows, `universal=3`, `won=2`, `lost=3`, and RLS enabled on all tables.

3. **Shared Edge utilities** live in [`baseline/supabase/functions/_shared/`](baseline/supabase/functions/_shared/) (`cors.ts`, `supabase-client.ts`, `anthropic-client.ts`).

4. **Deno tests** (install [Deno](https://deno.land/) if needed):

   ```powershell
   cd C:\Users\dowb\Projects\github-starter\baseline\supabase\functions
   deno test --allow-env _shared\*.test.ts get-or-create-day\*.test.ts
   ```

## C2 — `get-or-create-day` Edge Function

- **Source:** [`baseline/supabase/functions/get-or-create-day/`](baseline/supabase/functions/get-or-create-day/) (`index.ts`, `handler.ts`, `dates.ts`).
- **Behavior:** `GET` or `POST` with `Authorization: Bearer <access_token>`. Returns `{ data: { day, goals, timers, yesterday_intention }, error }`. Uses `users.timezone` for “today” / “yesterday”; creates today’s `days` row if missing (handles unique race).
- **Local serve** (from `baseline/`, with `.env.local` or exported env):

  ```powershell
  supabase functions serve get-or-create-day --no-verify-jwt
  ```

  Omit `--no-verify-jwt` when you pass a real JWT and have JWT verification enabled.

- **Invoke (example):**

  ```powershell
  curl -i -H "Authorization: Bearer YOUR_ACCESS_TOKEN" http://127.0.0.1:54321/functions/v1/get-or-create-day
  ```

- **Deploy:** `supabase functions deploy get-or-create-day`

- **Dashboard:** Project → Edge Functions → confirm `get-or-create-day` listed; logs show requests. Set secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY` (and others) as needed for your project defaults.

## C3 — `process-checkin` Edge Function

- **Source:** [`baseline/supabase/functions/process-checkin/`](baseline/supabase/functions/process-checkin/).
- **Method:** `POST` only (`OPTIONS` preflight). Body (JSON):

  - `day_id` (uuid)
  - `goal_outcomes`: `{ goal_id, completed }[]` (must include every goal for that day)
  - `reflection_answers`: `{ question_text, answer, category }[]`
  - `tomorrow_intention`: string or `null`
  - `tomorrow_timeblocks`: `{ title, start_time, end_time, color_hex }[]` (`HH:MM` or `HH:MM:SS`)
  - `streak_freeze_used`: boolean

- **Behavior:** Validates coverage, classifies `won` / `lost` / `skipped`, updates `goals` + `days`, inserts `check_ins`, applies streak / freeze / perfect-day rules via **service role**, upserts **tomorrow’s** `days` row, inserts `time_blocks` for tomorrow, then fire-and-forgets `generate-coach-checkin-note` and `update-coach-memory` (ignored if those functions are not deployed yet).

- **Secrets:** Edge runtime must have `SUPABASE_SERVICE_ROLE_KEY` (Dashboard → Edge Functions → Secrets) because this function uses `createServiceClient()`.

- **Local serve:**

  ```powershell
  cd C:\Users\dowb\Projects\github-starter\baseline
  supabase functions serve process-checkin --no-verify-jwt
  ```

- **Invoke (example):**

  ```powershell
  curl -s -X POST -H "Authorization: Bearer YOUR_ACCESS_TOKEN" -H "Content-Type: application/json" `
    -d "{\"day_id\":\"...\",\"goal_outcomes\":[],\"reflection_answers\":[],\"tomorrow_intention\":null,\"tomorrow_timeblocks\":[],\"streak_freeze_used\":false}" `
    http://127.0.0.1:54321/functions/v1/process-checkin
  ```

- **Tests:** `deno test --allow-env baseline/supabase/functions/process-checkin/logic.test.ts`

- **Deploy:** `supabase functions deploy process-checkin`

## Git remote

```bash
git remote add origin https://github.com/resetbaseline/github-starter.git
git branch -M main
git push -u origin main
```
