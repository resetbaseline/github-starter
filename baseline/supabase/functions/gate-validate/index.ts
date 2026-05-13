import { corsHeaders, handleCorsPreflightRequest } from "../_shared/cors.ts";
import { createServiceClient, createUserClient } from "../_shared/supabase-client.ts";
import { gateValidate } from "./handler.ts";
import { parseGateValidateBody } from "./parse.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return handleCorsPreflightRequest();
  }

  if (req.method !== "POST") {
    return json({ data: null, error: { message: "Method not allowed", code: "method_not_allowed" } }, 405);
  }

  let userSb;
  let serviceSb;
  try {
    userSb = createUserClient(req);
    serviceSb = createServiceClient();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const unauthorized = msg.includes("Authorization") || msg.includes("Bearer");
    return json(
      {
        data: null,
        error: { message: msg, code: unauthorized ? "unauthorized" : "configuration_error" },
      },
      unauthorized ? 401 : 500,
    );
  }

  try {
    const { data: userData, error: authErr } = await userSb.auth.getUser();
    if (authErr || !userData?.user) {
      return json(
        {
          data: null,
          error: {
            message: authErr?.message ?? "Invalid or expired JWT",
            code: "invalid_jwt",
            detail: authErr?.name,
          },
        },
        401,
      );
    }

    const userId = userData.user.id;

    let raw: unknown;
    try {
      raw = await req.json();
    } catch {
      return json({ data: null, error: { message: "Invalid JSON body", code: "invalid_json" } }, 400);
    }

    const parsed = parseGateValidateBody(raw);
    if (!parsed.ok) {
      return json({ data: null, error: { message: parsed.error, code: "validation_error" } }, 400);
    }

    const result = await gateValidate(userSb, serviceSb, userId, parsed.value);

    if (result.error) {
      return json({ data: null, error: result.error }, 400);
    }

    return json({ data: result.data, error: null }, 200);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    let anthropic: unknown = null;
    try {
      anthropic = JSON.parse(msg);
    } catch {
      // not JSON
    }
    if (anthropic && typeof anthropic === "object" && (anthropic as { type?: string }).type === "anthropic_error") {
      return json({ data: null, error: { message: msg, code: "anthropic_error" } }, 502);
    }
    return json({ data: null, error: { message: msg, code: "internal_error" } }, 500);
  }
});
