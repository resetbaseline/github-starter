import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callHaiku } from "../_shared/anthropic-client.ts";
import { calendarToday, validateTimeZone } from "../_shared/calendar.ts";
import { COACH_VOICE_SYSTEM_PROMPT, GATE_NEXT_ACTION_SYSTEM_SUPPLEMENT } from "../_shared/coach-voice.ts";
import { fetchNonNegotiableGoalNextAction } from "../_shared/next-action-goals.ts";
import {
  applyEscalation,
  applyMismatchReduction,
  baseGrantSeconds,
  firstWord,
  parseClassification,
  sanitizeLikeFragment,
  wordCount,
} from "./grant.ts";
import { classificationSystemPrompt, classificationUserMessage, coachGateUserMessage } from "./prompts.ts";
import type { GateValidateError, GateValidateInput, GateValidateSuccess } from "./types.ts";

type DayRow = { id: string; user_id: string; date: string; gate_triggers: number };

async function loadOrCreateTodayDay(
  userSb: SupabaseClient,
  userId: string,
  today: string,
): Promise<{ data: DayRow | null; error: GateValidateError | null }> {
  const { data: existing, error: e1 } = await userSb.from("days").select("id,user_id,date,gate_triggers").eq("date", today).maybeSingle();
  if (e1) {
    return { data: null, error: { message: e1.message, code: e1.code, detail: e1.details ?? undefined } };
  }
  if (existing) return { data: existing as DayRow, error: null };

  const { data: inserted, error: e2 } = await userSb
    .from("days")
    .insert({ user_id: userId, date: today })
    .select("id,user_id,date,gate_triggers")
    .maybeSingle();

  if (!e2 && inserted) return { data: inserted as DayRow, error: null };

  const isDup =
    e2?.code === "23505" ||
    (e2?.message?.toLowerCase().includes("duplicate") ?? false);

  if (isDup) {
    const { data: again, error: e3 } = await userSb.from("days").select("id,user_id,date,gate_triggers").eq("date", today).maybeSingle();
    if (e3) {
      return { data: null, error: { message: e3.message, code: e3.code, detail: e3.details ?? undefined } };
    }
    return { data: (again ?? null) as DayRow | null, error: null };
  }

  return { data: null, error: { message: e2?.message ?? "Failed to create day row", code: e2?.code, detail: e2?.details ?? undefined } };
}

export async function gateValidate(
  userSb: SupabaseClient,
  serviceSb: SupabaseClient,
  userId: string,
  input: GateValidateInput,
  now: Date = new Date(),
): Promise<{ data: GateValidateSuccess | null; error: GateValidateError | null }> {
  const { data: profile, error: pErr } = await userSb.from("users").select("timezone").eq("id", userId).maybeSingle();
  if (pErr) {
    return { data: null, error: { message: pErr.message, code: pErr.code, detail: pErr.details ?? undefined } };
  }
  const tz = (profile as { timezone?: string } | null)?.timezone;
  if (!tz) {
    return { data: null, error: { message: "User profile timezone missing", code: "profile_missing" } };
  }
  const tzErr = validateTimeZone(tz);
  if (tzErr) {
    return { data: null, error: { message: tzErr, code: "invalid_timezone" } };
  }

  const today = calendarToday(now, tz);
  const { data: day, error: dayErr } = await loadOrCreateTodayDay(userSb, userId, today);
  if (dayErr) return { data: null, error: dayErr };
  if (!day) return { data: null, error: { message: "Day row missing", code: "day_missing" } };

  const { data: streakRow, error: sErr } = await userSb.from("streaks").select("current_count").eq("user_id", userId).maybeSingle();
  if (sErr) {
    return { data: null, error: { message: sErr.message, code: sErr.code, detail: sErr.details ?? undefined } };
  }
  const streakCount = (streakRow as { current_count: number } | null)?.current_count ?? 0;

  const priorCount = day.gate_triggers ?? 0;
  const isFocusBlock = input.trigger_source === "focus_block";

  let nextAction: string | null = null;
  try {
    nextAction = await fetchNonNegotiableGoalNextAction(userSb, userId, day.id, input.active_non_negotiable);
  } catch (_e) {
    nextAction = null;
  }

  const gateCoachSystem = `${COACH_VOICE_SYSTEM_PROMPT}\n\n${GATE_NEXT_ACTION_SYSTEM_SUPPLEMENT}`;

  let timeGranted = 0;
  let coachResponse = "";
  let reasonClassification: string | null = null;

  if (isFocusBlock) {
    timeGranted = 0;
    const coach = await callHaiku(
      gateCoachSystem,
      [
        {
          role: "user",
          content:
            `Focus Block is active. Access grant must be 0 seconds.\nApp: ${input.app_name} (${input.app_bundle_id})\nUser message: """${input.stated_reason}"""\n` +
              `Non-negotiable context: ${input.active_non_negotiable ?? "(none)"}\n` +
              `next_action (first step for active NN goal, or null): ${nextAction ?? "null"}\n\n` +
              `Reply max 2 sentences. Be direct; no shaming.`,
        },
      ],
      256,
    );
    coachResponse = coach.content.trim();
  } else {
    const cls = await callHaiku(
      classificationSystemPrompt(),
      [{ role: "user", content: classificationUserMessage(input.stated_reason) }],
      64,
    );
    const classification = parseClassification(cls.content);
    reasonClassification = classification;

    let grant = baseGrantSeconds(classification);
    grant = applyEscalation(grant, priorCount);

    const frag = sanitizeLikeFragment(firstWord(input.stated_reason));
    let mismatchCount = 0;
    if (frag.length > 0) {
      const { count, error: cErr } = await userSb
        .from("gate_triggers")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .not("usage_ratio", "is", null)
        .gt("usage_ratio", 0.8)
        .ilike("stated_reason", `%${frag}%`);
      if (cErr) {
        return { data: null, error: { message: cErr.message, code: cErr.code, detail: cErr.details ?? undefined } };
      }
      mismatchCount = count ?? 0;
    }

    grant = applyMismatchReduction(grant, mismatchCount);
    timeGranted = grant;

    const coach = await callHaiku(
      gateCoachSystem,
      [
        {
          role: "user",
          content: coachGateUserMessage({
            stated_reason: input.stated_reason,
            classification,
            time_granted_seconds: timeGranted,
            active_non_negotiable: input.active_non_negotiable,
            next_action: nextAction,
          }),
        },
      ],
      256,
    );
    coachResponse = coach.content.trim();
  }

  const triggerOrdinal = priorCount + 1;
  const rwc = wordCount(input.stated_reason);

  const { data: inserted, error: insErr } = await serviceSb
    .from("gate_triggers")
    .insert({
      user_id: userId,
      day_id: day.id,
      app_bundle_id: input.app_bundle_id,
      app_name: input.app_name,
      trigger_source: input.trigger_source,
      trigger_count_today: triggerOrdinal,
      stated_reason: input.stated_reason,
      reason_word_count: rwc,
      coach_response: coachResponse,
      time_granted_seconds: timeGranted,
      active_non_negotiable: input.active_non_negotiable,
      streak_at_trigger: streakCount,
      reason_classification: reasonClassification,
    })
    .select("id")
    .single();

  if (insErr || !inserted) {
    return {
      data: null,
      error: { message: insErr?.message ?? "Failed to insert gate trigger", code: insErr?.code, detail: insErr?.details ?? undefined },
    };
  }

  const gateTriggerId = (inserted as { id: string }).id;

  const { error: upErr } = await serviceSb
    .from("days")
    .update({ gate_triggers: priorCount + 1 })
    .eq("id", day.id)
    .eq("user_id", userId);

  if (upErr) {
    return { data: null, error: { message: upErr.message, code: upErr.code, detail: upErr.details ?? undefined } };
  }

  return {
    data: {
      coach_response: coachResponse,
      time_granted_seconds: timeGranted,
      gate_trigger_id: gateTriggerId,
      trigger_count_today: triggerOrdinal,
    },
    error: null,
  };
}
