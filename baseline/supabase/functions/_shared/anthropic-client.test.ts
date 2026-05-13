import { assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { callHaiku, callSonnet } from "./anthropic-client.ts";

Deno.test("callHaiku throws descriptive error when ANTHROPIC_API_KEY missing", async () => {
  const prev = Deno.env.get("ANTHROPIC_API_KEY");
  Deno.env.delete("ANTHROPIC_API_KEY");
  try {
    await assertRejects(
      () => callHaiku("system", [{ role: "user", content: "hi" }], 16),
      Error,
      "ANTHROPIC_API_KEY",
    );
  } finally {
    if (prev !== undefined) Deno.env.set("ANTHROPIC_API_KEY", prev);
  }
});

Deno.test("callSonnet throws descriptive error when ANTHROPIC_API_KEY missing", async () => {
  const prev = Deno.env.get("ANTHROPIC_API_KEY");
  Deno.env.delete("ANTHROPIC_API_KEY");
  try {
    await assertRejects(
      () => callSonnet("system", [{ role: "user", content: "hi" }], 16),
      Error,
      "ANTHROPIC_API_KEY",
    );
  } finally {
    if (prev !== undefined) Deno.env.set("ANTHROPIC_API_KEY", prev);
  }
});
