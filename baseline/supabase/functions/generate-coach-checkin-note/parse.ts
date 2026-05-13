import type { GenerateCheckinNoteInput } from "./types.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isUuid(s: string): boolean {
  return UUID_RE.test(s.trim());
}

export function parseGenerateCheckinNoteBody(
  raw: unknown,
): { ok: true; value: GenerateCheckinNoteInput } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") return { ok: false, error: "Body must be a JSON object" };
  const o = raw as Record<string, unknown>;

  if (typeof o.day_id !== "string" || !isUuid(o.day_id)) {
    return { ok: false, error: "day_id must be a valid UUID" };
  }

  let user_id: string | undefined;
  if (o.user_id !== undefined && o.user_id !== null) {
    if (typeof o.user_id !== "string" || !isUuid(o.user_id)) {
      return { ok: false, error: "user_id must be a valid UUID when provided" };
    }
    user_id = o.user_id.trim();
  }

  return { ok: true, value: { day_id: o.day_id.trim(), user_id } };
}
