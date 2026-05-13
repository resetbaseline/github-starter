import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

function requireEnv(name: string): string {
  const v = Deno.env.get(name);
  if (!v || v.trim() === "") {
    throw new Error(
      `Missing ${name}. For local dev, set it in baseline/.env.local and run supabase functions serve with env loaded. ` +
        `For production, add Edge Function secrets in Supabase Dashboard → Project Settings → Edge Functions → Secrets. ` +
        `API keys: Dashboard → Project Settings → API (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY).`,
    );
  }
  return v;
}

/** User-scoped client: respects RLS using the JWT from Authorization. */
export function createUserClient(req: Request): SupabaseClient {
  const supabaseUrl = requireEnv("SUPABASE_URL");
  const anonKey = requireEnv("SUPABASE_ANON_KEY");
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new Error(
      "Missing or invalid Authorization header. Expected: Authorization: Bearer <user_jwt> (Supabase access token).",
    );
  }
  return createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** Service role: bypasses RLS. Use only for trusted server-side writes. */
export function createServiceClient(): SupabaseClient {
  const supabaseUrl = requireEnv("SUPABASE_URL");
  const serviceKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
  return createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
