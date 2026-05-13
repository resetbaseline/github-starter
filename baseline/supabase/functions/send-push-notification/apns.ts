import { SignJWT, importPKCS8 } from "https://esm.sh/jose@5.9.6";

function apnsHost(): string {
  const raw = (Deno.env.get("APNS_USE_SANDBOX") ?? "").trim().toLowerCase();
  if (raw === "true" || raw === "1" || raw === "yes") return "api.sandbox.push.apple.com";
  return "api.push.apple.com";
}

let cachedToken: { value: string; expMs: number } | null = null;

export function apnsConfigured(): boolean {
  const kid = Deno.env.get("APNS_KEY_ID")?.trim();
  const iss = Deno.env.get("APNS_TEAM_ID")?.trim();
  const key = (Deno.env.get("APNS_SIGNING_KEY") ?? Deno.env.get("APNS_PRIVATE_KEY"))?.trim();
  const topic = Deno.env.get("APNS_BUNDLE_ID")?.trim();
  return Boolean(kid && iss && key && topic);
}

function requireApnsEnv(name: string): string {
  const v = Deno.env.get(name)?.trim();
  if (!v) throw new Error(`${name} must be set for APNs (Edge Function secrets or local env).`);
  return v;
}

function signingPem(): string {
  const s = Deno.env.get("APNS_SIGNING_KEY")?.trim();
  const p = Deno.env.get("APNS_PRIVATE_KEY")?.trim();
  const v = s || p;
  if (!v) throw new Error("APNS_SIGNING_KEY or APNS_PRIVATE_KEY must be set for APNs (.p8 PEM).");
  return v.replace(/\\n/g, "\n");
}

async function mintProviderJwt(): Promise<string> {
  const kid = requireApnsEnv("APNS_KEY_ID");
  const iss = requireApnsEnv("APNS_TEAM_ID");
  const pem = signingPem();
  const key = await importPKCS8(pem, "ES256");
  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid })
    .setIssuer(iss)
    .setIssuedAt()
    .setExpirationTime("50m")
    .sign(key);
}

export async function getApnsProviderJwt(): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expMs > now + 60_000) return cachedToken.value;
  try {
    const value = await mintProviderJwt();
    cachedToken = { value, expMs: now + 45 * 60 * 1000 };
    return value;
  } catch (e) {
    cachedToken = null;
    throw e;
  }
}

export type ApnsSendResult = {
  ok: boolean;
  status: number;
  unregistered?: boolean;
  error?: string;
};

export async function sendApnsAlert(args: {
  deviceToken: string;
  title: string;
  body: string;
  topic: string;
  badge?: number;
  sound?: string | null;
  baselinePayload?: Record<string, unknown>;
}): Promise<ApnsSendResult> {
  const provider = await getApnsProviderJwt();
  const host = apnsHost();
  const url = `https://${host}/3/device/${args.deviceToken}`;

  const aps: Record<string, unknown> = {
    alert: { title: args.title, body: args.body },
  };
  if (args.sound === undefined) {
    aps.sound = "default";
  } else if (args.sound !== null) {
    aps.sound = args.sound;
  }

  if (args.badge !== undefined) aps.badge = args.badge;

  const payload: Record<string, unknown> = { aps };
  if (args.baselinePayload && Object.keys(args.baselinePayload).length > 0) {
    payload.baseline = args.baselinePayload;
  }

  const res = await fetch(url, {
    method: "POST",
    headers: {
      authorization: `bearer ${provider}`,
      "apns-topic": args.topic,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const unregistered = res.status === 410;
  if (res.ok) return { ok: true, status: res.status };

  let errText = "";
  try {
    errText = await res.text();
  } catch {
    /* ignore */
  }
  return {
    ok: false,
    status: res.status,
    unregistered,
    error: errText.slice(0, 500) || res.statusText,
  };
}
