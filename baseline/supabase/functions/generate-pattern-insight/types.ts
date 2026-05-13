export type GeneratePatternInsightInput = {
  /** When set, must equal the JWT subject. */
  user_id?: string;
  /** Calendar anchor `YYYY-MM-DD` in the user timezone; normalized to the Monday that starts that ISO week. */
  week_start?: string;
};

export type GeneratePatternInsightSuccess = {
  insight_id: string;
  week_start: string;
  insight_text: string;
  duplicate?: boolean;
};

export type GeneratePatternInsightError = {
  message: string;
  code?: string;
  detail?: string;
};
