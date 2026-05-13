export type Classification = "specific_legitimate" | "plausible" | "vague" | "low_legitimacy";

export function baseGrantSeconds(c: Classification): number {
  switch (c) {
    case "specific_legitimate":
      return 600;
    case "plausible":
      return 300;
    case "vague":
      return 240;
    case "low_legitimacy":
      return 180;
  }
}

/**
 * `priorTriggersOnDay` = `days.gate_triggers` before this event (integer count of prior triggers today).
 */
export function applyEscalation(grant: number, priorTriggersOnDay: number): number {
  const n = priorTriggersOnDay;
  let g = grant;
  if (n >= 4 && n <= 5) g -= 60;
  if (n >= 6 && n <= 7) g = Math.min(g, 300);
  if (n >= 8) g = Math.min(g, 180);
  return Math.max(0, Math.floor(g));
}

export function applyMismatchReduction(grant: number, mismatchCount: number): number {
  if (mismatchCount >= 3) return Math.max(0, grant - 60);
  return grant;
}

export function firstWord(reason: string): string {
  const t = reason.trim();
  if (!t) return "";
  return t.split(/\s+/)[0] ?? "";
}

/** Strip wildcard chars for a simple ILIKE contains match. */
export function sanitizeLikeFragment(fragment: string): string {
  return fragment.replace(/[%_\\]/g, "").trim();
}

export function wordCount(reason: string): number {
  const parts = reason.trim().split(/\s+/).filter(Boolean);
  return parts.length;
}

export function parseClassification(raw: string): Classification {
  const line = raw.trim().split("\n").map((l) => l.trim()).find((l) => l.length > 0) ?? "";
  const token = (line.split(/[\s,;]+/).find(Boolean) ?? "").toLowerCase().replace(/[^a-z_]/g, "");

  if (token === "specific_legitimate" || token === "specificlegitimate") return "specific_legitimate";
  if (token === "plausible") return "plausible";
  if (token === "vague") return "vague";
  if (token === "low_legitimacy" || token === "lowlegitimacy") return "low_legitimacy";

  if (line.toLowerCase().includes("specific")) return "specific_legitimate";
  if (line.toLowerCase().includes("plausible")) return "plausible";
  if (line.toLowerCase().includes("low")) return "low_legitimacy";

  return "vague";
}
