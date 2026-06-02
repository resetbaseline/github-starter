import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { calendarToday } from "../_shared/calendar.ts";
import { incrementStreak } from "../_shared/streak.ts";

export type ProcessFocusCompleteInput = {
  duration_minutes: number;
  client_session_id?: string;
};

export function parseProcessFocusCompleteBody(raw: unknown):
  | { ok: true; value: ProcessFocusCompleteInput }
  | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") {
    return { ok: false, error: "Body must be a JSON object" };
  }
  const o = raw as Record<string, unknown>;
  const rawMinutes = o.duration_minutes ?? o.durationMinutes;
  const duration_minutes = typeof rawMinutes === "number"
    ? rawMinutes
    : typeof rawMinutes === "string"
    ? Number(rawMinutes)
    : NaN;
  if (!Number.isFinite(duration_minutes) || duration_minutes < 0) {
    return { ok: false, error: "duration_minutes must be a non-negative number" };
  }
  const rawSessionId = o.client_session_id ?? o.clientSessionId;
  const client_session_id = typeof rawSessionId === "string" && rawSessionId.length > 0
    ? rawSessionId
    : undefined;
  return { ok: true, value: { duration_minutes, client_session_id } };
}

export async function processFocusComplete(
  userSb: SupabaseClient,
  serviceSb: SupabaseClient,
  userId: string,
  input: ProcessFocusCompleteInput,
): Promise<{ success: boolean; streak_updated: boolean }> {
  if (input.duration_minutes < 10) {
    return { success: true, streak_updated: false };
  }

  const { data: profile, error: profileErr } = await userSb
    .from("users")
    .select("timezone")
    .eq("id", userId)
    .maybeSingle();

  if (profileErr) {
    throw new Error(profileErr.message);
  }

  const tz = (profile as { timezone?: string } | null)?.timezone ?? "UTC";
  const today = calendarToday(new Date(), tz);
  const completedAt = new Date().toISOString();

  const sessionRow: Record<string, unknown> = {
    user_id: userId,
    duration_minutes: Math.round(input.duration_minutes),
    completed_at: completedAt,
  };
  if (input.client_session_id) {
    sessionRow.client_session_id = input.client_session_id;
  }

  const { error: sessionErr } = await serviceSb.from("focus_sessions").insert(sessionRow);

  // 23505 = duplicate submission of the same client session; treat as a no-op insert.
  // The streak increment below is itself idempotent per calendar day.
  if (sessionErr && sessionErr.code !== "23505") {
    throw new Error(sessionErr.message);
  }

  const { incremented } = await incrementStreak(serviceSb, userId, today, "focus_session");

  return { success: true, streak_updated: incremented };
}
