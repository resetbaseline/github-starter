export type UpdateCoachMemoryInput = {
  user_id: string;
  session_id: string;
};

export type UpdateCoachMemorySuccess = {
  success: true;
  skipped?: boolean;
};

export type UpdateCoachMemoryError = {
  message: string;
  code?: string;
  detail?: string;
};

/** Parsed from Haiku extraction response. */
export type ExtractedMemoryFacts = {
  goal_updates?: Array<{ goal_name: string; current_status: string }>;
  new_struggles?: string[];
  new_wins?: string[];
  focus_window?: string | null;
  risk_window?: string | null;
  coach_notes?: string[];
  emotional_tone?: string;
  identity_summary?: string | null;
  gate_pattern_summary?: string | null;
};
