import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { callClaude, ClaudeError } from '../_shared/anthropic.ts'

type EvaluateRiskRequest = {
  projection_date?: unknown
  projected_income?: unknown
  projected_expenses?: unknown
  projected_balance?: unknown
  historical_balances?: unknown
}

type HistoricalBalance = {
  date: string | null
  balance: number
}

type RuleResult = {
  risk_level: 'low' | 'medium' | 'high'
  should_alert: boolean
  severity: 'info' | 'warning' | 'critical'
  reasons: string[]
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const jsonHeaders = {
  ...corsHeaders,
  'Content-Type': 'application/json',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  try {
    const body = (await req.json()) as EvaluateRiskRequest
    const input = validateRequest(body)
    const rules = evaluateRules(input)
    const message = await generateRiskMessage(input, rules)

    return jsonResponse({
      risk_level: rules.risk_level,
      should_alert: rules.should_alert,
      severity: rules.severity,
      message,
    })
  } catch (error) {
    if (error instanceof RequestError) {
      return jsonResponse({ error: error.message }, error.status)
    }

    if (error instanceof ClaudeError) {
      return jsonResponse({ error: error.message }, error.status)
    }

    return jsonResponse({ error: error instanceof Error ? error.message : 'Unexpected error' }, 500)
  }
})

class RequestError extends Error {
  constructor(
    message: string,
    readonly status = 400,
  ) {
    super(message)
    this.name = 'RequestError'
  }
}

function validateRequest(body: EvaluateRiskRequest) {
  const projectedIncome = requiredNumber(body.projected_income, 'projected_income')
  const projectedExpenses = requiredNumber(body.projected_expenses, 'projected_expenses')
  const projectedBalance = requiredNumber(body.projected_balance, 'projected_balance')

  if (!isString(body.projection_date) || body.projection_date.trim().length === 0) {
    throw new RequestError('projection_date is required')
  }

  return {
    projection_date: body.projection_date.trim(),
    projected_income: projectedIncome,
    projected_expenses: projectedExpenses,
    projected_balance: projectedBalance,
    historical_balances: normalizeHistoricalBalances(body.historical_balances),
  }
}

function evaluateRules(input: ReturnType<typeof validateRequest>): RuleResult {
  const reasons: string[] = []
  const expenseCoverageRatio = input.projected_expenses > 0
    ? input.projected_balance / input.projected_expenses
    : Number.POSITIVE_INFINITY
  const netCashFlow = input.projected_income - input.projected_expenses
  const trend = balanceTrend(input.historical_balances)

  if (input.projected_balance < 0) {
    reasons.push('Projected balance is negative.')
    return {
      risk_level: 'high',
      should_alert: true,
      severity: 'critical',
      reasons,
    }
  }

  if (expenseCoverageRatio < 0.25) {
    reasons.push('Projected balance covers less than 25% of projected expenses.')
  }

  if (netCashFlow < 0) {
    reasons.push('Projected expenses are higher than projected income.')
  }

  if (trend < 0) {
    reasons.push('Historical balances are trending downward.')
  }

  if (expenseCoverageRatio < 0.25 || (expenseCoverageRatio < 0.5 && netCashFlow < 0)) {
    return {
      risk_level: 'high',
      should_alert: true,
      severity: 'warning',
      reasons,
    }
  }

  if (expenseCoverageRatio < 0.5 || (trend < 0 && expenseCoverageRatio < 1)) {
    return {
      risk_level: 'medium',
      should_alert: true,
      severity: 'warning',
      reasons: reasons.length ? reasons : ['Cash buffer is narrowing.'],
    }
  }

  return {
    risk_level: 'low',
    should_alert: false,
    severity: 'info',
    reasons: reasons.length ? reasons : ['Projected balance remains healthy.'],
  }
}

async function generateRiskMessage(
  input: ReturnType<typeof validateRequest>,
  rules: RuleResult,
) {
  const text = await callClaude({
    system:
      'You write concise CFO-style cash-flow alerts for small businesses. Return only the final message text, no JSON and no markdown.',
    prompt: `Write one short, natural-language message for this cash-flow risk result.

Tone: clear, calm, useful. Mention the main reason and the projected date. Keep it under 35 words.

Risk result:
${JSON.stringify(rules, null, 2)}

Projection:
${JSON.stringify(input, null, 2)}`,
    maxTokens: 120,
    temperature: 0.2,
  })

  return text.replace(/^["']|["']$/g, '').trim()
}

function normalizeHistoricalBalances(value: unknown): HistoricalBalance[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value
    .map((item) => {
      if (typeof item === 'number' && Number.isFinite(item)) {
        return { date: null, balance: item }
      }

      if (isRecord(item)) {
        const balance = optionalNumber(item.balance)
        if (balance !== null) {
          return {
            date: isString(item.date) ? item.date : null,
            balance,
          }
        }
      }

      return null
    })
    .filter((item): item is HistoricalBalance => item !== null)
}

function balanceTrend(balances: HistoricalBalance[]) {
  if (balances.length < 2) {
    return 0
  }

  return balances[balances.length - 1].balance - balances[0].balance
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  })
}

function requiredNumber(value: unknown, field: string) {
  const number = optionalNumber(value)

  if (number === null) {
    throw new RequestError(`${field} must be a number`)
  }

  return number
}

function optionalNumber(value: unknown) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value
  }

  if (typeof value === 'string') {
    const parsed = Number(value.replace(/[^0-9.-]/g, ''))
    return Number.isFinite(parsed) ? parsed : null
  }

  return null
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function isString(value: unknown): value is string {
  return typeof value === 'string'
}
