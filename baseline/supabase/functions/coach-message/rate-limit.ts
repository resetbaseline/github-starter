import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { calendarToday, startOfCalendarDayUtcIso } from "../_shared/calendar.ts";

/**
 * Free users: max 3 distinct `session_id` values in `coach_messages` since local midnight.
 * Pro users: unlimited (`sessions_remaining` null).
 */
export async function rateLimitState(
  sb: SupabaseClient,
  userId: string,
  timeZone: string,
  sessionId: string,
  pro: boolean,
  now: Date = new Date(),
): Promise<
  | { ok: true; sessions_remaining: number | null }
  | { ok: false; code: "rate_limit_exceeded"; sessions_remaining: 0 }
> {
  if (pro) {
    return { ok: true, sessions_remaining: null };
  }

  const today = calendarToday(now, timeZone);
  const startIso = startOfCalendarDayUtcIso(today, timeZone);

  const { data, error } = await sb
    .from("coach_messages")
    .select("session_id")
    .eq("user_id", userId)
    .gte("created_at", startIso);

  if (error) {
    throw new Error(`rate_limit query: ${error.message}`);
  }

  const distinct = new Set((data ?? []).map((r: { session_id: string }) => r.session_id));
  const already = distinct.has(sessionId);
  const count = distinct.size;

  if (!already && count >= 3) {
    return { ok: false, code: "rate_limit_exceeded", sessions_remaining: 0 };
  }

  const afterDistinct = already ? count : count + 1;
  const sessions_remaining = Math.max(0, 3 - afterDistinct);
  return { ok: true, sessions_remaining };
}
