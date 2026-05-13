import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  applyEscalation,
  applyMismatchReduction,
  baseGrantSeconds,
  firstWord,
  parseClassification,
  sanitizeLikeFragment,
  wordCount,
} from "./grant.ts";

Deno.test("baseGrantSeconds", () => {
  assertEquals(baseGrantSeconds("specific_legitimate"), 600);
  assertEquals(baseGrantSeconds("plausible"), 300);
  assertEquals(baseGrantSeconds("vague"), 240);
  assertEquals(baseGrantSeconds("low_legitimacy"), 180);
});

Deno.test("applyEscalation tiers", () => {
  assertEquals(applyEscalation(600, 3), 600);
  assertEquals(applyEscalation(600, 4), 540);
  assertEquals(applyEscalation(600, 5), 540);
  assertEquals(applyEscalation(600, 6), 300);
  assertEquals(applyEscalation(600, 7), 300);
  assertEquals(applyEscalation(600, 8), 180);
  assertEquals(applyEscalation(600, 20), 180);
});

Deno.test("applyMismatchReduction", () => {
  assertEquals(applyMismatchReduction(300, 2), 300);
  assertEquals(applyMismatchReduction(300, 3), 240);
});

Deno.test("parseClassification strict token", () => {
  assertEquals(parseClassification("plausible"), "plausible");
  assertEquals(parseClassification("specific_legitimate\n"), "specific_legitimate");
});

Deno.test("parseClassification falls back to vague", () => {
  assertEquals(parseClassification("unknown-label"), "vague");
});

Deno.test("firstWord and sanitizeLikeFragment", () => {
  assertEquals(firstWord("  hello world "), "hello");
  assertEquals(sanitizeLikeFragment("50%_done"), "50done");
});

Deno.test("wordCount", () => {
  assertEquals(wordCount("one two three"), 3);
  assertEquals(wordCount("   "), 0);
});
