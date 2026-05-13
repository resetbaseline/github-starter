import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseGateResolveBody } from "./parse.ts";

Deno.test("parseGateResolveBody happy path", () => {
  const r = parseGateResolveBody({
    gate_trigger_id: "550e8400-e29b-41d4-a716-446655440000",
    time_used_seconds: 120,
    outcome: "timed_access",
  });
  assertEquals(r.ok, true);
});

Deno.test("parseGateResolveBody rejects negative time", () => {
  const r = parseGateResolveBody({
    gate_trigger_id: "550e8400-e29b-41d4-a716-446655440000",
    time_used_seconds: -1,
    outcome: "dismissed",
  });
  assertEquals(r.ok, false);
});
