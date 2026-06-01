import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { calendarToday } from "../_shared/calendar.ts";
import { incrementStreak } from "../_shared/streak.ts";

export type ProcessAnchorCompleteInput = {
  anchor_id: string;
};

export function parseProcessAnchorCompleteBody(raw: unknown):
  | { ok: true; value: ProcessAnchorCompleteInput }
  | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") {
    return { ok: false, error: "Body must be a JSON object" };
  }
  const o = raw as Record<string, unknown>;
  const anchorId = o.anchor_id ?? o.anchorId;
  if (typeof anchorId !== "string" || !anchorId.trim()) {
    return { ok: false, error: "anchor_id is required" };
  }
  return { ok: true, value: { anchor_id: anchorId.trim() } };
}

export async function processAnchorComplete(
  userSb: SupabaseClient,
  serviceSb: SupabaseClient,
  userId: string,
  input: ProcessAnchorCompleteInput,
): Promise<{ success: boolean; streak_incremented: boolean; message?: string }> {
  const { data: anchor, error: anchorErr } = await userSb
    .from("daily_anchors")
    .select("id,user_id,anchor_text,completed")
    .eq("id", input.anchor_id)
    .eq("user_id", userId)
    .maybeSingle();

  if (anchorErr) {
    return { success: false, streak_incremented: false, message: anchorErr.message };
  }
  if (!anchor) {
    return { success: false, streak_incremented: false, message: "Anchor not found" };
  }

  const row = anchor as { id: string; completed: boolean; anchor_text: string };

  if (!row.completed) {
    const { error: upErr } = await userSb
      .from("daily_anchors")
      .update({ completed: true, completed_at: new Date().toISOString() })
      .eq("id", input.anchor_id)
      .eq("user_id", userId);
    if (upErr) {
      return { success: false, streak_incremented: false, message: upErr.message };
    }
  }

  const { data: profile, error: profileErr } = await userSb
    .from("users")
    .select("timezone")
    .eq("id", userId)
    .maybeSingle();

  if (profileErr) {
    return { success: false, streak_incremented: false, message: profileErr.message };
  }

  const tz = (profile as { timezone?: string } | null)?.timezone ?? "UTC";
  const today = calendarToday(new Date(), tz);

  const { incremented } = await incrementStreak(serviceSb, userId, today, "anchor");

  return { success: true, streak_incremented: incremented };
}
