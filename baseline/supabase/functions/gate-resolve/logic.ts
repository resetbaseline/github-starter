import type { GateOutcome } from "./types.ts";

export function computeUsageRatio(timeUsed: number, timeGranted: number | null | undefined): number | null {
  const g = timeGranted ?? 0;
  if (g <= 0) return null;
  return timeUsed / g;
}

export function shouldFlagMismatch(args: {
  usage_ratio: number | null;
  reason_classification: string | null | undefined;
}): boolean {
  if (args.usage_ratio == null || args.usage_ratio <= 0.8) return false;
  const c = (args.reason_classification ?? "").trim();
  return c === "specific_legitimate" || c === "plausible";
}

const OUTCOMES = new Set<GateOutcome>(["dismissed", "timed_access", "focus_block_active"]);

export function isValidOutcome(v: string): v is GateOutcome {
  return OUTCOMES.has(v as GateOutcome);
}
