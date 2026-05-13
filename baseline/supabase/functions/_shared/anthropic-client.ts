const ANTHROPIC_MESSAGES_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";

export type AnthropicMessage = { role: "user" | "assistant"; content: string };

export type ClaudeResult = {
  content: string;
  inputTokens: number;
  outputTokens: number;
};

/** Structured error for Anthropic HTTP failures (parse thrown message JSON). */
export type AnthropicRequestError = {
  ok: false;
  status: number;
  type: "anthropic_error";
  message: string;
  body: unknown;
};

function requireApiKey(): string {
  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key || key.trim() === "") {
    throw new Error(
      "ANTHROPIC_API_KEY is missing. Create a key at https://console.anthropic.com/ → API keys, " +
        "then set ANTHROPIC_API_KEY in baseline/.env.local (local) or Edge Function secrets (production).",
    );
  }
  return key;
}

function extractErrorMessage(body: unknown): string {
  if (body && typeof body === "object" && "error" in body) {
    const err = (body as { error?: { message?: string; type?: string } }).error;
    if (err?.message) return err.message;
  }
  return "Anthropic API request failed";
}

async function callModel(
  model: string,
  system: string,
  messages: AnthropicMessage[],
  maxTokens: number,
): Promise<ClaudeResult> {
  const apiKey = requireApiKey();
  const res = await fetch(ANTHROPIC_MESSAGES_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": ANTHROPIC_VERSION,
    },
    body: JSON.stringify({
      model,
      max_tokens: maxTokens,
      system,
      messages,
    }),
  });

  let body: unknown = null;
  try {
    body = await res.json();
  } catch {
    body = null;
  }

  if (!res.ok) {
    const payload: AnthropicRequestError = {
      ok: false,
      status: res.status,
      type: "anthropic_error",
      message: extractErrorMessage(body),
      body,
    };
    throw new Error(JSON.stringify(payload));
  }

  const contentBlocks = (body as { content?: Array<{ type?: string; text?: string }> })?.content ?? [];
  const content = contentBlocks
    .filter((b) => b?.type === "text")
    .map((b) => b.text ?? "")
    .join("");

  const usage = (body as { usage?: { input_tokens?: number; output_tokens?: number } })?.usage;

  return {
    content,
    inputTokens: typeof usage?.input_tokens === "number" ? usage.input_tokens : 0,
    outputTokens: typeof usage?.output_tokens === "number" ? usage.output_tokens : 0,
  };
}

/** Default fast model for Gate + most Coach turns. */
export function callHaiku(
  system: string,
  messages: AnthropicMessage[],
  maxTokens: number,
): Promise<ClaudeResult> {
  return callModel("claude-haiku-4-5", system, messages, maxTokens);
}

/** Deeper reasoning for insights / check-in style sessions. */
export function callSonnet(
  system: string,
  messages: AnthropicMessage[],
  maxTokens: number,
): Promise<ClaudeResult> {
  return callModel("claude-sonnet-4-6", system, messages, maxTokens);
}
