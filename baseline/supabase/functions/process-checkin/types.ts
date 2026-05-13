export type GoalOutcome = { goal_id: string; completed: boolean };
export type ReflectionAnswer = { question_text: string; answer: string; category: string };
export type TomorrowTimeblock = { title: string; start_time: string; end_time: string; color_hex: string };

export type ProcessCheckinInput = {
  day_id: string;
  goal_outcomes: GoalOutcome[];
  reflection_answers: ReflectionAnswer[];
  tomorrow_intention: string | null;
  tomorrow_timeblocks: TomorrowTimeblock[];
  streak_freeze_used: boolean;
};

export type DayResult = "won" | "lost" | "skipped";

export type ProcessCheckinSuccess = {
  day_status: DayResult;
  streak: { current_count: number; max_count: number; active: boolean };
  freeze_counts: { available: number; used_this_month: number };
  perfect_day: boolean;
};

export type ProcessCheckinError = {
  message: string;
  code?: string;
  detail?: string;
};
