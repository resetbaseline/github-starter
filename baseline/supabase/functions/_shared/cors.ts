/** CORS headers for all Baseline Edge Functions. */
export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type, x-client-info, apikey",
};

/** Return 200 for browser preflight. */
export function handleCorsPreflightRequest(): Response {
  return new Response("ok", { headers: corsHeaders });
}
