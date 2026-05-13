/** Matches `public.notification_type` enum. */
export type NotificationType =
  | "checkin_reminder"
  | "morning"
  | "timeblock_start"
  | "streak_alert"
  | "reengagement"
  | "coach_nudge"
  | "planning_reminder";

export type SendPushNotificationInput = {
  title: string;
  body: string;
  /** Merged as custom keys next to `aps` (e.g. `baseline.notification_type`). */
  data?: Record<string, unknown>;
  notification_type?: NotificationType;
  /** Required when the caller authenticates with the service role JWT. */
  user_id?: string;
  badge?: number;
  /** iOS sound name; default `default` when omitted. */
  sound?: string | null;
};

export type SendPushDeviceResult = {
  token_id: string;
  ok: boolean;
  status?: number;
  error?: string;
  unregistered?: boolean;
};

export type SendPushNotificationSuccess = {
  sent: number;
  failed: number;
  skipped?: "no_tokens" | "notifications_disabled";
  results: SendPushDeviceResult[];
};

export type SendPushNotificationError = {
  message: string;
  code?: string;
  detail?: string;
};
