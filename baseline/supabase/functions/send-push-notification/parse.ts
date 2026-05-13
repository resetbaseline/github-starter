import type { NotificationType, SendPushNotificationInput } from "./types.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const NOTIFICATION_TYPES = new Set<string>([
  "checkin_reminder",
  "morning",
  "timeblock_start",
  "streak_alert",
  "reengagement",
  "coach_nudge",
  "planning_reminder",
]);

function isUuid(s: string): boolean {
  return UUID_RE.test(s.trim());
}

export function parseSendPushNotificationBody(
  raw: unknown,
): { ok: true; value: SendPushNotificationInput } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") return { ok: false, error: "Body must be a JSON object" };
  const o = raw as Record<string, unknown>;

  if (typeof o.title !== "string" || o.title.trim().length === 0) {
    return { ok: false, error: "title is required and must be a non-empty string" };
  }
  if (o.title.length > 200) return { ok: false, error: "title must be at most 200 characters" };

  if (typeof o.body !== "string" || o.body.trim().length === 0) {
    return { ok: false, error: "body is required and must be a non-empty string" };
  }
  if (o.body.length > 4000) return { ok: false, error: "body must be at most 4000 characters" };

  let data: Record<string, unknown> | undefined;
  if (o.data !== undefined && o.data !== null) {
    if (typeof o.data !== "object" || Array.isArray(o.data)) {
      return { ok: false, error: "data must be a JSON object when provided" };
    }
    data = o.data as Record<string, unknown>;
  }

  let notification_type: NotificationType | undefined;
  if (o.notification_type !== undefined && o.notification_type !== null) {
    if (typeof o.notification_type !== "string" || !NOTIFICATION_TYPES.has(o.notification_type)) {
      return { ok: false, error: "notification_type must be a valid notification_type enum value" };
    }
    notification_type = o.notification_type as NotificationType;
  }

  let user_id: string | undefined;
  if (o.user_id !== undefined && o.user_id !== null) {
    if (typeof o.user_id !== "string" || !isUuid(o.user_id)) {
      return { ok: false, error: "user_id must be a valid UUID when provided" };
    }
    user_id = o.user_id.trim();
  }

  let badge: number | undefined;
  if (o.badge !== undefined && o.badge !== null) {
    if (typeof o.badge !== "number" || !Number.isFinite(o.badge) || o.badge < 0 || o.badge > 999999) {
      return { ok: false, error: "badge must be a non-negative finite number when provided" };
    }
    badge = Math.floor(o.badge);
  }

  let sound: string | null | undefined;
  if (o.sound !== undefined) {
    if (o.sound === null) sound = null;
    else if (typeof o.sound === "string" && o.sound.length <= 64) sound = o.sound;
    else return { ok: false, error: "sound must be null or a string of at most 64 characters" };
  }

  return {
    ok: true,
    value: {
      title: o.title.trim(),
      body: o.body.trim(),
      data,
      notification_type,
      user_id,
      badge,
      sound,
    },
  };
}
