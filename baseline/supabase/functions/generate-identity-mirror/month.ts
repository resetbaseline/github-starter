import { formatInTimeZone, fromZonedTime } from "https://esm.sh/date-fns-tz@3.2.0";
import { calendarToday } from "../_shared/calendar.ts";

/** First day `YYYY-MM-01` of the calendar month containing `calendarDateYmd` in `timeZone`. */
export function firstOfMonthContaining(calendarDateYmd: string, timeZone: string): string {
  const inst = fromZonedTime(`${calendarDateYmd} 12:00:00`, timeZone);
  const ym = formatInTimeZone(inst, timeZone, "yyyy-MM");
  return `${ym}-01`;
}

/** `month_start` is always `yyyy-mm-01`; returns last calendar day of that month (`YYYY-MM-DD`, UTC date math). */
export function lastDayOfCalendarMonth(monthStartYmd: string): string {
  const [y, m] = monthStartYmd.split("-").map(Number);
  const last = new Date(Date.UTC(y, m, 0));
  return last.toISOString().slice(0, 10);
}

/** First day of the next calendar month after `monthStartYmd` (which must be `yyyy-mm-01`). */
export function firstOfNextMonth(monthStartYmd: string): string {
  const [y, m] = monthStartYmd.split("-").map(Number);
  if (m === 12) return `${y + 1}-01-01`;
  return `${y}-${String(m + 1).padStart(2, "0")}-01`;
}

export function defaultMonthStart(now: Date, timeZone: string): string {
  return firstOfMonthContaining(calendarToday(now, timeZone), timeZone);
}
