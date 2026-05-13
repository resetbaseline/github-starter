import type { GenerateIdentityMirrorInput } from "./types.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const YMD_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

function isUuid(s: string): boolean {
  return UUID_RE.test(s.trim());
}

function isValidYmd(s: string): boolean {
  const m = YMD_RE.exec(s.trim());
  if (!m) return false;
  const y = Number(m[1]);
  const mo = Number(m[2]);
  const d = Number(m[3]);
  const dt = new Date(Date.UTC(y, mo - 1, d));
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === mo - 1 && dt.getUTCDate() === d;
}

export function parseGenerateIdentityMirrorBody(
  raw: unknown,
): { ok: true; value: GenerateIdentityMirrorInput } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") return { ok: false, error: "Body must be a JSON object" };
  const o = raw as Record<string, unknown>;

  let user_id: string | undefined;
  if (o.user_id !== undefined && o.user_id !== null) {
    if (typeof o.user_id !== "string" || !isUuid(o.user_id)) {
      return { ok: false, error: "user_id must be a valid UUID when provided" };
    }
    user_id = o.user_id.trim();
  }

  let month_start: string | undefined;
  if (o.month_start !== undefined && o.month_start !== null) {
    if (typeof o.month_start !== "string") return { ok: false, error: "month_start must be a string YYYY-MM-DD when provided" };
    const ms = o.month_start.trim();
    if (!isValidYmd(ms)) return { ok: false, error: "month_start must be a valid calendar date (YYYY-MM-DD)" };
    month_start = ms;
  }

  return { ok: true, value: { user_id, month_start } };
}
