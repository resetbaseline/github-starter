import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callHaiku, callSonnet, type AnthropicMessage } from "../_shared/anthropic-client.ts";
import { COACH_VOICE_SYSTEM_PROMPT } from "../_shared/coach-voice.ts";
import { calendarToday, validateTimeZone } from "../_shared/calendar.ts";
import { executeCoachActions, extractActionJsonBlocks, stripActionTags } from "./actions.ts";
import { rateLimitState } from "./rate-limit.ts";
import { modelForSessionType, sessionTypeInstruction } from "./session-types.ts";
import type { CoachMessageError, CoachMessageInput, CoachMessageSuccess } from "./types.ts";

function buildSystemPrompt(args: {
  memory: Record<string, unknown> | null;
  journalLines: string[];
  todayContext: string;
  sessionInstruction: string;
  longTermGoalsBlock: string;
}): string {
  const parts: string[] = [COACH_VOICE_SYSTEM_PROMPT];

  parts.push("\n## User memory profile (long-term)\n");
  parts.push(JSON.stringify(args.memory ?? {}, null, 2));

  parts.push("\n## Long term goals\n");
  parts.push(args.longTermGoalsBlock);

  parts.push("\n## Recent session journal (newest summaries last; read oldest→newest for arc)\n");
  parts.push(args.journalLines.length ? args.journalLines.join("\n---\n") : "(none yet)");

  parts.push("\n## Today's live context\n");
  parts.push(args.todayContext);

  parts.push("\n## Session focus\n");
  parts.push(args.sessionInstruction);

  parts.push(
    "\nIf you take a product action, append a JSON object inside <action></action> after your reply text. Shape: {\"type\":\"add_goal\"|\"update_schedule\"|\"set_tomorrow_intention\"|\"start_focus_block\",\"params\":{...}}",
  );

  parts.push(
    "\nWhen Long term goals above is not \"(none active)\", keep those ambitions in mind as background—do not claim progress the user has not stated in this session.",
  );

  return parts.join("\n");
}

export async function coachMessage(
  sb: SupabaseClient,
  userId: string,
  input: CoachMessageInput,
  now: Date = new Date(),
): Promise<{ data: CoachMessageSuccess | null; error: CoachMessageError | null }> {
  const { data: userRow, error: uErr } = await sb
    .from("users")
    .select("timezone,pro,wake_time,checkin_time,coach_strictness")
    .eq("id", userId)
    .maybeSingle();

  if (uErr) {
    return { data: null, error: { message: uErr.message, code: uErr.code, detail: uErr.details ?? undefined } };
  }
  const tz = (userRow as { timezone?: string } | null)?.timezone;
  if (!tz) {
    return { data: null, error: { message: "User timezone missing", code: "profile_missing" } };
  }
  const tzErr = validateTimeZone(tz);
  if (tzErr) {
    return { data: null, error: { message: tzErr, code: "invalid_timezone" } };
  }

  const pro = Boolean((userRow as { pro?: boolean }).pro);

  const rl = await rateLimitState(sb, userId, tz, input.session_id, pro, now);
  if (!rl.ok) {
    return {
      data: null,
      error: {
        message: "Daily coach session limit reached for free accounts",
        code: "rate_limit_exceeded",
        sessions_remaining: 0,
      },
    };
  }

  const { data: dayRow, error: dErr } = await sb
    .from("days")
    .select("id,user_id,date,status,goals_count,goals_completed,gate_triggers,gate_dismissals,focus_minutes_total")
    .eq("id", input.day_id)
    .maybeSingle();

  if (dErr) {
    return { data: null, error: { message: dErr.message, code: dErr.code, detail: dErr.details ?? undefined } };
  }
  const day = dayRow as {
    id: string;
    user_id: string;
    date: string;
    status: string;
    goals_count: number;
    goals_completed: number;
    gate_triggers: number;
    gate_dismissals: number;
    focus_minutes_total: number;
  } | null;

  if (!day || day.user_id !== userId) {
    return { data: null, error: { message: "Day not found", code: "day_not_found" } };
  }

  const [
    { data: memory, error: mErr },
    { data: journalRows, error: jErr },
    { data: nnGoals, error: gErr },
    { data: streakRow, error: sErr },
    { data: history, error: hErr },
    { data: userGoals, error: ugErr },
  ] = await Promise.all([
    sb.from("coach_memory_profile").select("*").eq("user_id", userId).maybeSingle(),
    sb
      .from("coach_session_journal")
      .select("summary,emotional_tone,session_type,created_at")
      .eq("user_id", userId)
      .eq("compressed", false)
      .order("created_at", { ascending: false })
      .limit(14),
    sb.from("goals").select("id,text,status").eq("day_id", input.day_id).eq("is_non_negotiable", true),
    sb.from("streaks").select("current_count,max_count,active").eq("user_id", userId).maybeSingle(),
    sb
      .from("coach_messages")
      .select("role,message,created_at")
      .eq("session_id", input.session_id)
      .order("created_at", { ascending: true }),
    sb
      .from("user_goals")
      .select("id,category,long_term_goal,goal_name,target_date,daily_action_suggestion,order_index,active")
      .eq("user_id", userId)
      .eq("active", true)
      .order("order_index", { ascending: true }),
  ]);

  if (mErr || jErr || gErr || sErr || hErr || ugErr) {
    const err = mErr ?? jErr ?? gErr ?? sErr ?? hErr ?? ugErr!;
    return { data: null, error: { message: err.message, code: err.code, detail: err.details ?? undefined } };
  }

  const journalSorted = [...(journalRows ?? [])].sort(
    (a: { created_at: string }, b: { created_at: string }) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
  );
  const journalLines = journalSorted.map((r: { summary: string; session_type: string; created_at: string }) =>
    `[${r.created_at}] (${r.session_type}) ${r.summary}`
  );

  const nnList = (nnGoals ?? []) as { id: string; text: string; status: string }[];
  const nnText = nnList.map((g) => `- ${g.text} (${g.status})`).join("\n") || "(none)";

  const userGoalRows = (userGoals ?? []) as { category?: string; long_term_goal?: string; goal_name?: string }[];
  const longTermGoalsBlock =
    userGoalRows.length === 0
      ? "(none active)"
      : userGoalRows
          .map((row) => {
            const cat = String(row.category ?? "");
            const lt = String(row.long_term_goal ?? row.goal_name ?? "");
            return `- [${cat}] ${lt}`;
          })
          .join("\n");

  const streak = streakRow as { current_count: number; max_count: number; active: boolean } | null;
  const nowLocal = calendarToday(now, tz);
  const u = userRow as { wake_time: string; checkin_time: string; coach_strictness: string };

  const todayContext = [
    `Local now: ${now.toISOString()} (user calendar date: ${nowLocal}, day row date: ${day.date})`,
    `Day status: ${day.status}; goals ${day.goals_completed}/${day.goals_count}; gate_triggers: ${day.gate_triggers}; gate_dismissals: ${day.gate_dismissals}; focus_minutes_total: ${day.focus_minutes_total}`,
    `Streak: current ${streak?.current_count ?? 0}, max ${streak?.max_count ?? 0}, active ${streak?.active ?? false}`,
    `User: coach_strictness=${u.coach_strictness}, wake_time=${u.wake_time}, checkin_time=${u.checkin_time}`,
    `Non-negotiable goals today:\n${nnText}`,
  ].join("\n");

  const system = buildSystemPrompt({
    memory: (memory ?? null) as Record<string, unknown> | null,
    journalLines,
    todayContext,
    sessionInstruction: sessionTypeInstruction(input.session_type),
    longTermGoalsBlock,
  });

  const histMsgs: AnthropicMessage[] = ((history ?? []) as { role: string; message: string }[])
    .filter((row) => row.role === "user" || row.role === "assistant")
    .map((row) => ({
      role: row.role as "user" | "assistant",
      content: row.message,
    }));

  histMsgs.push({ role: "user", content: input.message });

  const useSonnet = modelForSessionType(input.session_type) === "sonnet";
  const maxOut = useSonnet ? 1024 : 768;

  let rawAssistant: string;
  let inputTokens: number;
  let outputTokens: number;
  let modelUsed: string;

  try {
    if (useSonnet) {
      const r = await callSonnet(system, histMsgs, maxOut);
      rawAssistant = r.content;
      inputTokens = r.inputTokens;
      outputTokens = r.outputTokens;
      modelUsed = "claude-sonnet-4-6";
    } else {
      const r = await callHaiku(system, histMsgs, maxOut);
      rawAssistant = r.content;
      inputTokens = r.inputTokens;
      outputTokens = r.outputTokens;
      modelUsed = "claude-haiku-4-5";
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { data: null, error: { message: msg, code: "anthropic_error", detail: undefined } };
  }

  const blocks = extractActionJsonBlocks(rawAssistant);
  const action_taken = await executeCoachActions(sb, userId, input.day_id, day.date, tz, blocks);
  const responseText = stripActionTags(rawAssistant);
  const tokens_used = inputTokens + outputTokens;

  const { error: insUserErr } = await sb.from("coach_messages").insert({
    user_id: userId,
    session_id: input.session_id,
    day_id: input.day_id,
    session_type: input.session_type,
    role: "user",
    message: input.message,
  });
  if (insUserErr) {
    return { data: null, error: { message: insUserErr.message, code: insUserErr.code, detail: insUserErr.details ?? undefined } };
  }

  const { error: insAsstErr } = await sb.from("coach_messages").insert({
    user_id: userId,
    session_id: input.session_id,
    day_id: input.day_id,
    session_type: input.session_type,
    role: "assistant",
    message: responseText || rawAssistant.trim(),
    tokens_used,
    model_used: modelUsed,
  });
  if (insAsstErr) {
    return { data: null, error: { message: insAsstErr.message, code: insAsstErr.code, detail: insAsstErr.details ?? undefined } };
  }

  return {
    data: {
      response: responseText || rawAssistant.trim(),
      action_taken,
      tokens_used,
      session_id: input.session_id,
      sessions_remaining: rl.sessions_remaining,
      model_used: modelUsed,
    },
    error: null,
  };
}
