import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { calendarToday, calendarYesterday, validateTimeZone } from "./dates.ts";

Deno.test("calendarToday uses IANA timezone", () => {
  const instant = new Date("2026-06-15T07:00:00.000Z");
  assertEquals(calendarToday(instant, "America/Los_Angeles"), "2026-06-15");
});

Deno.test("calendarYesterday is previous local calendar day", () => {
  assertEquals(calendarYesterday("2026-06-15", "UTC"), "2026-06-14");
});

Deno.test("validateTimeZone rejects empty", () => {
  assertEquals(validateTimeZone(" "), "timezone is empty");
});

Deno.test("validateTimeZone rejects invalid", () => {
  const err = validateTimeZone("Not/A/Real/Zone");
  assertEquals(err !== null, true);
});

Deno.test("validateTimeZone accepts America/Los_Angeles", () => {
  assertEquals(validateTimeZone("America/Los_Angeles"), null);
});
