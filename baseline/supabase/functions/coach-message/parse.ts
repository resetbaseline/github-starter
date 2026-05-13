import type { CoachMessageInput, CoachSessionType } from "./types.ts";

const SESSION_TYPES = new Set<CoachSessionType>(["checkin", "stuck", "planning", "freeform", "insight", "gate"]);

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isUuid(s: string): boolean {
  return UUID_RE.test(s.trim());
}

export function parseCoachMessageBody(raw: unknown): { ok: true; value: CoachMessageInput } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") return { ok: false, error: "Body must be a JSON object" };
  const o = raw as Record<string, unknown>;

  if (typeof o.session_type !== "string" || !SESSION_TYPES.has(o.session_type as CoachSessionType)) {
    return { ok: false, error: "session_type must be checkin | stuck | planning | freeform | insight | gate" };
  }
  if (typeof o.message !== "string" || o.message.trim() === "") {
    return { ok: false, error: "message is required" };
  }
  if (typeof o.session_id !== "string" || !isUuid(o.session_id)) {
    return { ok: false, error: "session_id must be a valid UUID" };
  }
  if (typeof o.day_id !== "string" || !isUuid(o.day_id)) {
    return { ok: false, error: "day_id must be a valid UUID" };
  }

  return {
    ok: true,
    value: {
      session_type: o.session_type as CoachSessionType,
      message: o.message,
      session_id: o.session_id.trim(),
      day_id: o.day_id.trim(),
    },
  };
}
