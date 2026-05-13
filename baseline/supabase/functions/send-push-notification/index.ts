import { corsHeaders, handleCorsPreflightRequest } from "../_shared/cors.ts";
import { createServiceClient, createUserClient } from "../_shared/supabase-client.ts";
import { sendPushNotification } from "./handler.ts";
import { parseSendPushNotificationBody } from "./parse.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let x = 0;
  for (let i = 0; i < a.length; i++) x |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return x === 0;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return handleCorsPreflightRequest();
  }

  if (req.method !== "POST") {
    return json({ data: null, error: { message: "Method not allowed", code: "method_not_allowed" } }, 405);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const bearer = authHeader.startsWith("Bearer ") ? authHeader.slice(7).trim() : "";

  const serviceKey = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
  const isServiceCall = serviceKey.length > 0 && timingSafeEqual(bearer, serviceKey);

  let db;
  try {
    db = isServiceCall ? createServiceClient() : createUserClient(req);
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
    let targetUserId: string;

    if (isServiceCall) {
      let raw: unknown;
      try {
        raw = await req.json();
      } catch {
        return json({ data: null, error: { message: "Invalid JSON body", code: "invalid_json" } }, 400);
      }
      const parsed = parseSendPushNotificationBody(raw);
      if (!parsed.ok) {
        return json({ data: null, error: { message: parsed.error, code: "validation_error" } }, 400);
      }
      if (!parsed.value.user_id) {
        return json(
          { data: null, error: { message: "user_id is required when using the service role key", code: "validation_error" } },
          400,
        );
      }
      targetUserId = parsed.value.user_id;

      const result = await sendPushNotification(db, targetUserId, parsed.value);
      if (result.error) {
        if (result.error.code === "user_not_found") return json({ data: null, error: result.error }, 404);
        if (result.error.code === "apns_not_configured") return json({ data: null, error: result.error }, 503);
        return json({ data: null, error: result.error }, 400);
      }
      return json({ data: result.data, error: null }, 200);
    }

    const { data: userData, error: authErr } = await db.auth.getUser();
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

    const callerId = userData.user.id;

    let raw: unknown;
    try {
      raw = await req.json();
    } catch {
      return json({ data: null, error: { message: "Invalid JSON body", code: "invalid_json" } }, 400);
    }

    const parsed = parseSendPushNotificationBody(raw);
    if (!parsed.ok) {
      return json({ data: null, error: { message: parsed.error, code: "validation_error" } }, 400);
    }

    if (parsed.value.user_id !== undefined && parsed.value.user_id !== callerId) {
      return json({ data: null, error: { message: "user_id does not match authenticated user", code: "forbidden" } }, 403);
    }

    targetUserId = parsed.value.user_id ?? callerId;

    const result = await sendPushNotification(db, targetUserId, parsed.value);
    if (result.error) {
      if (result.error.code === "user_not_found") return json({ data: null, error: result.error }, 404);
      if (result.error.code === "apns_not_configured") return json({ data: null, error: result.error }, 503);
      return json({ data: null, error: result.error }, 400);
    }

    return json({ data: result.data, error: null }, 200);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return json({ data: null, error: { message: msg, code: "internal_error" } }, 500);
  }
});
