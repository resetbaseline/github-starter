import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { addCalendarDays } from "../_shared/calendar.ts";
import type { ActionTaken } from "./types.ts";

const ACTION_SRC = "<action>\\s*([\\s\\S]*?)\\s*<\\/action>";

export function extractActionJsonBlocks(assistantText: string): unknown[] {
  const out: unknown[] = [];
  for (const m of assistantText.matchAll(new RegExp(ACTION_SRC, "gi"))) {
    const raw = m[1]?.trim() ?? "";
    if (!raw) continue;
    try {
      out.push(JSON.parse(raw));
    } catch {
      // skip invalid JSON
    }
  }
  return out;
}

/** Strip <action> blocks from assistant text for storage as user-visible response. */
export function stripActionTags(assistantText: string): string {
  return assistantText.replace(new RegExp(ACTION_SRC, "gi"), "").trim();
}

export async function executeCoachActions(
  sb: SupabaseClient,
  userId: string,
  dayId: string,
  dayCalendarDate: string,
  timeZone: string,
  blocks: unknown[],
): Promise<ActionTaken[]> {
  const results: ActionTaken[] = [];
  for (const block of blocks) {
    if (!block || typeof block !== "object") continue;
    const a = block as Record<string, unknown>;
    const type = typeof a.type === "string" ? a.type : "";
    const params = (a.params && typeof a.params === "object" ? a.params : {}) as Record<string, unknown>;

    if (type === "add_goal") {
      results.push(await actionAddGoal(sb, userId, dayId, params));
    } else if (type === "update_schedule") {
      results.push(await actionUpdateSchedule(sb, userId, params));
    } else if (type === "set_tomorrow_intention") {
      results.push(await actionSetTomorrowIntention(sb, userId, dayCalendarDate, timeZone, params));
    } else if (type === "start_focus_block") {
      results.push(await actionStartFocusBlock(sb, userId, dayId, params));
    } else if (type) {
      results.push({ type, ok: false, detail: "unknown_action_type" });
    }
  }
  return results;
}

async function actionAddGoal(
  sb: SupabaseClient,
  userId: string,
  dayId: string,
  p: Record<string, unknown>,
): Promise<ActionTaken> {
  const text = typeof p.text === "string" ? p.text.trim() : "";
  if (!text) return { type: "add_goal", ok: false, detail: "missing text" };

  const category = typeof p.category === "string" ? p.category : "work";
  const priority = typeof p.priority === "number" && Number.isFinite(p.priority) ? Math.trunc(p.priority) : 3;
  const is_non_negotiable = typeof p.is_non_negotiable === "boolean" ? p.is_non_negotiable : false;

  const { data: rows } = await sb.from("goals").select("order_index").eq("day_id", dayId).order("order_index", { ascending: false }).limit(1);
  const maxOrder = rows && rows.length > 0 ? Number((rows[0] as { order_index: number | null }).order_index ?? 0) : 0;
  const order_index = maxOrder + 1;

  const { error } = await sb.from("goals").insert({
    user_id: userId,
    day_id: dayId,
    text,
    category,
    priority,
    is_non_negotiable,
    order_index,
    source: "coach",
    status: "pending",
  });

  if (error) return { type: "add_goal", ok: false, detail: error.message };
  return { type: "add_goal", ok: true };
}

async function actionUpdateSchedule(
  sb: SupabaseClient,
  userId: string,
  p: Record<string, unknown>,
): Promise<ActionTaken> {
  const id = typeof p.id === "string" ? p.id : "";
  if (!id) return { type: "update_schedule", ok: false, detail: "missing id" };

  const patch: Record<string, unknown> = {};
  const keys = [
    "name",
    "start_time",
    "end_time",
    "days_active",
    "blocked_apps",
    "custom_message",
    "color_hex",
    "enabled",
    "is_default",
  ] as const;
  for (const k of keys) {
    if (k in p) patch[k] = p[k];
  }
  if (Object.keys(patch).length === 0) {
    return { type: "update_schedule", ok: false, detail: "no fields to update" };
  }

  const { error } = await sb.from("schedule_blocks").update(patch).eq("id", id).eq("user_id", userId);
  if (error) return { type: "update_schedule", ok: false, detail: error.message };
  return { type: "update_schedule", ok: true };
}

async function actionSetTomorrowIntention(
  sb: SupabaseClient,
  userId: string,
  dayCalendarDate: string,
  _timeZone: string,
  p: Record<string, unknown>,
): Promise<ActionTaken> {
  const intention = typeof p.intention === "string" ? p.intention : typeof p.tomorrow_intention === "string" ? p.tomorrow_intention : "";
  if (!intention.trim()) return { type: "set_tomorrow_intention", ok: false, detail: "missing intention" };

  const tomorrow = addCalendarDays(dayCalendarDate, 1);
  const { error } = await sb
    .from("days")
    .upsert(
      { user_id: userId, date: tomorrow, tomorrow_intention: intention.trim() },
      { onConflict: "user_id,date" },
    );
  if (error) return { type: "set_tomorrow_intention", ok: false, detail: error.message };
  return { type: "set_tomorrow_intention", ok: true };
}

async function actionStartFocusBlock(
  sb: SupabaseClient,
  userId: string,
  dayId: string,
  p: Record<string, unknown>,
): Promise<ActionTaken> {
  const duration = typeof p.duration_minutes === "number" ? Math.trunc(p.duration_minutes) : 25;
  const t = p.type === "freeform" ? "freeform" : "pomodoro";
  if (duration <= 0) return { type: "start_focus_block", ok: false, detail: "invalid duration_minutes" };

  const { error } = await sb.from("timers").insert({
    user_id: userId,
    day_id: dayId,
    type: t,
    duration_minutes: duration,
    hard_lock_active: true,
    status: "pending",
  });
  if (error) return { type: "start_focus_block", ok: false, detail: error.message };
  return { type: "start_focus_block", ok: true };
}
