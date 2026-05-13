export type CoachSessionType =
  | "checkin"
  | "stuck"
  | "planning"
  | "freeform"
  | "insight"
  | "gate";

export type CoachMessageInput = {
  session_type: CoachSessionType;
  message: string;
  session_id: string;
  day_id: string;
};

export type ActionTaken = {
  type: string;
  ok: boolean;
  detail?: string;
};

export type CoachMessageSuccess = {
  response: string;
  action_taken: ActionTaken[];
  tokens_used: number;
  session_id: string;
  sessions_remaining: number | null;
  model_used: string;
};

export type CoachMessageError = {
  message: string;
  code?: string;
  detail?: string;
  sessions_remaining?: number;
};
