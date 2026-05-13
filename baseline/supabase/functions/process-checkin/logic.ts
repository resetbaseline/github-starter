import type { DayResult, GoalOutcome, ProcessCheckinInput, ReflectionAnswer } from "./types.ts";

export type GoalRow = { id: string; is_non_negotiable: boolean };

/** Calendar add for Postgres `date` strings (YYYY-MM-DD). */
export function addCalendarDays(isoDate: string, delta: number): string {
  const [y, m, d] = isoDate.split("-").map(Number);
  const utc = Date.UTC(y, m - 1, d + delta);
  return new Date(utc).toISOString().slice(0, 10);
}

export function outcomeMap(outcomes: GoalOutcome[]): Map<string, boolean> {
  const m = new Map<string, boolean>();
  for (const o of outcomes) {
    m.set(o.goal_id, o.completed);
  }
  return m;
}

/** Every on-day goal must appear in outcomes when the day has goals. */
export function validateGoalCoverage(goals: GoalRow[], outcomes: GoalOutcome[]): string | null {
  if (goals.length === 0) return null;
  const ids = new Set(outcomes.map((o) => o.goal_id));
  for (const g of goals) {
    if (!ids.has(g.id)) {
      return `Missing outcome for goal_id ${g.id}`;
    }
  }
  return null;
}

/** Non-negotiable goals must be explicitly completed to avoid a loss (except skipped path). */
export function validateNonNegotiables(goals: GoalRow[], outcomes: Map<string, boolean>): string | null {
  for (const g of goals) {
    if (!g.is_non_negotiable) continue;
    if (!outcomes.has(g.id)) {
      return `Missing outcome for non-negotiable goal ${g.id}`;
    }
  }
  return null;
}

export function classifyDayResult(args: {
  goals: GoalRow[];
  outcomes: Map<string, boolean>;
  reflectionCount: number;
  focusMinutesTotal: number;
}): DayResult {
  const { goals, outcomes, reflectionCount, focusMinutesTotal } = args;

  if (goals.length === 0 && focusMinutesTotal === 0) {
    return "skipped";
  }

  for (const g of goals) {
    if (!g.is_non_negotiable) continue;
    const done = outcomes.get(g.id) === true;
    if (!done) return "lost";
  }

  const allNnComplete = goals.filter((g) => g.is_non_negotiable).every((g) => outcomes.get(g.id) === true);
  const nn = goals.filter((g) => g.is_non_negotiable);
  const nnOk = nn.length === 0 ? true : allNnComplete;

  if (nnOk && reflectionCount >= 1) return "won";
  return "lost";
}

export function isPerfectDay(args: {
  goals: GoalRow[];
  outcomes: Map<string, boolean>;
  reflectionCount: number;
  focusMinutesTotal: number;
}): boolean {
  if (args.goals.length === 0) return false;
  if (args.reflectionCount < 1) return false;
  if (args.focusMinutesTotal <= 0) return false;
  return args.goals.every((g) => args.outcomes.get(g.id) === true);
}

export function parseProcessCheckinBody(raw: unknown): { ok: true; value: ProcessCheckinInput } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") return { ok: false, error: "Body must be a JSON object" };
  const o = raw as Record<string, unknown>;
  const day_id = o.day_id;
  if (typeof day_id !== "string" || day_id.length === 0) return { ok: false, error: "day_id is required" };

  if (!Array.isArray(o.goal_outcomes)) return { ok: false, error: "goal_outcomes must be an array" };
  const goal_outcomes: GoalOutcome[] = [];
  for (const item of o.goal_outcomes) {
    if (!item || typeof item !== "object") return { ok: false, error: "goal_outcomes items must be objects" };
    const g = item as Record<string, unknown>;
    if (typeof g.goal_id !== "string") return { ok: false, error: "goal_outcomes[].goal_id must be a string" };
    if (typeof g.completed !== "boolean") return { ok: false, error: "goal_outcomes[].completed must be a boolean" };
    goal_outcomes.push({ goal_id: g.goal_id, completed: g.completed });
  }

  if (!Array.isArray(o.reflection_answers)) return { ok: false, error: "reflection_answers must be an array" };
  const reflection_answers: ReflectionAnswer[] = [];
  for (const item of o.reflection_answers) {
    if (!item || typeof item !== "object") return { ok: false, error: "reflection_answers items must be objects" };
    const r = item as Record<string, unknown>;
    if (typeof r.question_text !== "string") return { ok: false, error: "reflection_answers[].question_text must be a string" };
    if (typeof r.answer !== "string") return { ok: false, error: "reflection_answers[].answer must be a string" };
    if (typeof r.category !== "string") return { ok: false, error: "reflection_answers[].category must be a string" };
    reflection_answers.push({ question_text: r.question_text, answer: r.answer, category: r.category });
  }

  const tomorrow_intention = o.tomorrow_intention == null ? null : String(o.tomorrow_intention);

  if (!Array.isArray(o.tomorrow_timeblocks)) return { ok: false, error: "tomorrow_timeblocks must be an array" };
  const tomorrow_timeblocks: ProcessCheckinInput["tomorrow_timeblocks"] = [];
  for (const item of o.tomorrow_timeblocks) {
    if (!item || typeof item !== "object") return { ok: false, error: "tomorrow_timeblocks items must be objects" };
    const t = item as Record<string, unknown>;
    if (typeof t.title !== "string") return { ok: false, error: "tomorrow_timeblocks[].title must be a string" };
    if (typeof t.start_time !== "string") return { ok: false, error: "tomorrow_timeblocks[].start_time must be a string (HH:MM or HH:MM:SS)" };
    if (typeof t.end_time !== "string") return { ok: false, error: "tomorrow_timeblocks[].end_time must be a string (HH:MM or HH:MM:SS)" };
    if (typeof t.color_hex !== "string") return { ok: false, error: "tomorrow_timeblocks[].color_hex must be a string" };
    tomorrow_timeblocks.push({
      title: t.title,
      start_time: normalizeTime(t.start_time),
      end_time: normalizeTime(t.end_time),
      color_hex: t.color_hex,
    });
  }

  if (typeof o.streak_freeze_used !== "boolean") {
    return { ok: false, error: "streak_freeze_used must be a boolean" };
  }

  return {
    ok: true,
    value: {
      day_id,
      goal_outcomes,
      reflection_answers,
      tomorrow_intention,
      tomorrow_timeblocks,
      streak_freeze_used: o.streak_freeze_used,
    },
  };
}

function normalizeTime(t: string): string {
  const parts = t.split(":");
  if (parts.length === 2) return `${parts[0].padStart(2, "0")}:${parts[1].padStart(2, "0")}:00`;
  return t;
}
