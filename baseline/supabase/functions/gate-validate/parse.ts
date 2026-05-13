import type { GateValidateInput } from "./types.ts";

export function parseGateValidateBody(raw: unknown): { ok: true; value: GateValidateInput } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") return { ok: false, error: "Body must be a JSON object" };
  const o = raw as Record<string, unknown>;

  if (typeof o.app_bundle_id !== "string" || o.app_bundle_id.trim() === "") {
    return { ok: false, error: "app_bundle_id is required" };
  }
  if (typeof o.app_name !== "string" || o.app_name.trim() === "") {
    return { ok: false, error: "app_name is required" };
  }
  if (typeof o.trigger_source !== "string" || o.trigger_source.trim() === "") {
    return { ok: false, error: "trigger_source is required" };
  }
  if (typeof o.stated_reason !== "string") {
    return { ok: false, error: "stated_reason must be a string" };
  }

  const active =
    o.active_non_negotiable == null || o.active_non_negotiable === ""
      ? null
      : String(o.active_non_negotiable);

  return {
    ok: true,
    value: {
      app_bundle_id: o.app_bundle_id.trim(),
      app_name: o.app_name.trim(),
      trigger_source: o.trigger_source.trim(),
      stated_reason: o.stated_reason,
      active_non_negotiable: active,
    },
  };
}
