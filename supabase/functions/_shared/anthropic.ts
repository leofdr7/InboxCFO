type ClaudeOptions = {
  system: string
  prompt: string
  maxTokens?: number
  temperature?: number
}

type AnthropicTextBlock = {
  type: 'text'
  text: string
}

type AnthropicResponse = {
  content?: AnthropicTextBlock[]
  error?: {
    message?: string
  }
}

const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
const ANTHROPIC_VERSION = '2023-06-01'
const DEFAULT_MODEL = 'claude-haiku-4-5'
const DEFAULT_TIMEOUT_MS = 20_000

export class ClaudeError extends Error {
  constructor(
    message: string,
    readonly status = 502,
  ) {
    super(message)
    this.name = 'ClaudeError'
  }
}

export async function callClaude(options: ClaudeOptions): Promise<string> {
  const apiKey = Deno.env.get('ANTHROPIC_API_KEY')

  if (!apiKey) {
    throw new ClaudeError('ANTHROPIC_API_KEY is not configured', 500)
  }

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS)

  try {
    const response = await fetch(ANTHROPIC_API_URL, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'anthropic-version': ANTHROPIC_VERSION,
        'content-type': 'application/json',
        'x-api-key': apiKey,
      },
      body: JSON.stringify({
        model: Deno.env.get('ANTHROPIC_MODEL') ?? DEFAULT_MODEL,
        max_tokens: options.maxTokens ?? 700,
        temperature: options.temperature ?? 0,
        system: options.system,
        messages: [
          {
            role: 'user',
            content: options.prompt,
          },
        ],
      }),
    })

    const data = (await response.json().catch(() => ({}))) as AnthropicResponse

    if (!response.ok) {
      throw new ClaudeError(
        data.error?.message ?? `Claude request failed with status ${response.status}`,
        response.status,
      )
    }

    const text = data.content?.find((block) => block.type === 'text')?.text?.trim()

    if (!text) {
      throw new ClaudeError('Claude returned an empty response')
    }

    return stripMarkdownFence(text)
  } catch (error) {
    if (error instanceof ClaudeError) {
      throw error
    }

    if (error instanceof DOMException && error.name === 'AbortError') {
      throw new ClaudeError('Claude request timed out')
    }

    throw new ClaudeError(error instanceof Error ? error.message : 'Claude request failed')
  } finally {
    clearTimeout(timeout)
  }
}

function stripMarkdownFence(text: string): string {
  const fenceMatch = text.match(/^```(?:json)?\s*\n?([\s\S]*?)\n?```$/)
  return fenceMatch ? fenceMatch[1].trim() : text
}