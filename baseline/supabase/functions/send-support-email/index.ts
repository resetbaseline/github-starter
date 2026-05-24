import { corsHeaders, handleCorsPreflightRequest } from "../_shared/cors.ts";
import { createUserClient } from "../_shared/supabase-client.ts";
import { parseSendSupportEmailBody, sendSupportEmail } from "./handler.ts";

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
    return json({ success: false, message: "Method not allowed" }, 405);
  }

  let db;
  try {
    db = createUserClient(req);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const unauthorized = msg.includes("Authorization") || msg.includes("Bearer");
    return json({ success: false, message: msg }, unauthorized ? 401 : 500);
  }

  try {
    const { data: userData, error: authErr } = await db.auth.getUser();
    if (authErr || !userData?.user) {
      return json(
        { success: false, message: authErr?.message ?? "Invalid or expired JWT" },
        401,
      );
    }

    let raw: unknown;
    try {
      raw = await req.json();
    } catch {
      return json({ success: false, message: "Invalid JSON body" }, 400);
    }

    const parsed = parseSendSupportEmailBody(raw);
    if (!parsed.ok) {
      return json({ success: false, message: parsed.error }, 400);
    }

    if (parsed.value.userId !== userData.user.id) {
      return json({ success: false, message: "userId does not match authenticated user" }, 403);
    }

    const result = await sendSupportEmail(db, parsed.value);
    if (!result.success) {
      return json({ success: false, message: result.message }, 400);
    }

    return json({ success: true }, 200);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return json({ success: false, message: msg }, 500);
  }
});
