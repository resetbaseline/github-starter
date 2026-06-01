import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export type StreakActivityType = "check_in" | "anchor" | "focus_session";

type StreakRow = {
  current_count: number;
  max_count: number;
  last_updated_date: string | null;
};

/**
 * Records at most one streak increment per `activityDate` (YYYY-MM-DD).
 * Updates `public.streaks` when this is the first qualifying activity that day.
 */
export async function incrementStreak(
  serviceSb: SupabaseClient,
  userId: string,
  activityDate: string,
  activityType: StreakActivityType,
): Promise<{ incremented: boolean }> {
  const { data: existing, error: existingErr } = await serviceSb
    .from("streak_activity_log")
    .select("id")
    .eq("user_id", userId)
    .eq("activity_date", activityDate)
    .maybeSingle();

  if (existingErr) {
    throw new Error(existingErr.message);
  }
  if (existing) {
    return { incremented: false };
  }

  const { error: logErr } = await serviceSb.from("streak_activity_log").insert({
    user_id: userId,
    activity_date: activityDate,
    activity_type: activityType,
  });

  if (logErr) {
    // Race: another request logged the same day first.
    if (logErr.code === "23505") {
      return { incremented: false };
    }
    throw new Error(logErr.message);
  }

  const { data: streakRow, error: streakErr } = await serviceSb
    .from("streaks")
    .select("current_count,max_count,last_updated_date")
    .eq("user_id", userId)
    .maybeSingle();

  if (streakErr) {
    throw new Error(streakErr.message);
  }
  if (!streakRow) {
    return { incremented: false };
  }

  const streak = streakRow as StreakRow;
  if (streak.last_updated_date === activityDate) {
    return { incremented: false };
  }

  const current_count = streak.current_count + 1;
  const max_count = Math.max(streak.max_count, current_count);

  const { error: updateErr } = await serviceSb
    .from("streaks")
    .update({
      current_count,
      max_count,
      last_updated_date: activityDate,
      active: true,
      end_date: null,
    })
    .eq("user_id", userId);

  if (updateErr) {
    throw new Error(updateErr.message);
  }

  return { incremented: true };
}
