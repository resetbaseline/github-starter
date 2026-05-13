import { formatInTimeZone, fromZonedTime } from "https://esm.sh/date-fns-tz@3.2.0";
import { subDays } from "https://esm.sh/date-fns@3.6.0";

/** Calendar date YYYY-MM-DD for `instant` interpreted in `timeZone` (IANA). */
export function calendarToday(instant: Date, timeZone: string): string {
  return formatInTimeZone(instant, timeZone, "yyyy-MM-dd");
}

/**
 * Calendar yesterday relative to `calendarTodayStr` in `timeZone`.
 * Uses noon on the given calendar day as anchor to reduce DST edge issues.
 */
export function calendarYesterday(calendarTodayStr: string, timeZone: string): string {
  const noon = fromZonedTime(`${calendarTodayStr} 12:00:00`, timeZone);
  const prev = subDays(noon, 1);
  return formatInTimeZone(prev, timeZone, "yyyy-MM-dd");
}

/** Returns an error message if `timeZone` is not usable with date-fns-tz / Intl. */
export function validateTimeZone(timeZone: string): string | null {
  const t = timeZone?.trim();
  if (!t) return "timezone is empty";
  try {
    formatInTimeZone(new Date(), t, "yyyy-MM-dd");
    return null;
  } catch {
    return `invalid IANA timezone: ${timeZone}`;
  }
}
