import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  addCalendarDays,
  classifyDayResult,
  isPerfectDay,
  outcomeMap,
  parseProcessCheckinBody,
  validateGoalCoverage,
} from "./logic.ts";

Deno.test("addCalendarDays rolls month boundaries", () => {
  assertEquals(addCalendarDays("2026-01-31", 1), "2026-02-01");
});

Deno.test("classify skipped when no goals and no focus", () => {
  assertEquals(
    classifyDayResult({
      goals: [],
      outcomes: new Map(),
      reflectionCount: 0,
      focusMinutesTotal: 0,
    }),
    "skipped",
  );
});

Deno.test("classify solid when NN incomplete but negotiable completed", () => {
  const goals = [
    { id: "g1", is_non_negotiable: true },
    { id: "g2", is_non_negotiable: false },
  ];
  const outcomes = outcomeMap([
    { goal_id: "g1", completed: false },
    { goal_id: "g2", completed: true },
  ]);
  assertEquals(
    classifyDayResult({
      goals,
      outcomes,
      reflectionCount: 2,
      focusMinutesTotal: 10,
    }),
    "solid",
  );
});

Deno.test("classify strong when all NN complete and reflections present", () => {
  const goals = [{ id: "g1", is_non_negotiable: true }];
  const outcomes = outcomeMap([{ goal_id: "g1", completed: true }]);
  assertEquals(
    classifyDayResult({
      goals,
      outcomes,
      reflectionCount: 1,
      focusMinutesTotal: 5,
    }),
    "strong",
  );
});

Deno.test("classify light when nothing completed but day has goals", () => {
  const goals = [
    { id: "g1", is_non_negotiable: true },
    { id: "g2", is_non_negotiable: false },
  ];
  const outcomes = outcomeMap([
    { goal_id: "g1", completed: false },
    { goal_id: "g2", completed: false },
  ]);
  assertEquals(
    classifyDayResult({
      goals,
      outcomes,
      reflectionCount: 0,
      focusMinutesTotal: 5,
    }),
    "light",
  );
});

Deno.test("validateGoalCoverage requires all goals", () => {
  const err = validateGoalCoverage(
    [{ id: "a", is_non_negotiable: false }, { id: "b", is_non_negotiable: false }],
    [{ goal_id: "a", completed: true }],
  );
  assertEquals(err?.includes("b"), true);
});

Deno.test("isPerfectDay requires all goals completed + reflection + focus", () => {
  const goals = [{ id: "g1", is_non_negotiable: true }, { id: "g2", is_non_negotiable: false }];
  const outcomes = outcomeMap([{ goal_id: "g1", completed: true }, { goal_id: "g2", completed: false }]);
  assertEquals(
    isPerfectDay({
      goals,
      outcomes,
      reflectionCount: 1,
      focusMinutesTotal: 5,
    }),
    false,
  );
});

Deno.test("parseProcessCheckinBody happy path", () => {
  const r = parseProcessCheckinBody({
    day_id: "550e8400-e29b-41d4-a716-446655440000",
    goal_outcomes: [{ goal_id: "550e8400-e29b-41d4-a716-446655440001", completed: true }],
    reflection_answers: [{ question_text: "Q", answer: "A", category: "universal" }],
    tomorrow_intention: "Run",
    tomorrow_timeblocks: [{ title: "Deep work", start_time: "09:00", end_time: "10:00", color_hex: "7C5CBF" }],
    streak_freeze_used: false,
  });
  assertEquals(r.ok, true);
  if (r.ok) {
    assertEquals(r.value.rest_day, false);
    assertEquals(r.value.tomorrow_timeblocks[0].start_time, "09:00:00");
  }
});

Deno.test("parseProcessCheckinBody rest_day true", () => {
  const r = parseProcessCheckinBody({
    day_id: "550e8400-e29b-41d4-a716-446655440000",
    rest_day: true,
    goal_outcomes: [],
    reflection_answers: [],
    tomorrow_intention: null,
    tomorrow_timeblocks: [],
    streak_freeze_used: false,
  });
  assertEquals(r.ok, true);
  if (r.ok) assertEquals(r.value.rest_day, true);
});

Deno.test("parseProcessCheckinBody rejects bad boolean", () => {
  const r = parseProcessCheckinBody({
    day_id: "550e8400-e29b-41d4-a716-446655440000",
    goal_outcomes: [],
    reflection_answers: [],
    tomorrow_intention: null,
    tomorrow_timeblocks: [],
    streak_freeze_used: "no",
  });
  assertEquals(r.ok, false);
});

Deno.test("parseProcessCheckinBody rejects non-boolean rest_day", () => {
  const r = parseProcessCheckinBody({
    day_id: "550e8400-e29b-41d4-a716-446655440000",
    rest_day: "yes",
    goal_outcomes: [],
    reflection_answers: [],
    tomorrow_intention: null,
    tomorrow_timeblocks: [],
    streak_freeze_used: false,
  });
  assertEquals(r.ok, false);
});
