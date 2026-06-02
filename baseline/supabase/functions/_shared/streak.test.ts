import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { calendarDaysBetween, computeStreakTransition } from "./streak.ts";

Deno.test("calendarDaysBetween counts whole days across month boundaries", () => {
  assertEquals(calendarDaysBetween("2026-01-01", "2026-01-02"), 1);
  assertEquals(calendarDaysBetween("2026-01-31", "2026-02-01"), 1);
  assertEquals(calendarDaysBetween("2026-02-28", "2026-03-01"), 1);
  assertEquals(calendarDaysBetween("2026-01-01", "2026-01-01"), 0);
});

Deno.test("first ever activity starts the streak at 1", () => {
  const t = computeStreakTransition({
    lastUpdatedDate: null,
    currentCount: 0,
    startDate: null,
    activityDate: "2026-06-01",
    freezeCount: 0,
  });
  assertEquals(t.newCount, 1);
  assertEquals(t.newStartDate, "2026-06-01");
  assertEquals(t.freezeDelta, 0);
  assertEquals(t.bridged, false);
});

Deno.test("consecutive day increments the count", () => {
  const t = computeStreakTransition({
    lastUpdatedDate: "2026-06-01",
    currentCount: 3,
    startDate: "2026-05-30",
    activityDate: "2026-06-02",
    freezeCount: 0,
  });
  assertEquals(t.newCount, 4);
  assertEquals(t.newStartDate, "2026-05-30");
  assertEquals(t.bridged, false);
});

Deno.test("single missed day with a freeze bridges and consumes the freeze", () => {
  const t = computeStreakTransition({
    lastUpdatedDate: "2026-06-01",
    currentCount: 5,
    startDate: "2026-05-28",
    activityDate: "2026-06-03", // missed 06-02
    freezeCount: 2,
  });
  assertEquals(t.newCount, 6);
  assertEquals(t.bridged, true);
  assertEquals(t.freezeConsumed, 1);
  assertEquals(t.freezeDelta, -1);
  assertEquals(t.newStartDate, "2026-05-28");
});

Deno.test("single missed day with no freeze resets to 1", () => {
  const t = computeStreakTransition({
    lastUpdatedDate: "2026-06-01",
    currentCount: 5,
    startDate: "2026-05-28",
    activityDate: "2026-06-03",
    freezeCount: 0,
  });
  assertEquals(t.newCount, 1);
  assertEquals(t.bridged, false);
  assertEquals(t.freezeConsumed, 0);
  assertEquals(t.newStartDate, "2026-06-03");
});

Deno.test("two or more missed days always resets, even with freezes", () => {
  const t = computeStreakTransition({
    lastUpdatedDate: "2026-06-01",
    currentCount: 10,
    startDate: "2026-05-20",
    activityDate: "2026-06-04", // missed 06-02 and 06-03
    freezeCount: 5,
  });
  assertEquals(t.newCount, 1);
  assertEquals(t.bridged, false);
  assertEquals(t.freezeConsumed, 0);
  assertEquals(t.freezeDelta, 0);
  assertEquals(t.newStartDate, "2026-06-04");
});

Deno.test("reaching a 7-day multiple grants a freeze", () => {
  const t = computeStreakTransition({
    lastUpdatedDate: "2026-06-06",
    currentCount: 6,
    startDate: "2026-06-01",
    activityDate: "2026-06-07",
    freezeCount: 0,
  });
  assertEquals(t.newCount, 7);
  assertEquals(t.freezeDelta, 1);
});

Deno.test("bridging onto a 7-day multiple nets zero freeze change", () => {
  const t = computeStreakTransition({
    lastUpdatedDate: "2026-06-05",
    currentCount: 6,
    startDate: "2026-06-01",
    activityDate: "2026-06-07", // missed 06-06, bridge to 7
    freezeCount: 1,
  });
  assertEquals(t.newCount, 7);
  assertEquals(t.bridged, true);
  assertEquals(t.freezeConsumed, 1);
  assertEquals(t.freezeDelta, 0); // -1 consumed + 1 granted
});

Deno.test("no milestone grant when the streak resets onto a multiple of 7", () => {
  // A reset always lands on 1, so it can never trigger a milestone grant.
  const t = computeStreakTransition({
    lastUpdatedDate: "2026-06-01",
    currentCount: 6,
    startDate: "2026-06-01",
    activityDate: "2026-06-10",
    freezeCount: 0,
  });
  assertEquals(t.newCount, 1);
  assertEquals(t.freezeDelta, 0);
});
