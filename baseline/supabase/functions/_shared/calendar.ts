import { formatInTimeZone, fromZonedTime } from "https://esm.sh/date-fns-tz@3.2.0";

/** Calendar date YYYY-MM-DD for `instant` interpreted in `timeZone` (IANA). */
export function calendarToday(instant: Date, timeZone: string): string {
  return formatInTimeZone(instant, timeZone, "yyyy-MM-dd");
}

/** UTC instant (ISO string) for local midnight of `calendarDateYmd` in `timeZone`. */
export function startOfCalendarDayUtcIso(calendarDateYmd: string, timeZone: string): string {
  const d = fromZonedTime(`${calendarDateYmd} 00:00:00`, timeZone);
  return d.toISOString();
}

/** Add calendar days to a `YYYY-MM-DD` date (UTC date arithmetic). */
export function addCalendarDays(isoDate: string, delta: number): string {
  const [y, m, d] = isoDate.split("-").map(Number);
  const utc = Date.UTC(y, m - 1, d + delta);
  return new Date(utc).toISOString().slice(0, 10);
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
