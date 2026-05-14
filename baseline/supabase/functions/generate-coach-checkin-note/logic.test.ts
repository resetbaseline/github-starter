import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { gateCalloutWarranted, tomorrowAdjustmentWarranted } from "./logic.ts";

Deno.test("gateCalloutWarranted by count", () => {
  assertEquals(
    gateCalloutWarranted({ gateTriggersCountOnDay: 5, triggersToday: [] }),
    true,
  );
});

Deno.test("gateCalloutWarranted by usage and classification", () => {
  assertEquals(
    gateCalloutWarranted({
      gateTriggersCountOnDay: 1,
      triggersToday: [{ usage_ratio: 0.9, reason_classification: "plausible" }],
    }),
    true,
  );
  assertEquals(
    gateCalloutWarranted({
      gateTriggersCountOnDay: 1,
      triggersToday: [{ usage_ratio: 0.9, reason_classification: "vague" }],
    }),
    false,
  );
});

Deno.test("tomorrowAdjustmentWarranted", () => {
  assertEquals(tomorrowAdjustmentWarranted({ dayStatus: "light", goalsCount: 3, goalsCompleted: 2 }), true);
  assertEquals(tomorrowAdjustmentWarranted({ dayStatus: "strong", goalsCount: 4, goalsCompleted: 1 }), true);
  assertEquals(tomorrowAdjustmentWarranted({ dayStatus: "strong", goalsCount: 4, goalsCompleted: 3 }), false);
  assertEquals(tomorrowAdjustmentWarranted({ dayStatus: "rest", goalsCount: 4, goalsCompleted: 0 }), false);
});
