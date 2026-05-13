import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { computeUsageRatio, shouldFlagMismatch } from "./logic.ts";
import type { GateResolveError, GateResolveInput, GateResolveSuccess } from "./types.ts";

type TriggerRow = {
  id: string;
  user_id: string;
  day_id: string;
  time_granted_seconds: number | null;
  resolved_at: string | null;
  reason_classification: string | null;
};

export async function gateResolve(
  userSb: SupabaseClient,
  serviceSb: SupabaseClient,
  userId: string,
  input: GateResolveInput,
): Promise<{ data: GateResolveSuccess | null; error: GateResolveError | null }> {
  const { data: row, error: selErr } = await userSb
    .from("gate_triggers")
    .select("id,user_id,day_id,time_granted_seconds,resolved_at,reason_classification")
    .eq("id", input.gate_trigger_id)
    .maybeSingle();

  if (selErr) {
    return { data: null, error: { message: selErr.message, code: selErr.code, detail: selErr.details ?? undefined } };
  }
  const trigger = row as TriggerRow | null;
  if (!trigger || trigger.user_id !== userId) {
    return { data: null, error: { message: "Gate trigger not found", code: "not_found" } };
  }
  if (trigger.resolved_at) {
    return { data: null, error: { message: "Gate trigger already resolved", code: "already_resolved" } };
  }

  const usage_ratio = computeUsageRatio(input.time_used_seconds, trigger.time_granted_seconds);
  const mismatch_flagged = shouldFlagMismatch({
    usage_ratio,
    reason_classification: trigger.reason_classification,
  });

  const resolved_at = new Date().toISOString();

  const { error: upErr } = await serviceSb
    .from("gate_triggers")
    .update({
      time_used_seconds: input.time_used_seconds,
      usage_ratio,
      resolved_at,
      outcome: input.outcome,
      mismatch_flagged,
    })
    .eq("id", input.gate_trigger_id)
    .eq("user_id", userId);

  if (upErr) {
    return { data: null, error: { message: upErr.message, code: upErr.code, detail: upErr.details ?? undefined } };
  }

  if (input.outcome === "dismissed") {
    const { data: dayRow, error: dErr } = await serviceSb.from("days").select("gate_dismissals").eq("id", trigger.day_id).eq("user_id", userId).maybeSingle();
    if (dErr) {
      return { data: null, error: { message: dErr.message, code: dErr.code, detail: dErr.details ?? undefined } };
    }
    const current = (dayRow as { gate_dismissals: number } | null)?.gate_dismissals ?? 0;
    const { error: dayUpErr } = await serviceSb
      .from("days")
      .update({ gate_dismissals: current + 1 })
      .eq("id", trigger.day_id)
      .eq("user_id", userId);
    if (dayUpErr) {
      return { data: null, error: { message: dayUpErr.message, code: dayUpErr.code, detail: dayUpErr.details ?? undefined } };
    }
  }

  return {
    data: { success: true, usage_ratio, mismatch_flagged },
    error: null,
  };
}
