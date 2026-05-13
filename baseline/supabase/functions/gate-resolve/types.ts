export type GateOutcome = "dismissed" | "timed_access" | "focus_block_active";

export type GateResolveInput = {
  gate_trigger_id: string;
  time_used_seconds: number;
  outcome: GateOutcome;
};

export type GateResolveSuccess = {
  success: true;
  usage_ratio: number | null;
  mismatch_flagged: boolean;
};

export type GateResolveError = {
  message: string;
  code?: string;
  detail?: string;
};
