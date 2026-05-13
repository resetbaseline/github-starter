export type GenerateIdentityMirrorInput = {
  /** When set, must equal the JWT subject. */
  user_id?: string;
  /** Any calendar day `YYYY-MM-DD` in the user timezone; normalized to the first day of that month. */
  month_start?: string;
};

export type GenerateIdentityMirrorSuccess = {
  mirror_id: string;
  month_start: string;
  portrait_text: string;
  stats_summary: Record<string, unknown>;
  duplicate?: boolean;
};

export type GenerateIdentityMirrorError = {
  message: string;
  code?: string;
  detail?: string;
};
