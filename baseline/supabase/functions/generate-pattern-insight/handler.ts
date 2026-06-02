import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callSonnet } from "../_shared/anthropic-client.ts";
import { COACH_VOICE_SYSTEM_PROMPT } from "../_shared/coach-voice.ts";
import { calendarToday, validateTimeZone } from "../_shared/calendar.ts";
import type { GeneratePatternInsightError, GeneratePatternInsightInput, GeneratePatternInsightSuccess } from "./types.ts";
import { defaultWeekMonday, mondayOfWeekContaining, weekEndSunday } from "./week.ts";

const PATTERN_USER_INSTRUCTION = `## Task
You are writing a **weekly pattern insight** for this user (not a chat reply).

Output **one** cohesive piece of prose: **4–8 short paragraphs** (plain text, no markdown headings, no bullet lists).
Name concrete patterns you see in the numbers (day statuses like strong/solid/light/rest/skipped, goal completion, Gate triggers/dismissals, focus minutes, check-ins).
Be direct but kind; avoid shame. End with **one** actionable experiment for next week (a single sentence).

Do not invent dates or events that are not implied by the data. If the week has little data, say so briefly and still offer a gentle framing.`;

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

export async function generatePatternInsight(
  userSb: SupabaseClient,
  serviceSb: SupabaseClient,
  userId: string,
  input: GeneratePatternInsightInput,
  now: Date = new Date(),
): Promise<{ data: GeneratePatternInsightSuccess | null; error: GeneratePatternInsightError | null }> {
  if (input.user_id !== undefined && input.user_id !== userId) {
    return { data: null, error: { message: "user_id does not match authenticated user", code: "forbidden" } };
  }

  const { data: userRow, error: uErr } = await userSb.from("users").select("timezone").eq("id", userId).maybeSingle();
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

  const anchorDay = input.week_start ?? calendarToday(now, tz);
  const weekMonday = input.week_start ? mondayOfWeekContaining(input.week_start, tz) : defaultWeekMonday(now, tz);
  const weekEnd = weekEndSunday(weekMonday);

  const { data: existing, error: exErr } = await userSb
    .from("pattern_insights")
    .select("id, insight_text, week_start")
    .eq("user_id", userId)
    .eq("week_start", weekMonday)
    .maybeSingle();

  if (exErr) {
    return { data: null, error: { message: exErr.message, code: exErr.code, detail: exErr.details ?? undefined } };
  }
  if (existing) {
    const row = existing as { id: string; insight_text: string; week_start: string };
    return {
      data: {
        insight_id: row.id,
        week_start: row.week_start,
        insight_text: row.insight_text,
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
    .gte("date", weekMonday)
    .lte("date", weekEnd)
    .order("date", { ascending: true });

  if (dErr) {
    return { data: null, error: { message: dErr.message, code: dErr.code, detail: dErr.details ?? undefined } };
  }

  const dayList = (days ?? []) as DayRow[];
  const dayIds = dayList.map((d) => d.id);

  const [{ data: goals, error: gErr }, { data: triggers, error: tErr }, { data: checkins, error: cErr }, { data: memory, error: mErr }, { data: streak, error: sErr }] =
    await Promise.all([
      dayIds.length
        ? userSb.from("goals").select("day_id,status,is_non_negotiable,text").in("day_id", dayIds)
        : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
      dayIds.length
        ? userSb.from("gate_triggers").select("day_id,usage_ratio,outcome,mismatch_flagged,trigger_source,reason_classification").in("day_id", dayIds)
        : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
      dayIds.length
        ? userSb.from("check_ins").select("day_id,submitted_at,streak_freeze_used").in("day_id", dayIds)
        : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
      userSb.from("coach_memory_profile").select("top_struggles,wins_recent,focus_window_best,highest_risk_window,coach_notes").eq("user_id", userId).maybeSingle(),
      userSb.from("streaks").select("current_count,max_count,active").eq("user_id", userId).maybeSingle(),
    ]);

  const aggErr = gErr ?? tErr ?? cErr ?? mErr ?? sErr;
  if (aggErr) {
    return { data: null, error: { message: aggErr.message, code: aggErr.code, detail: aggErr.details ?? undefined } };
  }

  const pack = {
    timezone: tz,
    anchor_calendar_day: anchorDay,
    week_monday: weekMonday,
    week_sunday: weekEnd,
    days: dayList,
    goals: goals ?? [],
    gate_triggers: triggers ?? [],
    check_ins: checkins ?? [],
    coach_memory_profile: memory ?? {},
    streaks: streak ?? {},
  };

  const userPrompt = [
    PATTERN_USER_INSTRUCTION,
    "",
    "## Weekly data (JSON)",
    JSON.stringify(pack, null, 2),
  ].join("\n");

  let insightText: string;
  try {
    const r = await callSonnet(COACH_VOICE_SYSTEM_PROMPT, [{ role: "user", content: userPrompt }], 2048);
    insightText = r.content.trim();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { data: null, error: { message: msg, code: "anthropic_error" } };
  }

  if (!insightText) {
    return { data: null, error: { message: "Model returned empty insight", code: "empty_model_output" } };
  }

  const { data: inserted, error: insErr } = await serviceSb
    .from("pattern_insights")
    .insert({
      user_id: userId,
      insight_text: insightText,
      week_start: weekMonday,
    })
    .select("id")
    .single();

  if (insErr || !inserted) {
    // Lost a concurrent generation race: another request already inserted this
    // week's insight. Return the winning row instead of erroring.
    if (insErr?.code === "23505") {
      const { data: dupRow } = await userSb
        .from("pattern_insights")
        .select("id, insight_text, week_start")
        .eq("user_id", userId)
        .eq("week_start", weekMonday)
        .maybeSingle();
      if (dupRow) {
        const row = dupRow as { id: string; insight_text: string; week_start: string };
        return {
          data: { insight_id: row.id, week_start: row.week_start, insight_text: row.insight_text, duplicate: true },
          error: null,
        };
      }
    }
    return {
      data: null,
      error: { message: insErr?.message ?? "Insert failed", code: insErr?.code ?? "insert_failed", detail: insErr?.details ?? undefined },
    };
  }

  const ins = inserted as { id: string };
  return { data: { insight_id: ins.id, week_start: weekMonday, insight_text: insightText }, error: null };
}
