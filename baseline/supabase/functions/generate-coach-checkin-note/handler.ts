import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callHaiku } from "../_shared/anthropic-client.ts";
import { gateCalloutWarranted, tomorrowAdjustmentWarranted } from "./logic.ts";
import type { GenerateCheckinNoteError, GenerateCheckinNoteInput, GenerateCheckinNoteSuccess } from "./types.ts";

/** System prompt for nightly check-in notes only (no win/loss framing). */
const CHECKIN_NOTE_SYSTEM_PROMPT = `You write the nightly check-in note for Baseline.

Output shape:
- Write 2–3 short sentences total (aim for 3 when the day status is "strong" as defined below).
- Sentence 1: Name specifically what happened today using only the JSON data provided (goals completed vs pending, focus minutes, gate trigger count, gate dismissals, streak current_count when it helps). Do not invent facts.
- Sentence 2: Give exactly one concrete next-step recommendation grounded in those patterns (a schedule tweak, Gate use, or goal sizing — not generic self-help).

If the day row's "status" field is exactly the string "strong", add a third sentence (or a second clause after sentence 2): a calm identity-reinforcement line such as "This is what your baseline looks like." followed by one question asking what made today work.

Hard bans for your wording (do not use these or close variants): won, lost, failed, crushed, great job, proud, amazing.

Tone: calm, direct, observant — like a coach who read their log, not a cheerleader.

Immediately after this paragraph, the system message includes a section titled "## Long term goals" listing each active user_goal as [category] plus long_term_goal text. When that list is non-empty, you may briefly tie sentence 1 or 2 to one ambition if the day''s evidence naturally connects — do not invent progress on those outcomes. If the list says (none active), ignore it.`;

function buildUserPrompt(args: {
  day: Record<string, unknown>;
  goals: Record<string, unknown>[];
  userGoals: Record<string, unknown>[];
  streakCurrent: number;
  gateTriggersOnDay: number;
  gateDismissals: number;
  triggersDetail: Array<{ usage_ratio: number | null; reason_classification: string | null }>;
  gateCallout: boolean;
  suggestTomorrowBlock: boolean;
  dayStatus: string;
}): string {
  const lines: string[] = [
    "## Evidence (use only this; do not fabricate)",
    "",
    "### Day row (JSON)",
    JSON.stringify(args.day, null, 2),
    "",
    "### Long term goals (active user_goals; JSON)",
    JSON.stringify(args.userGoals, null, 2),
    "",
    "### Goals for this day (JSON)",
    JSON.stringify(args.goals, null, 2),
    "",
    "### Aggregates",
    `- streak current_count: ${args.streakCurrent}`,
    `- gate_triggers (count on day row): ${args.gateTriggersOnDay}`,
    `- gate_dismissals: ${args.gateDismissals}`,
    `- day status (string): ${args.dayStatus}`,
    "",
    "### Gate trigger rows for this day (JSON)",
    JSON.stringify(args.triggersDetail, null, 2),
    "",
    "## Writing constraints",
    `- If gate_dismissals > 0, sentence 1 should mention dismissals factually (what they closed or declined), without framing it as victory or failure language.`,
    args.gateCallout
      ? "- Gate usage is elevated or patterns look sharp today: sentence 1 or 2 should mention triggers or usage vs stated reasons in one precise clause."
      : "- Gate: keep any mention proportional; do not dramatize.",
    args.suggestTomorrowBlock
      ? "- Sentence 2 should lean toward a specific tomorrow adjustment (time block, first goal smaller, or Gate timing) because completion was thin or the day was light."
      : "- Sentence 2 can still be one concrete habit-level step; keep it tied to the numbers above.",
    "",
    `If status is "strong", include the identity line + question as specified in the system prompt. Otherwise do not use that identity line or that extra question.`,
  ];

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

  const [{ data: goals, error: gErr }, { data: triggers, error: tErr }, { data: streak, error: sErr }, { data: userGoals, error: ugErr }] =
    await Promise.all([
      userSb.from("goals").select("id,text,status,completed_at,is_non_negotiable,category,priority").eq("day_id", input.day_id).order(
        "order_index",
        { ascending: true },
      ),
      userSb
        .from("gate_triggers")
        .select("id,usage_ratio,reason_classification,stated_reason,time_granted_seconds,time_used_seconds")
        .eq("day_id", input.day_id)
        .eq("user_id", userId),
      userSb.from("streaks").select("current_count").eq("user_id", userId).maybeSingle(),
      userSb
        .from("user_goals")
        .select("id,category,long_term_goal,goal_name,target_date,daily_action_suggestion,order_index,active")
        .eq("user_id", userId)
        .eq("active", true)
        .order("order_index", { ascending: true }),
    ]);

  if (gErr || tErr || sErr || ugErr) {
    const err = gErr ?? tErr ?? sErr ?? ugErr!;
    return { data: null, error: { message: err.message, code: err.code, detail: err.details ?? undefined } };
  }

  const goalRows = (goals ?? []) as Record<string, unknown>[];
  const userGoalRows = (userGoals ?? []) as Record<string, unknown>[];
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
  const suggestTomorrowBlock = tomorrowAdjustmentWarranted({ dayStatus, goalsCount, goalsCompleted });

  const userPrompt = buildUserPrompt({
    day: d as Record<string, unknown>,
    goals: goalRows,
    userGoals: userGoalRows,
    streakCurrent: (streak as { current_count: number } | null)?.current_count ?? 0,
    gateTriggersOnDay: gateTriggersCountOnDay,
    gateDismissals,
    triggersDetail,
    gateCallout,
    suggestTomorrowBlock,
    dayStatus,
  });

  const longTermGoalsSystemLines: string[] = ["\n## Long term goals\n"];
  if (userGoalRows.length === 0) {
    longTermGoalsSystemLines.push("(none active)\n");
  } else {
    for (const row of userGoalRows) {
      const cat = String(row.category ?? "");
      const lt = String(row.long_term_goal ?? row.goal_name ?? "");
      longTermGoalsSystemLines.push(`- [${cat}] ${lt}\n`);
    }
  }
  const checkinSystemPrompt = CHECKIN_NOTE_SYSTEM_PROMPT + longTermGoalsSystemLines.join("");

  let note: string;
  try {
    const r = await callHaiku(checkinSystemPrompt, [{ role: "user", content: userPrompt }], 512);
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
