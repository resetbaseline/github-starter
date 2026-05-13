import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { extractActionJsonBlocks, stripActionTags } from "./actions.ts";
import { isUuid, parseCoachMessageBody } from "./parse.ts";
import { modelForSessionType } from "./session-types.ts";

Deno.test("modelForSessionType", () => {
  assertEquals(modelForSessionType("checkin"), "sonnet");
  assertEquals(modelForSessionType("insight"), "sonnet");
  assertEquals(modelForSessionType("gate"), "haiku");
});

Deno.test("parseCoachMessageBody", () => {
  const r = parseCoachMessageBody({
    session_type: "freeform",
    message: "Hi",
    session_id: "550e8400-e29b-41d4-a716-446655440000",
    day_id: "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
  });
  assertEquals(r.ok, true);
});

Deno.test("isUuid rejects bad", () => {
  assertEquals(isUuid("not-a-uuid"), false);
});

Deno.test("extractActionJsonBlocks and stripActionTags", () => {
  const text = 'Hello\n<action>{"type":"add_goal","params":{"text":"X"}}</action>\nTail';
  const blocks = extractActionJsonBlocks(text);
  assertEquals(blocks.length, 1);
  assertEquals((blocks[0] as { type: string }).type, "add_goal");
  assertEquals(stripActionTags(text).includes("<action>"), false);
});
