import type { UpdateCoachMemoryInput } from "./types.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isUuid(s: string): boolean {
  return UUID_RE.test(s.trim());
}

export function parseUpdateCoachMemoryBody(
  raw: unknown,
): { ok: true; value: UpdateCoachMemoryInput } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") return { ok: false, error: "Body must be a JSON object" };
  const o = raw as Record<string, unknown>;

  if (typeof o.user_id !== "string" || !isUuid(o.user_id)) {
    return { ok: false, error: "user_id must be a valid UUID" };
  }
  if (typeof o.session_id !== "string" || !isUuid(o.session_id)) {
    return { ok: false, error: "session_id must be a valid UUID" };
  }

  return { ok: true, value: { user_id: o.user_id.trim(), session_id: o.session_id.trim() } };
}
