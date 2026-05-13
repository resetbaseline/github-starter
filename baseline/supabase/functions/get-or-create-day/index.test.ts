import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { corsHeaders } from "../_shared/cors.ts";

Deno.test("OPTIONS preflight includes Baseline CORS headers", () => {
  assertEquals(corsHeaders["Access-Control-Allow-Methods"], "POST, GET, OPTIONS");
  assertEquals(corsHeaders["Access-Control-Allow-Headers"].includes("Authorization"), true);
});
