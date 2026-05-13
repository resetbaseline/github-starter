import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callSonnet } from "../_shared/anthropic-client.ts";
import { COACH_VOICE_SYSTEM_PROMPT } from "../_shared/coach-voice.ts";
import { calendarToday, startOfCalendarDayUtcIso, validateTimeZone } from "../_shared/calendar.ts";
import type { GenerateIdentityMirrorError, GenerateIdentityMirrorInput, GenerateIdentityMirrorSuccess } from "./types.ts";
import { defaultMonthStart, firstOfMonthContaining, firstOfNextMonth, lastDayOfCalendarMonth } from "./month.ts";

const MIRROR_USER_INSTRUCTION = `## Task
You are writing an **identity mirror** for this user: a reflective portrait of **who they are becoming** over this calendar month, grounded strictly in the data below.

Output **one** cohesive piece of prose in **second person** ("you"): **6–12 short paragraphs** (plain text, no markdown headings, no bullet lists).
Weave together habits, tradeoffs, courage, and drift you can fairly infer from days, Gate behavior, check-ins, streaks, memory, and journal tone.
Be warm and unflinchingly honest; avoid flattery and avoid shame. Do not invent specific events or dates that are not supported by the payload.

Close with **two** sentences: what seems most alive in them this month, and one quality you see them practicing (even imperfectly).`;

type DayRow = {
  id: string;
  date: string;
  status: string;
  first_hour_complete: boolean;
  goals_count: number;
  goals_completed: number;
  focus_minutes_total: number;
  gate_triggers: number;
  gate_dismissals: number;
  coach_check_in_note: string | null;
};

export async function generateIdentityMirror(
  userSb: SupabaseClient,
  serviceSb: SupabaseClient,
  userId: string,
  input: GenerateIdentityMirrorInput,
  now: Date = new Date(),
): Promise<{ data: GenerateIdentityMirrorSuccess | null; error: GenerateIdentityMirrorError | null }> {
  if (input.user_id !== undefined && input.user_id !== userId) {
    return { data: null, error: { message: "user_id does not match authenticated user", code: "forbidden" } };
  }

  const { data: userRow, error: uErr } = await userSb
    .from("users")
    .select("timezone,name,identity_type,coach_strictness,wake_time,checkin_time,pro,onboarding_complete")
    .eq("id", userId)
    .maybeSingle();

  if (uErr) {
    return { data: null, error: { message: uErr.message, code: uErr.code, detail: uErr.details ?? undefined } };
  }
  const tz = (userRow as { timezone?: string } | null)?.timezone;
  if (!tz) {
    return { data: null, error: { message: "User timezone missing", code: "profile_missing" } };
  }
  const tzErr = validateTimeZone(tz);
  if (tzErr) {
    return { data: null, error: { message: tzErr, code: "invalid_timezone" } };
  }

  const anchorDay = input.month_start ?? calendarToday(now, tz);
  const monthStart = input.month_start ? firstOfMonthContaining(input.month_start, tz) : defaultMonthStart(now, tz);
  const monthEnd = lastDayOfCalendarMonth(monthStart);
  const rangeStartIso = startOfCalendarDayUtcIso(monthStart, tz);
  const rangeEndExclusiveIso = startOfCalendarDayUtcIso(firstOfNextMonth(monthStart), tz);

  const { data: existing, error: exErr } = await userSb
    .from("identity_mirror")
    .select("id, portrait_text, month_start, stats_summary")
    .eq("user_id", userId)
    .eq("month_start", monthStart)
    .maybeSingle();

  if (exErr) {
    return { data: null, error: { message: exErr.message, code: exErr.code, detail: exErr.details ?? undefined } };
  }
  if (existing) {
    const row = existing as {
      id: string;
      portrait_text: string;
      month_start: string;
      stats_summary: Record<string, unknown> | null;
    };
    return {
      data: {
        mirror_id: row.id,
        month_start: row.month_start,
        portrait_text: row.portrait_text,
        stats_summary: (row.stats_summary ?? {}) as Record<string, unknown>,
        duplicate: true,
      },
      error: null,
    };
  }

  const { data: days, error: dErr } = await userSb
    .from("days")
    .select(
      "id,date,status,first_hour_complete,goals_count,goals_completed,focus_minutes_total,gate_triggers,gate_dismissals,coach_check_in_note",
    )
    .eq("user_id", userId)
    .gte("date", monthStart)
    .lte("date", monthEnd)
    .order("date", { ascending: true });

  if (dErr) {
    return { data: null, error: { message: dErr.message, code: dErr.code, detail: dErr.details ?? undefined } };
  }

  const dayList = (days ?? []) as DayRow[];
  const dayIds = dayList.map((d) => d.id);

  const [
    { data: goals, error: gErr },
    { data: triggers, error: tErr },
    { data: checkins, error: cErr },
    { data: memory, error: mErr },
    { data: streak, error: sErr },
    { data: userGoals, error: ugErr },
    { data: patterns, error: pErr },
    { data: journal, error: jErr },
  ] = await Promise.all([
    dayIds.length
      ? userSb.from("goals").select("day_id,status,is_non_negotiable,text,category").in("day_id", dayIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    dayIds.length
      ? userSb.from("gate_triggers").select("day_id,usage_ratio,outcome,mismatch_flagged,trigger_source,reason_classification").in("day_id", dayIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    dayIds.length
      ? userSb.from("check_ins").select("day_id,submitted_at,streak_freeze_used").in("day_id", dayIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    userSb.from("coach_memory_profile").select("*").eq("user_id", userId).maybeSingle(),
    userSb.from("streaks").select("current_count,max_count,active,start_date").eq("user_id", userId).maybeSingle(),
    userSb.from("user_goals").select("goal_name,category,current_status,active").eq("user_id", userId).eq("active", true).limit(24),
    userSb
      .from("pattern_insights")
      .select("week_start,insight_text,created_at")
      .eq("user_id", userId)
      .gte("created_at", rangeStartIso)
      .lt("created_at", rangeEndExclusiveIso)
      .order("created_at", { ascending: false })
      .limit(12),
    userSb
      .from("coach_session_journal")
      .select("summary,session_type,emotional_tone,created_at")
      .eq("user_id", userId)
      .gte("created_at", rangeStartIso)
      .lt("created_at", rangeEndExclusiveIso)
      .order("created_at", { ascending: false })
      .limit(24),
  ]);

  const aggErr = gErr ?? tErr ?? cErr ?? mErr ?? sErr ?? ugErr ?? pErr ?? jErr;
  if (aggErr) {
    return { data: null, error: { message: aggErr.message, code: aggErr.code, detail: aggErr.details ?? undefined } };
  }

  const stats_summary = buildStatsSummary({
    monthStart,
    monthEnd,
    days: dayList,
    goals: (goals ?? []) as Record<string, unknown>[],
    triggers: (triggers ?? []) as Record<string, unknown>[],
    checkins: (checkins ?? []) as Record<string, unknown>[],
    patterns: (patterns ?? []) as Record<string, unknown>[],
    journalCount: (journal ?? []).length,
    streak: streak as Record<string, unknown> | null,
  });

  const pack = {
    timezone: tz,
    anchor_calendar_day: anchorDay,
    month_start: monthStart,
    month_end: monthEnd,
    user_profile: userRow,
    stats_summary,
    days: dayList,
    goals: goals ?? [],
    gate_triggers: triggers ?? [],
    check_ins: checkins ?? [],
    coach_memory_profile: memory ?? {},
    streaks: streak ?? {},
    user_goals: userGoals ?? [],
    pattern_insights: patterns ?? [],
    coach_session_journal: journal ?? [],
  };

  const userPrompt = [MIRROR_USER_INSTRUCTION, "", "## Monthly payload (JSON)", JSON.stringify(pack, null, 2)].join("\n");

  let portraitText: string;
  try {
    const r = await callSonnet(COACH_VOICE_SYSTEM_PROMPT, [{ role: "user", content: userPrompt }], 4096);
    portraitText = r.content.trim();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { data: null, error: { message: msg, code: "anthropic_error" } };
  }

  if (!portraitText) {
    return { data: null, error: { message: "Model returned empty portrait", code: "empty_model_output" } };
  }

  const { data: inserted, error: insErr } = await serviceSb
    .from("identity_mirror")
    .insert({
      user_id: userId,
      portrait_text: portraitText,
      stats_summary,
      month_start: monthStart,
    })
    .select("id")
    .single();

  if (insErr || !inserted) {
    return {
      data: null,
      error: { message: insErr?.message ?? "Insert failed", code: insErr?.code ?? "insert_failed", detail: insErr?.details ?? undefined },
    };
  }

  const ins = inserted as { id: string };
  return {
    data: { mirror_id: ins.id, month_start: monthStart, portrait_text: portraitText, stats_summary },
    error: null,
  };
}

function buildStatsSummary(args: {
  monthStart: string;
  monthEnd: string;
  days: DayRow[];
  goals: Record<string, unknown>[];
  triggers: Record<string, unknown>[];
  checkins: Record<string, unknown>[];
  patterns: Record<string, unknown>[];
  journalCount: number;
  streak: Record<string, unknown> | null;
}): Record<string, unknown> {
  const byStatus: Record<string, number> = {};
  let focusSum = 0;
  let gateTrigSum = 0;
  let gateDisSum = 0;
  let goalsCompletedSum = 0;
  let goalsCountSum = 0;
  let firstHourTrue = 0;

  for (const d of args.days) {
    const st = String(d.status ?? "unknown");
    byStatus[st] = (byStatus[st] ?? 0) + 1;
    focusSum += Number(d.focus_minutes_total ?? 0);
    gateTrigSum += Number(d.gate_triggers ?? 0);
    gateDisSum += Number(d.gate_dismissals ?? 0);
    goalsCompletedSum += Number(d.goals_completed ?? 0);
    goalsCountSum += Number(d.goals_count ?? 0);
    if (d.first_hour_complete) firstHourTrue += 1;
  }

  const goalStatus: Record<string, number> = {};
  for (const g of args.goals) {
    const s = String(g.status ?? "unknown");
    goalStatus[s] = (goalStatus[s] ?? 0) + 1;
  }

  let trigDismissed = 0;
  let trigTimed = 0;
  let trigMismatch = 0;
  for (const t of args.triggers) {
    if (t.outcome === "dismissed") trigDismissed += 1;
    if (t.outcome === "timed_access") trigTimed += 1;
    if (t.mismatch_flagged === true) trigMismatch += 1;
  }

  return {
    month_start: args.monthStart,
    month_end: args.monthEnd,
    days_with_rows: args.days.length,
    day_status_counts: byStatus,
    first_hour_complete_days: firstHourTrue,
    sums: {
      focus_minutes_total: focusSum,
      gate_triggers_on_days: gateTrigSum,
      gate_dismissals_on_days: gateDisSum,
      goals_completed_on_days: goalsCompletedSum,
      goals_count_on_days: goalsCountSum,
    },
    goals_in_month_by_status: goalStatus,
    goals_rows_in_month: args.goals.length,
    gate_trigger_rows_in_month: args.triggers.length,
    gate_trigger_outcomes: { dismissed: trigDismissed, timed_access: trigTimed, mismatch_flagged: trigMismatch },
    check_ins_in_month: args.checkins.length,
    pattern_insights_in_month: args.patterns.length,
    journal_entries_in_month: args.journalCount,
    streak: args.streak,
  };
}
