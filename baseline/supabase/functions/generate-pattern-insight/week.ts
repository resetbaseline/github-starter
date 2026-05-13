import { fromZonedTime } from "https://esm.sh/date-fns-tz@3.2.0";
import { addCalendarDays, calendarToday } from "../_shared/calendar.ts";

/**
 * Monday = 0 … Sunday = 6 for the calendar day `yyyy-MM-dd` interpreted at noon in `timeZone`.
 */
export function weekdayMonday0FromCalendarDate(calendarDateYmd: string, timeZone: string): number {
  const inst = fromZonedTime(`${calendarDateYmd} 12:00:00`, timeZone);
  const fmt = new Intl.DateTimeFormat("en-US", { weekday: "short", timeZone });
  const s = fmt.format(inst);
  const head = s.replace(/\.$/, "").slice(0, 3);
  const lookup: Record<string, number> = { Mon: 0, Tue: 1, Wed: 2, Thu: 3, Fri: 4, Sat: 5, Sun: 6 };
  return lookup[head] ?? 0;
}

/** Monday `YYYY-MM-DD` (in `timeZone`) for the week containing `calendarDateYmd`. */
export function mondayOfWeekContaining(calendarDateYmd: string, timeZone: string): string {
  const mon0 = weekdayMonday0FromCalendarDate(calendarDateYmd, timeZone);
  return addCalendarDays(calendarDateYmd, -mon0);
}

export function weekEndSunday(weekMondayYmd: string): string {
  return addCalendarDays(weekMondayYmd, 6);
}

/** Current calendar day in `timeZone`, then Monday of that week. */
export function defaultWeekMonday(now: Date, timeZone: string): string {
  const today = calendarToday(now, timeZone);
  return mondayOfWeekContaining(today, timeZone);
}
