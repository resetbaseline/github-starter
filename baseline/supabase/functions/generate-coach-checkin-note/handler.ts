import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callHaiku } from "../_shared/anthropic-client.ts";
import { COACH_VOICE_SYSTEM_PROMPT } from "../_shared/coach-voice.ts";
import { gateCalloutWarranted, tomorrowAdjustmentWarranted } from "./logic.ts";
import type { GenerateCheckinNoteError, GenerateCheckinNoteInput, GenerateCheckinNoteSuccess } from "./types.ts";

function buildUserPrompt(args: {
  day: Record<string, unknown>;
  goals: Record<string, unknown>[];
  streakCurrent: number;
  gateTriggersOnDay: number;
  gateDismissals: number;
  triggersDetail: Array<{ usage_ratio: number | null; reason_classification: string | null }>;
  gateCallout: boolean;
  acknowledgeDismissals: boolean;
  suggestTomorrowBlock: boolean;
}): string {
  const lines: string[] = [
    "Write the nightly coach check-in note for this user (max 3 sentences). Be concrete; use the numbers below.",
    "",
    "## Day row (JSON)",
    JSON.stringify(args.day, null, 2),
    "",
    "## Goals for this day (JSON array; include status and completed_at)",
    JSON.stringify(args.goals, null, 2),
    "",
    `## Aggregates\n- streak current_count: ${args.streakCurrent}\n- gate_triggers (count on day row): ${args.gateTriggersOnDay}\n- gate_dismissals: ${args.gateDismissals}`,
    "",
    "## Instructions",
    "- Tie sentences to this data; no generic filler.",
  ];

  if (args.gateCallout) {
    lines.push("- Include **one** sharp observation about Gate usage / triggers (not moralizing).");
  }
  if (args.acknowledgeDismissals) {
    lines.push("- Because gate_dismissals > 0, briefly acknowledge what they turned down or closed out (a win).");
  }
  if (args.suggestTomorrowBlock) {
    lines.push("- Include **one** specific suggestion for tomorrow (e.g. a time block, shorter first goal, or Gate tweak) grounded in today's pattern.");
  }

  lines.push("", "## Trigger detail (resolved rows for this day)", JSON.stringify(args.triggersDetail, null, 2));

  return lines.join("\n");
}

export async function generateCoachCheckinNote(
  userSb: SupabaseClient,
  serviceSb: SupabaseClient,
  userId: string,
  input: GenerateCheckinNoteInput,
): Promise<{ data: GenerateCheckinNoteSuccess | null; error: GenerateCheckinNoteError | null }> {
  if (input.user_id && input.user_id !== userId) {
    return { data: null, error: { message: "user_id does not match authenticated user", code: "forbidden" } };
  }

  const { data: day, error: dErr } = await userSb.from("days").select("*").eq("id", input.day_id).maybeSingle();
  if (dErr) {
    return { data: null, error: { message: dErr.message, code: dErr.code, detail: dErr.details ?? undefined } };
  }
  const d = day as { user_id: string; [k: string]: unknown } | null;
  if (!d || d.user_id !== userId) {
    return { data: null, error: { message: "Day not found", code: "day_not_found" } };
  }

  const [{ data: goals, error: gErr }, { data: triggers, error: tErr }, { data: streak, error: sErr }] = await Promise.all([
    userSb.from("goals").select("id,text,status,completed_at,is_non_negotiable,category,priority").eq("day_id", input.day_id).order("order_index", { ascending: true }),
    userSb
      .from("gate_triggers")
      .select("id,usage_ratio,reason_classification,stated_reason,time_granted_seconds,time_used_seconds")
      .eq("day_id", input.day_id)
      .eq("user_id", userId),
    userSb.from("streaks").select("current_count").eq("user_id", userId).maybeSingle(),
  ]);

  if (gErr || tErr || sErr) {
    const err = gErr ?? tErr ?? sErr!;
    return { data: null, error: { message: err.message, code: err.code, detail: err.details ?? undefined } };
  }

  const goalRows = (goals ?? []) as Record<string, unknown>[];
  const triggerRows = (triggers ?? []) as Array<{ usage_ratio: number | null; reason_classification: string | null }>;

  const gateTriggersCountOnDay = typeof d.gate_triggers === "number" ? d.gate_triggers : Number(d.gate_triggers ?? 0);
  const gateDismissals = typeof d.gate_dismissals === "number" ? d.gate_dismissals : Number(d.gate_dismissals ?? 0);
  const goalsCount = typeof d.goals_count === "number" ? d.goals_count : Number(d.goals_count ?? 0);
  const goalsCompleted = typeof d.goals_completed === "number" ? d.goals_completed : Number(d.goals_completed ?? 0);
  const dayStatus = String(d.status ?? "");

  const triggersDetail = triggerRows.map((r) => ({
    usage_ratio: r.usage_ratio,
    reason_classification: r.reason_classification,
  }));

  const gateCallout = gateCalloutWarranted({
    gateTriggersCountOnDay,
    triggersToday: triggerRows,
  });
  const acknowledgeDismissals = gateDismissals > 0;
  const suggestTomorrowBlock = tomorrowAdjustmentWarranted({ dayStatus, goalsCount, goalsCompleted });

  const userPrompt = buildUserPrompt({
    day: d as Record<string, unknown>,
    goals: goalRows,
    streakCurrent: (streak as { current_count: number } | null)?.current_count ?? 0,
    gateTriggersOnDay: gateTriggersCountOnDay,
    gateDismissals,
    triggersDetail,
    gateCallout,
    acknowledgeDismissals,
    suggestTomorrowBlock,
  });

  let note: string;
  try {
    const r = await callHaiku(COACH_VOICE_SYSTEM_PROMPT, [{ role: "user", content: userPrompt }], 512);
    note = r.content.trim();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { data: null, error: { message: msg, code: "anthropic_error" } };
  }

  const { error: upErr } = await serviceSb
    .from("days")
    .update({ coach_check_in_note: note })
    .eq("id", input.day_id)
    .eq("user_id", userId);

  if (upErr) {
    return { data: null, error: { message: upErr.message, code: upErr.code, detail: upErr.details ?? undefined } };
  }

  return { data: { success: true }, error: null };
}
