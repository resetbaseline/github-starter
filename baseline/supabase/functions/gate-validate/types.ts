export type GateValidateInput = {
  app_bundle_id: string;
  app_name: string;
  trigger_source: string;
  stated_reason: string;
  active_non_negotiable: string | null;
};

export type GateValidateSuccess = {
  coach_response: string;
  time_granted_seconds: number;
  gate_trigger_id: string;
  trigger_count_today: number;
};

export type GateValidateError = {
  message: string;
  code?: string;
  detail?: string;
};
