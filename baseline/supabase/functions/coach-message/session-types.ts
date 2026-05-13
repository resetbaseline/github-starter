import type { CoachSessionType } from "./types.ts";

export function modelForSessionType(sessionType: CoachSessionType): "sonnet" | "haiku" {
  return sessionType === "checkin" || sessionType === "insight" ? "sonnet" : "haiku";
}

export function sessionTypeInstruction(sessionType: CoachSessionType): string {
  switch (sessionType) {
    case "checkin":
      return "Session type: nightly check-in. Help them close the day honestly. Max 4 sentences unless they ask a direct follow-up.";
    case "insight":
      return "Session type: insight. Offer a sharp, specific read on patterns—no generic praise. Max 4 sentences unless they ask a direct follow-up.";
    case "stuck":
      return "Session type: stuck. They feel blocked—name the friction, one concrete next move. Gate / Focus Block / Schedule when relevant.";
    case "planning":
      return "Session type: planning. Turn intentions into a small, ordered plan. Max 4 sentences unless they ask a direct follow-up.";
    case "gate":
      return "Session type: gate context. Max 2 sentences. Be direct about tradeoffs and time.";
    case "freeform":
      return "Session type: freeform. Stay concise; no padding.";
    default:
      return "Session type: general.";
  }
}
