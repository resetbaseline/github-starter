import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseProcessAnchorCompleteBody } from "./handler.ts";

Deno.test("parseProcessAnchorCompleteBody accepts anchor_id", () => {
  const r = parseProcessAnchorCompleteBody({ anchor_id: "abc" });
  assert(r.ok);
  if (r.ok) assertEquals(r.value.anchor_id, "abc");
});

Deno.test("parseProcessAnchorCompleteBody accepts anchorId", () => {
  const r = parseProcessAnchorCompleteBody({ anchorId: "def" });
  assert(r.ok);
  if (r.ok) assertEquals(r.value.anchor_id, "def");
});

Deno.test("parseProcessAnchorCompleteBody rejects missing id", () => {
  const r = parseProcessAnchorCompleteBody({});
  assert(!r.ok);
});
