import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { computeUsageRatio, isValidOutcome, shouldFlagMismatch } from "./logic.ts";

Deno.test("computeUsageRatio divide by zero returns null", () => {
  assertEquals(computeUsageRatio(10, 0), null);
  assertEquals(computeUsageRatio(10, null), null);
});

Deno.test("computeUsageRatio normal", () => {
  assertEquals(computeUsageRatio(300, 600), 0.5);
  assertEquals(computeUsageRatio(500, 600), 500 / 600);
});

Deno.test("shouldFlagMismatch when high usage and high-trust classification", () => {
  assertEquals(
    shouldFlagMismatch({ usage_ratio: 0.81, reason_classification: "specific_legitimate" }),
    true,
  );
  assertEquals(
    shouldFlagMismatch({ usage_ratio: 0.81, reason_classification: "plausible" }),
    true,
  );
  assertEquals(
    shouldFlagMismatch({ usage_ratio: 0.81, reason_classification: "vague" }),
    false,
  );
  assertEquals(
    shouldFlagMismatch({ usage_ratio: 0.8, reason_classification: "plausible" }),
    false,
  );
  assertEquals(
    shouldFlagMismatch({ usage_ratio: null, reason_classification: "plausible" }),
    false,
  );
});

Deno.test("isValidOutcome", () => {
  assertEquals(isValidOutcome("dismissed"), true);
  assertEquals(isValidOutcome("nope"), false);
});
