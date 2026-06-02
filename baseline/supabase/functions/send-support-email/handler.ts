import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export type SendSupportEmailInput = {
  userId: string;
  category: string;
  message: string;
  screenshotBase64?: string;
  deviceInfo: unknown;
  appVersion: string;
  resolvedByBot: boolean;
};

type ParseResult =
  | { ok: true; value: SendSupportEmailInput }
  | { ok: false; error: string };

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function requireString(obj: Record<string, unknown>, key: string): string | null {
  const v = obj[key];
  if (typeof v !== "string" || v.trim() === "") return null;
  return v.trim();
}

export function parseSendSupportEmailBody(raw: unknown): ParseResult {
  if (!isRecord(raw)) {
    return { ok: false, error: "Request body must be a JSON object" };
  }

  const userId = requireString(raw, "userId");
  const category = requireString(raw, "category");
  const message = requireString(raw, "message");
  const appVersion = requireString(raw, "appVersion");

  if (!userId) return { ok: false, error: "userId is required" };
  if (!category) return { ok: false, error: "category is required" };
  if (!message) return { ok: false, error: "message is required" };
  if (!appVersion) return { ok: false, error: "appVersion is required" };
  if (!("deviceInfo" in raw)) return { ok: false, error: "deviceInfo is required" };
  if (typeof raw.resolvedByBot !== "boolean") {
    return { ok: false, error: "resolvedByBot must be a boolean" };
  }

  let screenshotBase64: string | undefined;
  if (raw.screenshotBase64 !== undefined && raw.screenshotBase64 !== null) {
    if (typeof raw.screenshotBase64 !== "string" || raw.screenshotBase64.trim() === "") {
      return { ok: false, error: "screenshotBase64 must be a non-empty string when provided" };
    }
    screenshotBase64 = raw.screenshotBase64.trim();
  }

  return {
    ok: true,
    value: {
      userId,
      category,
      message,
      screenshotBase64,
      deviceInfo: raw.deviceInfo,
      appVersion,
      resolvedByBot: raw.resolvedByBot,
    },
  };
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function buildEmailHtml(input: SendSupportEmailInput): string {
  const deviceInfoJson = JSON.stringify(input.deviceInfo ?? null, null, 2);
  return `
    <h2>Baseline Support Ticket</h2>
    <p><strong>Category:</strong> ${escapeHtml(input.category)}</p>
    <p><strong>Message:</strong></p>
    <pre style="white-space: pre-wrap; font-family: sans-serif;">${escapeHtml(input.message)}</pre>
    <p><strong>Device info:</strong></p>
    <pre style="white-space: pre-wrap; font-family: monospace;">${escapeHtml(deviceInfoJson)}</pre>
    <p><strong>App version:</strong> ${escapeHtml(input.appVersion)}</p>
    <p><strong>User ID:</strong> ${escapeHtml(input.userId)}</p>
    <p><strong>Resolved by bot:</strong> ${input.resolvedByBot ? "yes" : "no"}</p>
  `.trim();
}

type EmailResult = { sent: boolean; error?: string };

async function sendResendEmail(input: SendSupportEmailInput): Promise<EmailResult> {
  const apiKey = Deno.env.get("RESEND_API_KEY")?.trim();
  if (!apiKey) {
    console.error("send-support-email: RESEND_API_KEY is not set");
    return { sent: false, error: "RESEND_API_KEY is not set" };
  }

  const payload: Record<string, unknown> = {
    from: "support@resetbaseline.com",
    to: "support@resetbaseline.com",
    subject: `[Baseline Support] ${input.category} — ${input.userId.slice(0, 8)}`,
    html: buildEmailHtml(input),
  };

  if (input.screenshotBase64) {
    payload.attachments = [
      {
        filename: "screenshot.png",
        content: input.screenshotBase64,
      },
    ];
  }

  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const body = await res.text();
      console.error("send-support-email: Resend API error", res.status, body);
      return { sent: false, error: `Resend API error ${res.status}: ${body.slice(0, 300)}` };
    }
    return { sent: true };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("send-support-email: Resend request failed", msg);
    return { sent: false, error: msg };
  }
}

export async function sendSupportEmail(
  db: SupabaseClient,
  input: SendSupportEmailInput,
): Promise<
  | { success: true; email_sent: boolean; email_error?: string }
  | { success: false; message: string }
> {
  const { error: insertErr } = await db.from("support_tickets").insert({
    user_id: input.userId,
    category: input.category,
    message: input.message,
    resolved_by_bot: input.resolvedByBot,
    device_info: input.deviceInfo,
    app_version: input.appVersion,
  });

  if (insertErr) {
    return { success: false, message: insertErr.message };
  }

  // The ticket is persisted regardless, so we keep success: true even if the
  // email fails — but we surface the email outcome so a failed delivery is not
  // silently swallowed (it would otherwise never reach the support inbox).
  const email = await sendResendEmail(input);

  return { success: true, email_sent: email.sent, email_error: email.error };
}
