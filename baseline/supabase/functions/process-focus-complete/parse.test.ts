import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseProcessFocusCompleteBody } from "./handler.ts";

Deno.test("parses duration and optional client session id", () => {
  const r = parseProcessFocusCompleteBody({
    durationMinutes: 25,
    clientSessionId: "11111111-1111-1111-1111-111111111111",
  });
  assertEquals(r.ok, true);
  if (r.ok) {
    assertEquals(r.value.duration_minutes, 25);
    assertEquals(r.value.client_session_id, "11111111-1111-1111-1111-111111111111");
  }
});

Deno.test("client session id is optional", () => {
  const r = parseProcessFocusCompleteBody({ duration_minutes: 10 });
  assertEquals(r.ok, true);
  if (r.ok) {
    assertEquals(r.value.client_session_id, undefined);
  }
});

Deno.test("empty client session id is treated as absent", () => {
  const r = parseProcessFocusCompleteBody({ duration_minutes: 10, client_session_id: "" });
  assertEquals(r.ok, true);
  if (r.ok) {
    assertEquals(r.value.client_session_id, undefined);
  }
});

Deno.test("rejects non-numeric duration", () => {
  const r = parseProcessFocusCompleteBody({ duration_minutes: "abc" });
  assertEquals(r.ok, false);
});
