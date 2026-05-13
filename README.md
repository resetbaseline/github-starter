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

- **Behavior:** Validates coverage, classifies `won` / `lost` / `skipped`, updates `goals` + `days`, inserts `check_ins`, applies streak / freeze / perfect-day rules via **service role**, upserts **tomorrow’s** `days` row, inserts `time_blocks` for tomorrow, then fire-and-forgets `generate-coach-checkin-note` and `update-coach-memory` with the **same `Authorization` header** as the check-in request so those functions run as the user (JWT).

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

## C4 — `gate-validate` Edge Function

- **Source:** [`baseline/supabase/functions/gate-validate/`](baseline/supabase/functions/gate-validate/).
- **Method:** `POST` + `OPTIONS`. Body:

  - `app_bundle_id`, `app_name`, `trigger_source`, `stated_reason` (string), `active_non_negotiable` (string or null)

- **Behavior:** Resolves **today** from `users.timezone`, loads/creates `days`, reads `streaks.current_count` and `days.gate_triggers` (pre-trigger count). If `trigger_source === "focus_block"`, grant is **0** and coach copy explains the block; otherwise **Haiku** classifies the reason (`specific_legitimate` | `plausible` | `vague` | `low_legitimacy`), applies base seconds + escalation tiers + historical mismatch penalty (ILIKE on first word, `usage_ratio > 0.8`), then **Haiku** coach reply (max 2 sentences; full coach voice rules in [`_shared/coach-voice.ts`](baseline/supabase/functions/_shared/coach-voice.ts)). Inserts `gate_triggers` (including `reason_classification` when not focus-block) and increments `days.gate_triggers` via **service role**. Requires migration **002** for `reason_classification`.

- **Secrets:** `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`, plus standard Supabase URL/keys.

- **Local serve:**

  ```powershell
  cd C:\Users\dowb\Projects\github-starter\baseline
  supabase functions serve gate-validate
  ```

- **Invoke (example):**

  ```powershell
  curl -s -X POST -H "Authorization: Bearer YOUR_ACCESS_TOKEN" -H "Content-Type: application/json" `
    -d "{\"app_bundle_id\":\"com.test.app\",\"app_name\":\"Test\",\"trigger_source\":\"gate\",\"stated_reason\":\"I need to reply to one email\",\"active_non_negotiable\":null}" `
    http://127.0.0.1:54321/functions/v1/gate-validate
  ```

- **Tests:** `deno test baseline/supabase/functions/gate-validate/grant.test.ts baseline/supabase/functions/gate-validate/parse.test.ts`

- **Deploy:** `supabase functions deploy gate-validate`

## C5 — `gate-resolve` Edge Function

- **Source:** [`baseline/supabase/functions/gate-resolve/`](baseline/supabase/functions/gate-resolve/).
- **Migration:** [`baseline/supabase/migrations/002_gate_trigger_reason_classification.sql`](baseline/supabase/migrations/002_gate_trigger_reason_classification.sql) adds `gate_triggers.reason_classification` (set by [`gate-validate`](baseline/supabase/functions/gate-validate/handler.ts) for mismatch logic). Run `supabase db push` (or apply SQL) before relying on `mismatch_flagged`.

- **Method:** `POST` + `OPTIONS`. Body:

  - `gate_trigger_id` (uuid)
  - `time_used_seconds` (number, ≥ 0)
  - `outcome`: `dismissed` | `timed_access` | `focus_block_active`

- **Behavior:** Loads the trigger with the **user JWT** (RLS). Rejects if missing or already `resolved_at`. Computes `usage_ratio` (`null` if `time_granted_seconds` is 0 to avoid divide-by-zero). **Service role** updates `gate_triggers` (`time_used_seconds`, `usage_ratio`, `resolved_at`, `outcome`, `mismatch_flagged`). Sets `mismatch_flagged` when `usage_ratio > 0.8` and `reason_classification` is `specific_legitimate` or `plausible`. If `outcome === dismissed`, increments `days.gate_dismissals` for the trigger’s `day_id`.

- **Response `data`:** `{ success: true, usage_ratio, mismatch_flagged }`.

- **Secrets:** `SUPABASE_SERVICE_ROLE_KEY` + standard Supabase URL/keys.

- **Local serve:** `supabase functions serve gate-resolve`

- **Tests:** `deno test baseline/supabase/functions/gate-resolve/logic.test.ts baseline/supabase/functions/gate-resolve/parse.test.ts`

- **Deploy:** `supabase functions deploy gate-resolve`

## C6 — `coach-message` Edge Function

- **Source:** [`baseline/supabase/functions/coach-message/`](baseline/supabase/functions/coach-message/).
- **Method:** `POST` + `OPTIONS`. Body: `{ session_type, message, session_id, day_id }` (`session_type` is `checkin` | `stuck` | `planning` | `freeform` | `insight` | `gate`; UUIDs for `session_id` and `day_id`).
- **Rate limit:** Free users (`users.pro = false`): max **3 distinct `session_id`** values in `coach_messages` per **calendar day** in `users.timezone`. Pro: unlimited (`sessions_remaining` is `null` on success).
- **Models:** `checkin` and `insight` → **Sonnet**; others → **Haiku**. System prompt order: coach voice → memory profile → journal (up to 14 uncompressed entries, chronological) → today’s context → session-type instructions.
- **Actions:** Parses `<action>...</action>` JSON after the model reply; supports `add_goal`, `update_schedule`, `set_tomorrow_intention`, `start_focus_block` (see [`actions.ts`](baseline/supabase/functions/coach-message/actions.ts)). Inserts **user** then **assistant** rows into `coach_messages`.
- **Secrets:** `ANTHROPIC_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` (no service role).
- **Serve:** `supabase functions serve coach-message`
- **Tests:** `deno test baseline/supabase/functions/coach-message/logic.test.ts`
- **Deploy:** `supabase functions deploy coach-message`

## C7 — `generate-coach-checkin-note` Edge Function

- **Source:** [`baseline/supabase/functions/generate-coach-checkin-note/`](baseline/supabase/functions/generate-coach-checkin-note/).
- **Method:** `POST` + `OPTIONS`. Body: `{ day_id, user_id? }` — optional `user_id` must match the JWT user when present.
- **Behavior:** Loads the **day** (full row), **goals** for that day, **gate_triggers** rows for gate-callout logic, **streak** `current_count`. Computes whether a **Gate callout** is warranted (`days.gate_triggers >= 5` or any same-day trigger with `usage_ratio > 0.8` and `reason_classification` in `plausible` / `specific_legitimate`). Builds a Haiku prompt (max 3 sentences; coach voice + concrete data). If `gate_dismissals > 0`, prompt asks to acknowledge wins; if heuristics suggest a rough day, adds one **tomorrow block** suggestion. **`callHaiku`** then **`days.coach_check_in_note`** is updated via **service role** (bypasses RLS while still scoping `eq` on `user_id`).
- **Secrets:** `ANTHROPIC_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`.
- **Internal calls:** [`process-checkin`](baseline/supabase/functions/process-checkin/handler.ts) forwards the caller’s `Authorization` header on `functions.invoke` so this function receives a valid user JWT.
- **Serve:** `supabase functions serve generate-coach-checkin-note`
- **Tests:** `deno test baseline/supabase/functions/generate-coach-checkin-note/logic.test.ts`
- **Deploy:** `supabase functions deploy generate-coach-checkin-note`

## C8 — `update-coach-memory` Edge Function

- **Source:** [`baseline/supabase/functions/update-coach-memory/`](baseline/supabase/functions/update-coach-memory/).
- **Method:** `POST` + `OPTIONS`. Body: `{ user_id, session_id }` (UUIDs). `user_id` must match the JWT subject.
- **Behavior:** Loads `coach_messages` for that `session_id` (ordered by `created_at`). If there are no rows, returns `{ success: true, skipped: true }` (useful when internal callers pass a correlation id that does not match chat `session_id`). Otherwise **Haiku** extracts structured facts (goals, struggles, wins, windows, notes, tone), **service role** merges into `coach_memory_profile` (including `goals_summary` JSON), updates matching **`user_goals.current_status`** when names align, **Haiku** writes a 3–5 sentence journal summary, **user JWT** inserts **`coach_session_journal`**. If there are more than **14** uncompressed journal rows older than **14 days**, groups them by calendar month and **Haiku** compresses each month; **service role** sets `compression_summary` and `compressed` on those rows (RLS has no journal `UPDATE` for users).
- **Secrets:** `ANTHROPIC_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`.
- **Internal calls:** [`process-checkin`](baseline/supabase/functions/process-checkin/handler.ts) invokes this with the caller’s `Authorization` header; for memory and journal updates to run, `session_id` should be the same UUID used in `coach_messages` for that chat (not necessarily the check-in id).
- **Serve:** `supabase functions serve update-coach-memory`
- **Tests:** `deno test baseline/supabase/functions/update-coach-memory/json-utils.test.ts`
- **Deploy:** `supabase functions deploy update-coach-memory`

## Git remote

```bash
git remote add origin https://github.com/resetbaseline/github-starter.git
git branch -M main
git push -u origin main
```
