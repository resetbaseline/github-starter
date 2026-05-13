/** Gate callout if many triggers today, or high usage vs stated reason on a "trusted" classification. */
export function gateCalloutWarranted(args: {
  gateTriggersCountOnDay: number;
  triggersToday: Array<{ usage_ratio: number | null; reason_classification: string | null }>;
}): boolean {
  if (args.gateTriggersCountOnDay >= 5) return true;
  return args.triggersToday.some((t) => {
    const ur = t.usage_ratio;
    if (ur == null || ur <= 0.8) return false;
    const c = (t.reason_classification ?? "").trim();
    return c === "plausible" || c === "specific_legitimate";
  });
}

export function tomorrowAdjustmentWarranted(args: {
  dayStatus: string;
  goalsCount: number;
  goalsCompleted: number;
}): boolean {
  if (args.dayStatus === "lost") return true;
  if (args.goalsCount <= 0) return false;
  return args.goalsCompleted < Math.ceil(args.goalsCount * 0.5);
}
