import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { addCalendarDays } from "./calendar.ts";

export type StreakActivityType = "check_in" | "anchor" | "focus_session";

type StreakRow = {
  current_count: number;
  max_count: number;
  last_updated_date: string | null;
  start_date: string | null;
};

/** A new freeze is granted every time the streak reaches a multiple of this many days. */
const FREEZE_AWARD_INTERVAL = 7;

/** Whole calendar days from `fromYmd` to `toYmd` (both `YYYY-MM-DD`, UTC date math). */
export function calendarDaysBetween(fromYmd: string, toYmd: string): number {
  const [y1, m1, d1] = fromYmd.split("-").map(Number);
  const [y2, m2, d2] = toYmd.split("-").map(Number);
  const t1 = Date.UTC(y1, m1 - 1, d1);
  const t2 = Date.UTC(y2, m2 - 1, d2);
  return Math.round((t2 - t1) / 86_400_000);
}

export type StreakTransition = {
  newCount: number;
  newStartDate: string | null;
  /** Net change to apply to `streak_freeze_count` (negative = consumed, positive = granted). */
  freezeDelta: number;
  /** Number of freezes consumed to bridge a missed day (0 or 1). */
  freezeConsumed: number;
  bridged: boolean;
};

/**
 * Pure streak-state transition. Given the prior streak and the new activity date,
 * compute the next count, start date, and freeze movement.
 */
export function computeStreakTransition(args: {
  lastUpdatedDate: string | null;
  currentCount: number;
  startDate: string | null;
  activityDate: string;
  freezeCount: number;
}): StreakTransition {
  const { lastUpdatedDate: last, currentCount, startDate, activityDate, freezeCount } = args;
  const yesterday = addCalendarDays(activityDate, -1);

  let newCount: number;
  let newStartDate = startDate;
  let freezeConsumed = 0;
  let bridged = false;

  if (!last) {
    newCount = 1;
    newStartDate = activityDate;
  } else if (last === yesterday) {
    newCount = currentCount + 1;
  } else {
    const missedDays = calendarDaysBetween(last, activityDate) - 1;
    if (missedDays === 1 && freezeCount > 0) {
      freezeConsumed = 1;
      newCount = currentCount + 1;
      bridged = true;
    } else {
      newCount = 1;
      newStartDate = activityDate;
    }
  }

  // Grant a freeze on each 7-day milestone (no cap).
  const granted = newCount > currentCount && newCount % FREEZE_AWARD_INTERVAL === 0 ? 1 : 0;

  return {
    newCount,
    newStartDate,
    freezeDelta: granted - freezeConsumed,
    freezeConsumed,
    bridged,
  };
}

/**
 * Records at most one streak increment per `activityDate` (YYYY-MM-DD) and updates
 * `public.streaks`. Any one of check-in / anchor / focus session counts for the day.
 *
 * Streak rules:
 * - First ever activity → count = 1.
 * - Activity the day after `last_updated_date` → count + 1 (consecutive).
 * - Exactly one missed day with a freeze available → consume the freeze, count + 1 (bridged).
 * - Two or more missed days, or one missed day with no freeze → reset to 1.
 * - A freeze is granted each time the streak reaches a 7-day multiple (no cap).
 *
 * The unique `(user_id, activity_date)` row in `streak_activity_log` is the once-per-day
 * lock; concurrent callers on the same day no-op via the unique violation.
 */
export async function incrementStreak(
  serviceSb: SupabaseClient,
  userId: string,
  activityDate: string,
  activityType: StreakActivityType,
): Promise<{ incremented: boolean; bridged: boolean }> {
  // 1. Read the streak row first — never burn a day if the row is missing.
  const { data: streakRow, error: streakErr } = await serviceSb
    .from("streaks")
    .select("current_count,max_count,last_updated_date,start_date")
    .eq("user_id", userId)
    .maybeSingle();

  if (streakErr) {
    throw new Error(streakErr.message);
  }
  if (!streakRow) {
    throw new Error("Streak row missing for user");
  }
  const streak = streakRow as StreakRow;

  // Defensive: already counted today (the log lock below is the real guard).
  if (streak.last_updated_date === activityDate) {
    return { incremented: false, bridged: false };
  }

  // 2. Acquire the once-per-day lock.
  const { error: logErr } = await serviceSb.from("streak_activity_log").insert({
    user_id: userId,
    activity_date: activityDate,
    activity_type: activityType,
  });

  if (logErr) {
    if (logErr.code === "23505") {
      return { incremented: false, bridged: false };
    }
    throw new Error(logErr.message);
  }

  const rollbackLog = async () => {
    await serviceSb
      .from("streak_activity_log")
      .delete()
      .eq("user_id", userId)
      .eq("activity_date", activityDate);
  };

  // 3. Read the freeze balance.
  const { data: userRow, error: userErr } = await serviceSb
    .from("users")
    .select("streak_freeze_count,streak_freeze_used_this_month")
    .eq("id", userId)
    .single();

  if (userErr) {
    await rollbackLog();
    throw new Error(userErr.message);
  }

  const initialFreezeCount = (userRow as { streak_freeze_count: number }).streak_freeze_count ?? 0;
  const initialFreezeUsed =
    (userRow as { streak_freeze_used_this_month: number }).streak_freeze_used_this_month ?? 0;

  // 4. Compute the next streak state (pure).
  const transition = computeStreakTransition({
    lastUpdatedDate: streak.last_updated_date,
    currentCount: streak.current_count,
    startDate: streak.start_date,
    activityDate,
    freezeCount: initialFreezeCount,
  });

  const { newCount, newStartDate, bridged } = transition;
  const freezeCount = initialFreezeCount + transition.freezeDelta;
  const freezeUsed = initialFreezeUsed + transition.freezeConsumed;
  const newMax = Math.max(streak.max_count, newCount);

  // 5. Persist the streak.
  const { error: updErr } = await serviceSb
    .from("streaks")
    .update({
      current_count: newCount,
      max_count: newMax,
      last_updated_date: activityDate,
      start_date: newStartDate,
      active: true,
      end_date: null,
    })
    .eq("user_id", userId);

  if (updErr) {
    await rollbackLog();
    throw new Error(updErr.message);
  }

  // 6. Persist the freeze balance if it changed.
  if (freezeCount !== initialFreezeCount || freezeUsed !== initialFreezeUsed) {
    const { error: freezeErr } = await serviceSb
      .from("users")
      .update({ streak_freeze_count: freezeCount, streak_freeze_used_this_month: freezeUsed })
      .eq("id", userId);
    if (freezeErr) {
      throw new Error(freezeErr.message);
    }
  }

  return { incremented: true, bridged };
}
