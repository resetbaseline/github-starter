import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * `next_action` for the NN goal matching `active_non_negotiable` text on the given day.
 * Match is exact trimmed string first; fallback case-insensitive on same day NN goals.
 */
export async function fetchNonNegotiableGoalNextAction(
  userSb: SupabaseClient,
  userId: string,
  dayId: string,
  activeNonNegotiable: string | null,
): Promise<string | null> {
  const needle = typeof activeNonNegotiable === "string" ? activeNonNegotiable.trim() : "";
  if (!needle) return null;

  const { data: exact, error: e1 } = await userSb
    .from("goals")
    .select("next_action")
    .eq("day_id", dayId)
    .eq("user_id", userId)
    .eq("is_non_negotiable", true)
    .eq("text", needle)
    .maybeSingle();

  if (e1) throw new Error(e1.message);
  const na1 = typeof (exact as { next_action?: string } | null)?.next_action === "string"
    ? String((exact as { next_action: string }).next_action).trim()
    : "";
  if (na1) return na1;

  const { data: rows, error: e2 } = await userSb
    .from("goals")
    .select("text,next_action")
    .eq("day_id", dayId)
    .eq("user_id", userId)
    .eq("is_non_negotiable", true);

  if (e2) throw new Error(e2.message);
  const lowered = needle.toLowerCase();
  for (const r of rows ?? []) {
    const t = typeof (r as { text?: string }).text === "string"
      ? String((r as { text: string }).text).trim().toLowerCase()
      : "";
    if (t === lowered) {
      const na = typeof (r as { next_action?: string }).next_action === "string"
        ? String((r as { next_action: string }).next_action).trim()
        : "";
      return na.length > 0 ? na : null;
    }
  }
  return null;
}
