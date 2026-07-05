import "@supabase/functions-js/edge-runtime.d.ts";
import { callClaude, ClaudeError } from "../_shared/anthropic.ts";

type ExtractInvoiceRequest = {
  email_id?: unknown;
  raw_text?: unknown;
  attachment_text?: unknown;
  received_at?: unknown;
};

type ExtractedInvoice = {
  vendor_name: string | null;
  amount: number | null;
  currency: string | null;
  type: "income" | "expense";
  category: string | null;
  issue_date: string | null;
  due_date: string | null;
  confidence: number;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonHeaders = {
  ...corsHeaders,
  "Content-Type": "application/json",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const body = (await req.json()) as ExtractInvoiceRequest;
    const input = validateRequest(body);
    const claudeText = await callClaude({
      system:
        "You extract invoice data for InboxCFO. Return ONLY valid JSON. No markdown, no prose, no code fences.",
      prompt: buildPrompt(input),
      maxTokens: 600,
      temperature: 0,
    });
    const extracted = parseClaudeJson(claudeText);

    return jsonResponse(normalizeInvoice(extracted));
  } catch (error) {
    if (error instanceof RequestError) {
      return jsonResponse({ error: error.message }, error.status);
    }

    if (error instanceof ClaudeError) {
      return jsonResponse({ error: error.message }, error.status);
    }

    return jsonResponse({
      error: error instanceof Error ? error.message : "Unexpected error",
    }, 500);
  }
});

class RequestError extends Error {
  constructor(
    message: string,
    readonly status = 400,
  ) {
    super(message);
    this.name = "RequestError";
  }
}

function validateRequest(body: ExtractInvoiceRequest) {
  const rawText = stringOrEmpty(body.raw_text);
  const attachmentText = stringOrEmpty(body.attachment_text);

  if (!isString(body.email_id) || body.email_id.trim().length === 0) {
    throw new RequestError("email_id is required");
  }

  if (!rawText && !attachmentText) {
    throw new RequestError("raw_text or attachment_text is required");
  }

  return {
    email_id: body.email_id.trim(),
    raw_text: rawText,
    attachment_text: attachmentText,
    received_at: isString(body.received_at) ? body.received_at.trim() : null,
  };
}

function buildPrompt(input: ReturnType<typeof validateRequest>) {
  return `Extract the invoice fields from this email and attachment text.

Return exactly this JSON shape:
{
  "vendor_name": string | null,
  "amount": number | null,
  "currency": string | null,
  "type": "income" | "expense", 
  "category": string | null,
  "issue_date": "YYYY-MM-DD" | null,
  "due_date": "YYYY-MM-DD" | null,
  "confidence": number
}

Rules:
- type must be "income" if this document represents money coming IN to the user (a refund, a payment received, an invoice the user issued to a client).
- type must be "expense" if this document represents money going OUT (a bill, a receipt for a purchase, a subscription charge, a vendor invoice the user must pay).
- Return ONLY JSON that can be parsed by JSON.parse.
- Use the total amount due, not subtotal or tax, unless only one amount exists.
- Currency must be a 3-letter ISO code when possible.
- Dates must use YYYY-MM-DD. If only a relative due date is present, infer it from received_at.
- confidence must be between 0 and 1.
- Choose a concise category such as software, utilities, rent, payroll, insurance, taxes, travel, office, marketing, professional_services, or other.

Context:
email_id: ${input.email_id}
received_at: ${input.received_at ?? "unknown"}

raw_text:
${input.raw_text || "(empty)"}

attachment_text:
${input.attachment_text || "(empty)"}`;
}

function parseClaudeJson(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    throw new ClaudeError("Claude response was not valid JSON");
  }
}

function normalizeInvoice(value: unknown): ExtractedInvoice {
  if (!isRecord(value)) {
    throw new ClaudeError("Claude JSON response must be an object");
  }

  return {
    vendor_name: nullableString(value.vendor_name),
    amount: nullableNumber(value.amount),
    currency: nullableCurrency(value.currency),
    type: normalizeType(value.type),
    category: nullableString(value.category),
    issue_date: nullableDate(value.issue_date),
    due_date: nullableDate(value.due_date),
    confidence: clamp(nullableNumber(value.confidence) ?? 0, 0, 1),
  };
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isString(value: unknown): value is string {
  return typeof value === "string";
}

function stringOrEmpty(value: unknown) {
  return isString(value) ? value.trim() : "";
}

function nullableString(value: unknown) {
  return isString(value) && value.trim().length > 0 ? value.trim() : null;
}

function nullableNumber(value: unknown) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string") {
    const parsed = Number(value.replace(/[^0-9.-]/g, ""));
    return Number.isFinite(parsed) ? parsed : null;
  }

  return null;
}

function nullableCurrency(value: unknown) {
  const currency = nullableString(value)?.toUpperCase() ?? null;
  return currency && /^[A-Z]{3}$/.test(currency) ? currency : null;
}

function nullableDate(value: unknown) {
  const date = nullableString(value);
  return date && /^\d{4}-\d{2}-\d{2}$/.test(date) ? date : null;
}

function normalizeType(value: unknown) {
  const type = nullableString(value)?.toLowerCase() ?? "";
  return type === "income" || type === "expense" ? type : "expense";
}

function clamp(value: number, min: number, max: number) {
  return Math.min(Math.max(value, min), max);
}
