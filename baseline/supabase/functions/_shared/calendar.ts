import { formatInTimeZone } from "https://esm.sh/date-fns-tz@3.2.0";

/** Calendar date YYYY-MM-DD for `instant` interpreted in `timeZone` (IANA). */
export function calendarToday(instant: Date, timeZone: string): string {
  return formatInTimeZone(instant, timeZone, "yyyy-MM-dd");
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
