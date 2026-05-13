import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { calendarToday, calendarYesterday, validateTimeZone } from "./dates.ts";

export type GetOrCreateDayData = {
  day: Record<string, unknown>;
  goals: Record<string, unknown>[];
  timers: Record<string, unknown>[];
  yesterday_intention: string | null;
};

export type GetOrCreateDayError = {
  message: string;
  code?: string;
  detail?: string;
};

/**
 * Core logic: ensure today's `days` row exists, load goals/timers and yesterday's intention.
 * `now` is injectable for tests.
 */
export async function getOrCreateDay(
  supabase: SupabaseClient,
  userId: string,
  timeZone: string,
  now: Date = new Date(),
): Promise<{ data: GetOrCreateDayData | null; error: GetOrCreateDayError | null }> {
  const tzErr = validateTimeZone(timeZone);
  if (tzErr) {
    return { data: null, error: { message: tzErr, code: "invalid_timezone" } };
  }

  const today = calendarToday(now, timeZone);
  const yesterday = calendarYesterday(today, timeZone);

  let dayRow: Record<string, unknown> | null = null;
  {
    const { data, error } = await supabase.from("days").select("*").eq("date", today).maybeSingle();
    if (error) {
      return {
        data: null,
        error: { message: error.message, code: error.code, detail: error.details ?? undefined },
      };
    }
    dayRow = (data ?? null) as Record<string, unknown> | null;
  }

  if (!dayRow) {
    const { data: inserted, error: insErr } = await supabase
      .from("days")
      .insert({ user_id: userId, date: today })
      .select("*")
      .maybeSingle();

    if (!insErr && inserted) {
      dayRow = inserted as Record<string, unknown>;
    } else if (insErr) {
      const isDup =
        insErr.code === "23505" ||
        (insErr.message?.toLowerCase().includes("duplicate") ?? false) ||
        (insErr.details?.toLowerCase().includes("already exists") ?? false);

      if (isDup) {
        const { data: existing, error: readErr } = await supabase
          .from("days")
          .select("*")
          .eq("date", today)
          .maybeSingle();
        if (readErr) {
          return {
            data: null,
            error: { message: readErr.message, code: readErr.code, detail: readErr.details ?? undefined },
          };
        }
        dayRow = (existing ?? null) as Record<string, unknown> | null;
      } else {
        return {
          data: null,
          error: { message: insErr.message, code: insErr.code, detail: insErr.details ?? undefined },
        };
      }
    }
  }

  if (!dayRow || typeof dayRow["id"] !== "string") {
    return { data: null, error: { message: "Failed to load or create day row", code: "day_missing" } };
  }

  const dayId = dayRow["id"] as string;

  const [{ data: goals, error: goalsErr }, { data: timers, error: timersErr }, { data: yDay, error: yErr }] =
    await Promise.all([
      supabase.from("goals").select("*").eq("day_id", dayId).order("order_index", { ascending: true }),
      supabase.from("timers").select("*").eq("day_id", dayId),
      supabase.from("days").select("tomorrow_intention").eq("date", yesterday).maybeSingle(),
    ]);

  if (goalsErr) {
    return {
      data: null,
      error: { message: goalsErr.message, code: goalsErr.code, detail: goalsErr.details ?? undefined },
    };
  }
  if (timersErr) {
    return {
      data: null,
      error: { message: timersErr.message, code: timersErr.code, detail: timersErr.details ?? undefined },
    };
  }
  if (yErr) {
    return {
      data: null,
      error: { message: yErr.message, code: yErr.code, detail: yErr.details ?? undefined },
    };
  }

  const yesterdayIntention = yDay
    ? (yDay as { tomorrow_intention?: string | null }).tomorrow_intention ?? null
    : null;

  return {
    data: {
      day: dayRow,
      goals: (goals ?? []) as Record<string, unknown>[],
      timers: (timers ?? []) as Record<string, unknown>[],
      yesterday_intention: yesterdayIntention,
    },
    error: null,
  };
}
