import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  addCalendarDays,
  classifyDayResult,
  isPerfectDay,
  outcomeMap,
  validateGoalCoverage,
  validateNonNegotiables,
  type GoalRow,
} from "./logic.ts";
import type { ProcessCheckinError, ProcessCheckinInput, ProcessCheckinSuccess } from "./types.ts";

type DayRow = {
  id: string;
  user_id: string;
  date: string;
  focus_minutes_total: number;
};

type StreakRow = {
  current_count: number;
  max_count: number;
  active: boolean;
  last_updated_date: string | null;
  perfect_day_count: number;
  perfect_days_this_month: number;
  start_date: string;
};

function fireAndForgetInternalFunctions(service: SupabaseClient, userId: string, dayId: string, checkInId: string) {
  void service.functions.invoke("generate-coach-checkin-note", {
    body: { day_id: dayId, user_id: userId },
  }).catch(() => undefined);

  void service.functions.invoke("update-coach-memory", {
    body: { user_id: userId, session_id: checkInId },
  }).catch(() => undefined);
}

export async function processCheckIn(
  userSb: SupabaseClient,
  serviceSb: SupabaseClient,
  userId: string,
  input: ProcessCheckinInput,
): Promise<{ data: ProcessCheckinSuccess | null; error: ProcessCheckinError | null }> {
  const { data: existingCheckin, error: existingErr } = await userSb
    .from("check_ins")
    .select("id")
    .eq("day_id", input.day_id)
    .maybeSingle();

  if (existingErr) {
    return { data: null, error: { message: existingErr.message, code: existingErr.code, detail: existingErr.details ?? undefined } };
  }
  if (existingCheckin) {
    return { data: null, error: { message: "Check-in already submitted for this day", code: "already_submitted" } };
  }

  const { data: dayRow, error: dayErr } = await userSb
    .from("days")
    .select("id,user_id,date,focus_minutes_total")
    .eq("id", input.day_id)
    .maybeSingle();

  if (dayErr) {
    return { data: null, error: { message: dayErr.message, code: dayErr.code, detail: dayErr.details ?? undefined } };
  }
  const day = dayRow as DayRow | null;
  if (!day || day.user_id !== userId) {
    return { data: null, error: { message: "Day not found", code: "day_not_found" } };
  }

  const { data: goalRows, error: goalsErr } = await userSb
    .from("goals")
    .select("id,is_non_negotiable")
    .eq("day_id", input.day_id);

  if (goalsErr) {
    return { data: null, error: { message: goalsErr.message, code: goalsErr.code, detail: goalsErr.details ?? undefined } };
  }

  const goals = (goalRows ?? []) as GoalRow[];
  const outcomes = outcomeMap(input.goal_outcomes);

  const coverageErr = validateGoalCoverage(goals, input.goal_outcomes);
  if (coverageErr) {
    return { data: null, error: { message: coverageErr, code: "invalid_goal_outcomes" } };
  }

  const nnErr = validateNonNegotiables(goals, outcomes);
  if (nnErr) {
    return { data: null, error: { message: nnErr, code: "invalid_goal_outcomes" } };
  }

  const dayStatus = classifyDayResult({
    goals,
    outcomes,
    reflectionCount: input.reflection_answers.length,
    focusMinutesTotal: day.focus_minutes_total,
  });

  if (dayStatus === "lost" && input.streak_freeze_used) {
    const { data: u, error: uErr } = await userSb.from("users").select("streak_freeze_count").eq("id", userId).single();
    if (uErr) {
      return { data: null, error: { message: uErr.message, code: uErr.code, detail: uErr.details ?? undefined } };
    }
    const available = (u as { streak_freeze_count: number }).streak_freeze_count;
    if (available <= 0) {
      return { data: null, error: { message: "No streak freezes available", code: "streak_freeze_unavailable" } };
    }
  }

  const perfect = isPerfectDay({
    goals,
    outcomes,
    reflectionCount: input.reflection_answers.length,
    focusMinutesTotal: day.focus_minutes_total,
  });

  const nnReviewed = goals.filter((g) => g.is_non_negotiable).every((g) => outcomes.has(g.id));

  for (const o of input.goal_outcomes) {
    const status = o.completed ? "completed" : "pending";
    const completed_at = o.completed ? new Date().toISOString() : null;
    const { error: upErr } = await userSb
      .from("goals")
      .update({ status, completed_at })
      .eq("id", o.goal_id)
      .eq("day_id", input.day_id)
      .eq("user_id", userId);
    if (upErr) {
      return { data: null, error: { message: upErr.message, code: upErr.code, detail: upErr.details ?? undefined } };
    }
  }

  const { error: dayUpErr } = await userSb
    .from("days")
    .update({
      status: dayStatus,
      reflection_data: input.reflection_answers,
      tomorrow_intention: input.tomorrow_intention,
    })
    .eq("id", input.day_id)
    .eq("user_id", userId);

  if (dayUpErr) {
    return { data: null, error: { message: dayUpErr.message, code: dayUpErr.code, detail: dayUpErr.details ?? undefined } };
  }

  const { data: checkInRow, error: ciErr } = await userSb
    .from("check_ins")
    .insert({
      user_id: userId,
      day_id: input.day_id,
      non_negotiables_reviewed: nnReviewed,
      reflection_answers: input.reflection_answers,
      tomorrow_intention: input.tomorrow_intention,
      tomorrow_timeblocks: input.tomorrow_timeblocks,
      streak_freeze_used: input.streak_freeze_used,
      submitted_at: new Date().toISOString(),
    })
    .select("id")
    .single();

  if (ciErr || !checkInRow) {
    return {
      data: null,
      error: { message: ciErr?.message ?? "Failed to insert check-in", code: ciErr?.code, detail: ciErr?.details ?? undefined },
    };
  }

  const checkInId = (checkInRow as { id: string }).id;

  if (dayStatus !== "skipped") {
    const { data: streakRow, error: stFetchErr } = await serviceSb
      .from("streaks")
      .select("current_count,max_count,active,last_updated_date,perfect_day_count,perfect_days_this_month,start_date")
      .eq("user_id", userId)
      .maybeSingle();

    if (stFetchErr) {
      return { data: null, error: { message: stFetchErr.message, code: stFetchErr.code, detail: stFetchErr.details ?? undefined } };
    }
    if (!streakRow) {
      return { data: null, error: { message: "Streak row missing for user", code: "streak_missing" } };
    }

    const streak = streakRow as StreakRow;

    const { data: userRow, error: userFetchErr } = await serviceSb
      .from("users")
      .select("streak_freeze_count,streak_freeze_used_this_month")
      .eq("id", userId)
      .single();

    if (userFetchErr) {
      return {
        data: null,
        error: { message: userFetchErr.message, code: userFetchErr.code, detail: userFetchErr.details ?? undefined },
      };
    }

    const userFreeze = userRow as { streak_freeze_count: number; streak_freeze_used_this_month: number };

    if (dayStatus === "won") {
      if (streak.last_updated_date !== day.date) {
        const current_count = streak.current_count + 1;
        const max_count = Math.max(streak.max_count, current_count);
        const { error: stUp } = await serviceSb
          .from("streaks")
          .update({
            current_count,
            max_count,
            last_updated_date: day.date,
            active: true,
            end_date: null,
          })
          .eq("user_id", userId);
        if (stUp) {
          return { data: null, error: { message: stUp.message, code: stUp.code, detail: stUp.details ?? undefined } };
        }
      }
    } else if (dayStatus === "lost") {
      if (input.streak_freeze_used) {
        const { error: fu } = await serviceSb
          .from("users")
          .update({
            streak_freeze_count: userFreeze.streak_freeze_count - 1,
            streak_freeze_used_this_month: userFreeze.streak_freeze_used_this_month + 1,
          })
          .eq("id", userId);
        if (fu) {
          return { data: null, error: { message: fu.message, code: fu.code, detail: fu.details ?? undefined } };
        }
      } else {
        const tomorrow = addCalendarDays(day.date, 1);
        const { error: stUp } = await serviceSb
          .from("streaks")
          .update({
            current_count: 0,
            start_date: tomorrow,
            end_date: null,
            active: true,
            last_updated_date: null,
          })
          .eq("user_id", userId);
        if (stUp) {
          return { data: null, error: { message: stUp.message, code: stUp.code, detail: stUp.details ?? undefined } };
        }
      }
    }

    if (perfect) {
      const oldPdm = streak.perfect_days_this_month;
      const oldPdc = streak.perfect_day_count;
      const newPdm = oldPdm + 1;
      const newPdc = oldPdc + 1;

      const { error: pErr } = await serviceSb
        .from("streaks")
        .update({
          perfect_day_count: newPdc,
          perfect_days_this_month: newPdm,
        })
        .eq("user_id", userId);
      if (pErr) {
        return { data: null, error: { message: pErr.message, code: pErr.code, detail: pErr.details ?? undefined } };
      }

      const { data: uFreeze2, error: u2Err } = await serviceSb.from("users").select("streak_freeze_count").eq("id", userId).single();
      if (u2Err) {
        return { data: null, error: { message: u2Err.message, code: u2Err.code, detail: u2Err.details ?? undefined } };
      }
      const fc = (uFreeze2 as { streak_freeze_count: number }).streak_freeze_count;
      if (newPdm > oldPdm && fc < 3) {
        const { error: awErr } = await serviceSb
          .from("users")
          .update({ streak_freeze_count: fc + 1 })
          .eq("id", userId);
        if (awErr) {
          return { data: null, error: { message: awErr.message, code: awErr.code, detail: awErr.details ?? undefined } };
        }
      }
    }
  }

  const tomorrowDate = addCalendarDays(day.date, 1);
  const { data: tomorrowDay, error: tdErr } = await userSb
    .from("days")
    .upsert(
      {
        user_id: userId,
        date: tomorrowDate,
        tomorrow_intention: input.tomorrow_intention,
      },
      { onConflict: "user_id,date" },
    )
    .select("id")
    .single();

  if (tdErr || !tomorrowDay) {
    return {
      data: null,
      error: { message: tdErr?.message ?? "Failed to upsert tomorrow day", code: tdErr?.code, detail: tdErr?.details ?? undefined },
    };
  }

  const tomorrowId = (tomorrowDay as { id: string }).id;

  if (input.tomorrow_timeblocks.length > 0) {
    const rows = input.tomorrow_timeblocks.map((t) => ({
      user_id: userId,
      day_id: tomorrowId,
      title: t.title,
      start_time: t.start_time,
      end_time: t.end_time,
      color_hex: t.color_hex,
    }));
    const { error: tbErr } = await userSb.from("time_blocks").insert(rows);
    if (tbErr) {
      return { data: null, error: { message: tbErr.message, code: tbErr.code, detail: tbErr.details ?? undefined } };
    }
  }

  fireAndForgetInternalFunctions(serviceSb, userId, input.day_id, checkInId);

  const { data: streakOut, error: soErr } = await userSb.from("streaks").select("current_count,max_count,active").eq("user_id", userId).single();
  if (soErr) {
    return { data: null, error: { message: soErr.message, code: soErr.code, detail: soErr.details ?? undefined } };
  }
  const { data: userOut, error: uoErr } = await userSb
    .from("users")
    .select("streak_freeze_count,streak_freeze_used_this_month")
    .eq("id", userId)
    .single();
  if (uoErr) {
    return { data: null, error: { message: uoErr.message, code: uoErr.code, detail: uoErr.details ?? undefined } };
  }

  return {
    data: {
      day_status: dayStatus,
      streak: {
        current_count: (streakOut as { current_count: number }).current_count,
        max_count: (streakOut as { max_count: number }).max_count,
        active: (streakOut as { active: boolean }).active,
      },
      freeze_counts: {
        available: (userOut as { streak_freeze_count: number }).streak_freeze_count,
        used_this_month: (userOut as { streak_freeze_used_this_month: number }).streak_freeze_used_this_month,
      },
      perfect_day: perfect,
    },
    error: null,
  };
}
