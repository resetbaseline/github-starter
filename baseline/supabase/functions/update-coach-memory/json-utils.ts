import type { ExtractedMemoryFacts } from "./types.ts";

/** Pull JSON object from model output (raw JSON or ```json ... ``` fence). */
export function parseJsonObject(raw: string): unknown | null {
  let s = raw.trim();
  const fence = /^```(?:json)?\s*([\s\S]*?)```/im.exec(s);
  if (fence) s = fence[1].trim();

  const start = s.indexOf("{");
  const end = s.lastIndexOf("}");
  if (start === -1 || end <= start) return null;
  const slice = s.slice(start, end + 1);
  try {
    return JSON.parse(slice);
  } catch {
    return null;
  }
}

export function coerceExtractedFacts(v: unknown): ExtractedMemoryFacts | null {
  if (!v || typeof v !== "object") return null;
  return v as ExtractedMemoryFacts;
}

export function dedupeStrings(a: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const x of a) {
    const t = x.trim();
    if (!t || seen.has(t)) continue;
    seen.add(t);
    out.push(t);
  }
  return out;
}

export function mergeStringArrays(existing: string[] | null | undefined, incoming: string[] | null | undefined): string[] {
  return dedupeStrings([...(existing ?? []), ...(incoming ?? [])]);
}

export function monthKey(iso: string): string {
  const d = new Date(iso);
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}
