import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { dedupeStrings, mergeStringArrays, monthKey, parseJsonObject } from "./json-utils.ts";

Deno.test("parseJsonObject raw object", () => {
  const v = parseJsonObject(`{"a":1,"b":"x"}`);
  assertEquals(v, { a: 1, b: "x" });
});

Deno.test("parseJsonObject fenced", () => {
  const v = parseJsonObject("```json\n{\"x\": true}\n```");
  assertEquals(v, { x: true });
});

Deno.test("dedupeStrings", () => {
  assertEquals(dedupeStrings(["a", " a", "b", "a"]), ["a", "b"]);
});

Deno.test("mergeStringArrays", () => {
  assertEquals(mergeStringArrays(["a"], ["b", "a"]), ["a", "b"]);
});

Deno.test("monthKey UTC", () => {
  assertEquals(monthKey("2024-03-05T12:00:00.000Z"), "2024-03");
});
