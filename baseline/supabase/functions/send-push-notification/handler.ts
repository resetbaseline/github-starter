import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { apnsConfigured, sendApnsAlert } from "./apns.ts";
import type {
  SendPushDeviceResult,
  SendPushNotificationError,
  SendPushNotificationInput,
  SendPushNotificationSuccess,
} from "./types.ts";

function apnsTopic(): string {
  const t = Deno.env.get("APNS_BUNDLE_ID")?.trim();
  if (!t) throw new Error("APNS_BUNDLE_ID is not set");
  return t;
}

export async function sendPushNotification(
  db: SupabaseClient,
  targetUserId: string,
  input: SendPushNotificationInput,
): Promise<{ data: SendPushNotificationSuccess | null; error: SendPushNotificationError | null }> {
  const { data: urow, error: uErr } = await db.from("users").select("notifications_enabled").eq("id", targetUserId).maybeSingle();
  if (uErr) {
    return { data: null, error: { message: uErr.message, code: uErr.code, detail: uErr.details ?? undefined } };
  }
  if (!urow) {
    return { data: null, error: { message: "User not found", code: "user_not_found" } };
  }
  if (!(urow as { notifications_enabled?: boolean }).notifications_enabled) {
    return {
      data: { sent: 0, failed: 0, skipped: "notifications_disabled", results: [] },
      error: null,
    };
  }

  const { data: tokens, error: tErr } = await db
    .from("notification_tokens")
    .select("id, apns_token")
    .eq("user_id", targetUserId);

  if (tErr) {
    return { data: null, error: { message: tErr.message, code: tErr.code, detail: tErr.details ?? undefined } };
  }

  const rows = (tokens ?? []) as { id: string; apns_token: string }[];
  if (rows.length === 0) {
    return { data: { sent: 0, failed: 0, skipped: "no_tokens", results: [] }, error: null };
  }

  if (!apnsConfigured()) {
    return {
      data: null,
      error: {
        message:
          "APNs is not configured (set APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, and APNS_SIGNING_KEY or APNS_PRIVATE_KEY). " +
            "Optional: APNS_USE_SANDBOX=true for the sandbox endpoint.",
        code: "apns_not_configured",
      },
    };
  }

  let topic: string;
  try {
    topic = apnsTopic();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { data: null, error: { message: msg, code: "apns_not_configured" } };
  }

  const baselinePayload: Record<string, unknown> = {};
  if (input.notification_type) baselinePayload.notification_type = input.notification_type;
  if (input.data && Object.keys(input.data).length > 0) baselinePayload.client = input.data;

  const results: SendPushDeviceResult[] = [];
  let sent = 0;
  let failed = 0;

  for (const row of rows) {
    const r = await sendApnsAlert({
      deviceToken: row.apns_token.trim(),
      title: input.title,
      body: input.body,
      topic,
      badge: input.badge,
      sound: input.sound,
      baselinePayload: Object.keys(baselinePayload).length ? baselinePayload : undefined,
    });

    if (r.ok) {
      sent += 1;
      results.push({ token_id: row.id, ok: true, status: r.status });
      continue;
    }

    failed += 1;
    if (r.unregistered) {
      const { error: delErr } = await db.from("notification_tokens").delete().eq("id", row.id);
      if (delErr) {
        results.push({
          token_id: row.id,
          ok: false,
          status: r.status,
          unregistered: true,
          error: `${r.error ?? "unregistered"}; delete_failed: ${delErr.message}`,
        });
      } else {
        results.push({
          token_id: row.id,
          ok: false,
          status: r.status,
          unregistered: true,
          error: r.error ?? "unregistered",
        });
      }
    } else {
      results.push({ token_id: row.id, ok: false, status: r.status, error: r.error });
    }
  }

  return { data: { sent, failed, results }, error: null };
}
