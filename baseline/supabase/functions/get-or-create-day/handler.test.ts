import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { getOrCreateDay } from "./handler.ts";

Deno.test("getOrCreateDay invalid timezone", async () => {
  const mock = {} as unknown as SupabaseClient;
  const r = await getOrCreateDay(mock, "u1", "Not/AZone", new Date());
  assertEquals(r.data, null);
  assertEquals(r.error?.code, "invalid_timezone");
});

Deno.test("getOrCreateDay loads existing day, goals, timers, yesterday intention", async () => {
  const today = "2026-06-15";
  const yesterday = "2026-06-14";

  const mock = {
    from(table: string) {
      if (table === "goals") {
        return {
          select: () => ({
            eq: () => ({
              order: () => Promise.resolve({ data: [{ id: "g1", order_index: 0 }], error: null }),
            }),
          }),
        };
      }
      if (table === "timers") {
        return {
          select: () => ({
            eq: () => Promise.resolve({ data: [{ id: "t1" }], error: null }),
          }),
        };
      }
      if (table === "days") {
        return {
          select: () => ({
            eq: (col: string, val: unknown) => ({
              maybeSingle: () => {
                if (col === "date" && val === today) {
                  return Promise.resolve({
                    data: { id: "d1", user_id: "u1", date: today, status: "in_progress" },
                    error: null,
                  });
                }
                if (col === "date" && val === yesterday) {
                  return Promise.resolve({ data: { tomorrow_intention: "Plan" }, error: null });
                }
                return Promise.resolve({ data: null, error: null });
              },
            }),
          }),
        };
      }
      throw new Error(`unexpected table ${table}`);
    },
  } as unknown as SupabaseClient;

  const r = await getOrCreateDay(mock, "u1", "UTC", new Date(`${today}T12:00:00Z`));
  assertEquals(r.error, null);
  assertEquals(r.data?.day["id"], "d1");
  assertEquals(r.data?.goals.length, 1);
  assertEquals(r.data?.timers.length, 1);
  assertEquals(r.data?.yesterday_intention, "Plan");
});

Deno.test("getOrCreateDay inserts when row missing", async () => {
  const today = "2026-07-01";
  const yesterday = "2026-06-30";
  let insertCalled = false;

  const mock = {
    from(table: string) {
      if (table === "goals") {
        return {
          select: () => ({
            eq: () => ({
              order: () => Promise.resolve({ data: [], error: null }),
            }),
          }),
        };
      }
      if (table === "timers") {
        return {
          select: () => ({
            eq: () => Promise.resolve({ data: [], error: null }),
          }),
        };
      }
      if (table === "days") {
        return {
          select: () => ({
            eq: (col: string, val: unknown) => ({
              maybeSingle: () => {
                if (col === "date" && val === yesterday) {
                  return Promise.resolve({ data: null, error: null });
                }
                if (col === "date" && val === today) {
                  return Promise.resolve({
                    data: insertCalled
                      ? { id: "dnew", user_id: "u1", date: today }
                      : null,
                    error: null,
                  });
                }
                return Promise.resolve({ data: null, error: null });
              },
            }),
          }),
          insert: (_row: unknown) => ({
            select: () => ({
              maybeSingle: () => {
                insertCalled = true;
                return Promise.resolve({
                  data: { id: "dnew", user_id: "u1", date: today },
                  error: null,
                });
              },
            }),
          }),
        };
      }
      throw new Error(`unexpected table ${table}`);
    },
  } as unknown as SupabaseClient;

  const r = await getOrCreateDay(mock, "u1", "UTC", new Date(`${today}T15:00:00Z`));
  assertEquals(r.error, null);
  assertEquals(insertCalled, true);
  assertEquals(r.data?.day["id"], "dnew");
  assertEquals(r.data?.goals.length, 0);
});
