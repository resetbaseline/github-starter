import { assertThrows } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createUserClient } from "./supabase-client.ts";

Deno.test("createUserClient throws without Bearer Authorization", () => {
  assertThrows(
    () => createUserClient(new Request("https://example.com")),
    Error,
    "Authorization",
  );
});

Deno.test("createUserClient throws on malformed Authorization", () => {
  assertThrows(
    () =>
      createUserClient(
        new Request("https://example.com", {
          headers: { Authorization: "Basic xyz" },
        }),
      ),
    Error,
    "Authorization",
  );
});
