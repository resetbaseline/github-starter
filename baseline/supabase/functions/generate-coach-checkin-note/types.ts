export type GenerateCheckinNoteInput = {
  day_id: string;
  /** Optional; must match JWT `sub` when provided. */
  user_id?: string;
};

export type GenerateCheckinNoteSuccess = {
  success: true;
};

export type GenerateCheckinNoteError = {
  message: string;
  code?: string;
  detail?: string;
};
