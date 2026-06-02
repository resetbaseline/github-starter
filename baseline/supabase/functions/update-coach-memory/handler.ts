import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callHaiku } from "../_shared/anthropic-client.ts";
import {
  coerceExtractedFacts,
  dedupeStrings,
  mergeStringArrays,
  monthKey,
  parseJsonObject,
} from "./json-utils.ts";
import type {
  ExtractedMemoryFacts,
  UpdateCoachMemoryError,
  UpdateCoachMemoryInput,
  UpdateCoachMemorySuccess,
} from "./types.ts";

type GoalEntry = { goal_name: string; current_status: string };

type CoachMsgRow = {
  id: string;
  role: string;
  message: string;
  session_type: string;
  day_id: string | null;
  created_at: string;
};

type MemoryProfileRow = {
  identity_summary: string | null;
  goals_summary: unknown;
  top_struggles: string[] | null;
  focus_window_best: string | null;
  highest_risk_window: string | null;
  gate_pattern_summary: string | null;
  coach_notes: string[] | null;
  wins_recent: string[] | null;
};

function normalizeGoalsSummary(existing: unknown): Map<string, GoalEntry> {
  const m = new Map<string, GoalEntry>();
  if (Array.isArray(existing)) {
    for (const row of existing) {
      if (row && typeof row === "object") {
        const o = row as Record<string, unknown>;
        const gn = String(o.goal_name ?? "").trim();
        const cs = String(o.current_status ?? "").trim();
        if (gn) m.set(gn.toLowerCase(), { goal_name: gn, current_status: cs });
      }
    }
  } else if (existing && typeof existing === "object" && !Array.isArray(existing)) {
    const o = existing as Record<string, unknown>;
    if (Array.isArray(o.goals)) return normalizeGoalsSummary(o.goals);
  }
  return m;
}

function applyGoalUpdatesToMap(m: Map<string, GoalEntry>, updates: GoalEntry[]) {
  for (const u of updates) {
    const gn = u.goal_name.trim();
    const cs = u.current_status.trim();
    if (!gn) continue;
    m.set(gn.toLowerCase(), { goal_name: gn, current_status: cs });
  }
}

function buildConversationTranscript(messages: CoachMsgRow[]): string {
  return messages
    .map((m) => {
      const who = m.role === "assistant" ? "Coach" : "User";
      return `[${m.created_at}] ${who}: ${m.message}`;
    })
    .join("\n\n");
}

const EXTRACT_SYSTEM = `You extract structured memory updates from a coach chat transcript.
Return ONLY valid JSON (no markdown fences) with this exact shape:
{
  "goal_updates": [{"goal_name": string, "current_status": string}],
  "new_struggles": string[],
  "new_wins": string[],
  "focus_window": string | null,
  "risk_window": string | null,
  "coach_notes": string[],
  "emotional_tone": string,
  "identity_summary": string | null,
  "gate_pattern_summary": string | null
}
Rules:
- Use empty arrays when nothing applies; use null for optional string fields you cannot infer.
- goal_updates: only goals explicitly discussed with a status change or clear current state.
- new_struggles / new_wins: short phrases, max ~8 items each.
- coach_notes: durable coaching observations (max ~6).
- emotional_tone: one short label (e.g. "tired but determined", "activated", "flat").`;

const SUMMARY_SYSTEM = `You write a concise narrative summary of a coach conversation for the user's private session journal.
Output 3–5 complete sentences in second person ("you"). No bullet lists. Be specific to what was said.`;

const COMPRESS_SYSTEM = `You compress multiple session journal summaries from one calendar month into one factual paragraph (4–7 sentences).
No bullet lists. Preserve themes and outcomes; omit dates. Third person or neutral "they" is fine.`;

async function applyUserGoalStatusUpdates(
  userSb: SupabaseClient,
  userId: string,
  updates: GoalEntry[],
): Promise<void> {
  for (const u of updates) {
    const gn = u.goal_name.trim();
    const cs = u.current_status.trim();
    if (!gn) continue;
    await userSb
      .from("user_goals")
      .update({ current_status: cs })
      .eq("user_id", userId)
      .ilike("goal_name", gn);
  }
}

async function runMonthlyCompression(serviceSb: SupabaseClient, userId: string): Promise<void> {
  const cutoff = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString();
  const { data: rows, error } = await serviceSb
    .from("coach_session_journal")
    .select("id, summary, created_at")
    .eq("user_id", userId)
    .eq("compressed", false)
    .lt("created_at", cutoff);

  if (error || !rows?.length) return;
  if (rows.length <= 14) return;

  const byMonth = new Map<string, { ids: string[]; summaries: string[] }>();
  for (const r of rows as { id: string; summary: string; created_at: string }[]) {
    const mk = monthKey(r.created_at);
    let g = byMonth.get(mk);
    if (!g) {
      g = { ids: [], summaries: [] };
      byMonth.set(mk, g);
    }
    g.ids.push(r.id);
    g.summaries.push(r.summary);
  }

  for (const [, group] of byMonth) {
    const body = group.summaries.map((s, i) => `--- Entry ${i + 1} ---\n${s}`).join("\n\n");
    const { content } = await callHaiku(
      COMPRESS_SYSTEM,
      [{ role: "user", content: `Month batch (${group.summaries.length} entries):\n\n${body}` }],
      512,
    );
    const paragraph = content.trim();
    if (!paragraph) continue;

    const { error: upErr } = await serviceSb
      .from("coach_session_journal")
      .update({ compression_summary: paragraph, compressed: true })
      .in("id", group.ids);
    if (upErr) {
      console.error("update-coach-memory compression update failed", upErr.message);
    }
  }
}

export async function updateCoachMemory(
  userSb: SupabaseClient,
  serviceSb: SupabaseClient,
  userId: string,
  input: UpdateCoachMemoryInput,
): Promise<{ data: UpdateCoachMemorySuccess | null; error: UpdateCoachMemoryError | null }> {
  if (input.user_id !== userId) {
    return { data: null, error: { message: "user_id does not match authenticated user", code: "forbidden" } };
  }

  const { data: msgs, error: mErr } = await userSb
    .from("coach_messages")
    .select("id, role, message, session_type, day_id, created_at")
    .eq("user_id", userId)
    .eq("session_id", input.session_id)
    .order("created_at", { ascending: true });

  if (mErr) {
    return { data: null, error: { message: mErr.message, code: mErr.code, detail: mErr.details ?? undefined } };
  }

  const messages = (msgs ?? []) as CoachMsgRow[];
  if (messages.length === 0) {
    return { data: { success: true, skipped: true }, error: null };
  }

  const transcript = buildConversationTranscript(messages);
  const first = messages[0]!;

  let extractRaw: string;
  try {
    const r = await callHaiku(
      EXTRACT_SYSTEM,
      [{ role: "user", content: `Transcript:\n\n${transcript}` }],
      2048,
    );
    extractRaw = r.content;
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { data: null, error: { message: msg, code: "anthropic_error" } };
  }

  const parsed = parseJsonObject(extractRaw);
  const facts = coerceExtractedFacts(parsed);
  if (!facts) {
    return {
      data: null,
      error: { message: "Failed to parse memory extraction JSON", code: "parse_error", detail: extractRaw.slice(0, 500) },
    };
  }

  const { data: profileRow, error: pErr } = await userSb
    .from("coach_memory_profile")
    .select(
      "identity_summary, goals_summary, top_struggles, focus_window_best, highest_risk_window, gate_pattern_summary, coach_notes, wins_recent",
    )
    .eq("user_id", userId)
    .maybeSingle();

  if (pErr) {
    return { data: null, error: { message: pErr.message, code: pErr.code, detail: pErr.details ?? undefined } };
  }

  // The profile is normally created by the handle_new_user trigger, but may be
  // missing for legacy users or if the trigger never ran. Fall back to an empty
  // profile; the upsert below creates the row so memory capture still works.
  const profile = (profileRow ?? {
    identity_summary: null,
    goals_summary: null,
    top_struggles: null,
    focus_window_best: null,
    highest_risk_window: null,
    gate_pattern_summary: null,
    coach_notes: null,
    wins_recent: null,
  }) as MemoryProfileRow;
  const goalMap = normalizeGoalsSummary(profile.goals_summary);
  const goalUpdates: GoalEntry[] = (facts.goal_updates ?? [])
    .filter((x) => x && typeof x.goal_name === "string" && typeof x.current_status === "string")
    .map((x) => ({ goal_name: x.goal_name, current_status: x.current_status }));

  applyGoalUpdatesToMap(goalMap, goalUpdates);
  const goalsSummaryOut = [...goalMap.values()];

  const patch: Record<string, unknown> = {
    top_struggles: mergeStringArrays(profile.top_struggles, facts.new_struggles),
    wins_recent: mergeStringArrays(profile.wins_recent, facts.new_wins),
    coach_notes: mergeStringArrays(profile.coach_notes, facts.coach_notes),
    goals_summary: goalsSummaryOut,
    last_updated: new Date().toISOString(),
  };

  const fw = facts.focus_window != null ? String(facts.focus_window).trim() : "";
  if (fw) patch.focus_window_best = fw;

  const rw = facts.risk_window != null ? String(facts.risk_window).trim() : "";
  if (rw) patch.highest_risk_window = rw;

  const idSum = facts.identity_summary != null ? String(facts.identity_summary).trim() : "";
  if (idSum) patch.identity_summary = idSum;

  const gateSum = facts.gate_pattern_summary != null ? String(facts.gate_pattern_summary).trim() : "";
  if (gateSum) patch.gate_pattern_summary = gateSum;

  const { error: upMemErr } = await serviceSb
    .from("coach_memory_profile")
    .upsert({ user_id: userId, ...patch }, { onConflict: "user_id" });
  if (upMemErr) {
    return { data: null, error: { message: upMemErr.message, code: upMemErr.code, detail: upMemErr.details ?? undefined } };
  }

  await applyUserGoalStatusUpdates(userSb, userId, goalUpdates);

  let summaryText: string;
  try {
    const r = await callHaiku(
      SUMMARY_SYSTEM,
      [{ role: "user", content: `Transcript:\n\n${transcript}` }],
      1024,
    );
    summaryText = r.content.trim();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { data: null, error: { message: msg, code: "anthropic_error" } };
  }

  if (!summaryText) {
    summaryText = "Session captured; summary unavailable.";
  }

  const keyFactsUpdated = {
    goal_updates: goalUpdates,
    new_struggles: dedupeStrings(facts.new_struggles ?? []),
    new_wins: dedupeStrings(facts.new_wins ?? []),
    focus_window: fw || null,
    risk_window: rw || null,
    emotional_tone: facts.emotional_tone ?? null,
  };

  const { error: jErr } = await userSb.from("coach_session_journal").insert({
    user_id: userId,
    day_id: first.day_id,
    session_type: first.session_type,
    summary: summaryText,
    emotional_tone: facts.emotional_tone ?? null,
    key_facts_updated: keyFactsUpdated,
  });

  if (jErr) {
    return { data: null, error: { message: jErr.message, code: jErr.code, detail: jErr.details ?? undefined } };
  }

  try {
    await runMonthlyCompression(serviceSb, userId);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("update-coach-memory compression failed", msg);
  }

  return { data: { success: true }, error: null };
}
