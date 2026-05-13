import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseGateValidateBody } from "./parse.ts";

Deno.test("parseGateValidateBody happy path", () => {
  const r = parseGateValidateBody({
    app_bundle_id: "com.apple.Safari",
    app_name: "Safari",
    trigger_source: "gate",
    stated_reason: "Need to look up a doc",
    active_non_negotiable: "Deep work block",
  });
  assertEquals(r.ok, true);
});

Deno.test("parseGateValidateBody rejects missing bundle id", () => {
  const r = parseGateValidateBody({
    app_name: "Safari",
    trigger_source: "gate",
    stated_reason: "x",
  });
  assertEquals(r.ok, false);
});
