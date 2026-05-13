import { formatInTimeZone, fromZonedTime } from "https://esm.sh/date-fns-tz@3.2.0";
import { subDays } from "https://esm.sh/date-fns@3.6.0";

export { calendarToday, validateTimeZone } from "../_shared/calendar.ts";

/**
 * Calendar yesterday relative to `calendarTodayStr` in `timeZone`.
 * Uses noon on the given calendar day as anchor to reduce DST edge issues.
 */
export function calendarYesterday(calendarTodayStr: string, timeZone: string): string {
  const noon = fromZonedTime(`${calendarTodayStr} 12:00:00`, timeZone);
  const prev = subDays(noon, 1);
  return formatInTimeZone(prev, timeZone, "yyyy-MM-dd");
}
