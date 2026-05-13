import type { GateResolveInput } from "./types.ts";
import { isValidOutcome } from "./logic.ts";

export function parseGateResolveBody(raw: unknown): { ok: true; value: GateResolveInput } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") return { ok: false, error: "Body must be a JSON object" };
  const o = raw as Record<string, unknown>;

  if (typeof o.gate_trigger_id !== "string" || o.gate_trigger_id.trim() === "") {
    return { ok: false, error: "gate_trigger_id is required" };
  }
  if (typeof o.time_used_seconds !== "number" || !Number.isFinite(o.time_used_seconds)) {
    return { ok: false, error: "time_used_seconds must be a finite number" };
  }
  if (o.time_used_seconds < 0) {
    return { ok: false, error: "time_used_seconds must be >= 0" };
  }
  if (typeof o.outcome !== "string" || !isValidOutcome(o.outcome)) {
    return { ok: false, error: "outcome must be dismissed | timed_access | focus_block_active" };
  }

  return {
    ok: true,
    value: {
      gate_trigger_id: o.gate_trigger_id.trim(),
      time_used_seconds: o.time_used_seconds,
      outcome: o.outcome,
    },
  };
}
