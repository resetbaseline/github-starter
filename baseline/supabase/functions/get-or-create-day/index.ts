import { corsHeaders, handleCorsPreflightRequest } from "../_shared/cors.ts";
import { createUserClient } from "../_shared/supabase-client.ts";
import { getOrCreateDay } from "./handler.ts";

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

  if (req.method !== "GET" && req.method !== "POST") {
    return json({ data: null, error: { message: "Method not allowed", code: "method_not_allowed" } }, 405);
  }

  let supabase;
  try {
    supabase = createUserClient(req);
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
    const { data: userData, error: authErr } = await supabase.auth.getUser();
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

    const { data: profile, error: profileErr } = await supabase
      .from("users")
      .select("timezone")
      .eq("id", userId)
      .maybeSingle();

    if (profileErr) {
      return json(
        {
          data: null,
          error: { message: profileErr.message, code: profileErr.code, detail: profileErr.details ?? undefined },
        },
        400,
      );
    }

    if (!profile || typeof (profile as { timezone?: unknown }).timezone !== "string") {
      return json(
        {
          data: null,
          error: {
            message: "User profile not found or timezone missing. Complete signup first.",
            code: "profile_missing",
          },
        },
        404,
      );
    }

    const timeZone = (profile as { timezone: string }).timezone;

    const result = await getOrCreateDay(supabase, userId, timeZone, new Date());

    if (result.error) {
      return json({ data: null, error: result.error }, 400);
    }

    return json({ data: result.data, error: null }, 200);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return json({ data: null, error: { message: msg, code: "internal_error" } }, 500);
  }
});
