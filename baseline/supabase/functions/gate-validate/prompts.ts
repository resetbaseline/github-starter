export function classificationSystemPrompt(): string {
  return `You classify short user explanations for why they want temporary app access.
Reply with exactly ONE lowercase token from this list, nothing else:
specific_legitimate | plausible | vague | low_legitimacy

Definitions:
- specific_legitimate: concrete, time-bound, credible need clearly tied to a real task or obligation.
- plausible: somewhat reasonable but softer, less concrete, or mildly self-justifying.
- vague: generic, hand-wavy, or missing actionable detail.
- low_legitimacy: obvious dodge, contradiction, or attempt to game the system.

Output rules: single word only. No punctuation. No quotes.`;
}

export function classificationUserMessage(statedReason: string): string {
  return `User reason:\n${statedReason}`;
}

export function coachGateUserMessage(args: {
  stated_reason: string;
  classification: string;
  time_granted_seconds: number;
  active_non_negotiable: string | null;
}): string {
  const nn = args.active_non_negotiable?.trim() || "(none provided)";
  return [
    `User typed reason: """${args.stated_reason}"""`,
    `Classifier label: ${args.classification}`,
    `Time grant (seconds): ${args.time_granted_seconds}`,
    `Active non-negotiable context: ${nn}`,
    ``,
    `Write the Gate reply: max 2 sentences. Reference their actual words. Name the time grant in plain language (seconds is fine).`,
  ].join("\n");
}
