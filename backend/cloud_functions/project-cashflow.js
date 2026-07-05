import 'dotenv/config';
import { pathToFileURL } from 'node:url';
import { createClient } from '@supabase/supabase-js';

const REQUIRED_ENV = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
const WARNING_BALANCE = Number(process.env.CASHFLOW_WARNING_BALANCE ?? 1000);
const RISK_ENDPOINT = process.env.RISK_EVALUATION_URL;
const RISK_ENDPOINT_TOKEN = process.env.RISK_EVALUATION_TOKEN;

function assertEnv() {
  const missing = REQUIRED_ENV.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}

function getSupabaseClient() {
  assertEnv();

  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    },
  );
}

function addDays(date, days) {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function toIsoDate(date) {
  return date.toISOString().slice(0, 10);
}

function toNumber(value) {
  return Number.parseFloat(value ?? 0);
}

function calculateRiskLevel(projectedBalance) {
  if (projectedBalance < 0) {
    return 'high';
  }

  if (projectedBalance < WARNING_BALANCE) {
    return 'medium';
  }

  return 'low';
}

async function fetchRiskEvaluation(payload) {
  if (!RISK_ENDPOINT) {
    return {
      should_alert: payload.risk_level !== 'low',
      severity: payload.risk_level,
      message: `Projected balance risk on ${payload.projection_date}: $${payload.projected_balance.toFixed(2)}.`,
    };
  }

  const headers = {
    'content-type': 'application/json',
  };

  if (RISK_ENDPOINT_TOKEN) {
    headers.authorization = `Bearer ${RISK_ENDPOINT_TOKEN}`;
  }

  const response = await fetch(RISK_ENDPOINT, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`Risk endpoint returned ${response.status}: ${await response.text()}`);
  }

  return response.json();
}

async function recordProcessingError(supabase, emailId, errorMessage, rawPayload) {
  await supabase.from('processing_errors').insert({
    email_id: emailId,
    error_message: errorMessage,
    raw_payload: typeof rawPayload === 'string' ? rawPayload : JSON.stringify(rawPayload),
  });
}

async function getCurrentBalance(supabase) {
  const { data, error } = await supabase
    .from('account_balance')
    .select('current_balance')
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    throw new Error(`Could not load account balance: ${error.message}`);
  }

  return toNumber(data?.current_balance);
}

async function getPendingInvoices(supabase, startDate, endDate) {
  const { data, error } = await supabase
    .from('invoices')
    .select('id,email_id,vendor_name,amount,currency,type,category,due_date,confidence')
    .eq('status', 'pending')
    .gte('due_date', startDate)
    .lte('due_date', endDate)
    .order('due_date', { ascending: true });

  if (error) {
    throw new Error(`Could not load invoices: ${error.message}`);
  }

  return data ?? [];
}

function groupInvoicesByDueDate(invoices) {
  return invoices.reduce((byDate, invoice) => {
    byDate[invoice.due_date] ??= [];
    byDate[invoice.due_date].push(invoice);
    return byDate;
  }, {});
}

async function replaceAlertsForWindow(supabase, startDate, endDate) {
  const { error } = await supabase
    .from('alerts')
    .delete()
    .gte('alert_date', startDate)
    .lte('alert_date', endDate);

  if (error) {
    throw new Error(`Could not clear alerts: ${error.message}`);
  }
}

async function upsertProjection(supabase, projection) {
  const { data, error } = await supabase
    .from('cash_projections')
    .upsert(projection, { onConflict: 'projection_date' })
    .select('id,projection_date,projected_income,projected_expenses,projected_balance,risk_level')
    .single();

  if (error) {
    throw new Error(`Could not upsert projection ${projection.projection_date}: ${error.message}`);
  }

  return data;
}

async function maybeCreateAlert(supabase, projection, invoicesDue) {
  if (projection.risk_level === 'low') {
    return null;
  }

  const payload = {
    projection_date: projection.projection_date,
    projected_income: toNumber(projection.projected_income),
    projected_expenses: toNumber(projection.projected_expenses),
    projected_balance: toNumber(projection.projected_balance),
    risk_level: projection.risk_level,
    invoices_due: invoicesDue,
  };

  let evaluation;

  try {
    evaluation = await fetchRiskEvaluation(payload);
  } catch (error) {
    await recordProcessingError(supabase, 'project-cashflow', error.message, payload);
    evaluation = {
      should_alert: true,
      severity: projection.risk_level,
      message: `Risk evaluation failed, but projected balance is $${payload.projected_balance.toFixed(2)} on ${projection.projection_date}.`,
    };
  }

  if (evaluation?.should_alert === false) {
    return null;
  }

  const alert = {
    alert_date: projection.projection_date,
    severity: evaluation?.severity ?? projection.risk_level,
    message:
      evaluation?.message ??
      `Projected ${projection.risk_level} cash-flow risk: $${payload.projected_balance.toFixed(2)} balance.`,
    related_projection_id: projection.id,
  };

  const { data, error } = await supabase
    .from('alerts')
    .insert(alert)
    .select('id,alert_date,severity,message,related_projection_id')
    .single();

  if (error) {
    throw new Error(`Could not insert alert: ${error.message}`);
  }

  return data;
}

export async function runProjectCashflow() {
  const supabase = getSupabaseClient();
  const today = new Date();
  const startDate = toIsoDate(addDays(today, 1));
  const endDate = toIsoDate(addDays(today, 30));

  const startingBalance = await getCurrentBalance(supabase);
  const invoices = await getPendingInvoices(supabase, startDate, endDate);
  const invoicesByDate = groupInvoicesByDueDate(invoices);

  await replaceAlertsForWindow(supabase, startDate, endDate);

  let runningBalance = startingBalance;
  const projections = [];
  const alerts = [];

  for (let day = 1; day <= 30; day += 1) {
    const projectionDate = toIsoDate(addDays(today, day));
    const invoicesDue = invoicesByDate[projectionDate] ?? [];

    const projectedIncome = invoicesDue
      .filter((invoice) => invoice.type === 'income')
      .reduce((sum, invoice) => sum + toNumber(invoice.amount), 0);

    const projectedExpenses = invoicesDue
      .filter((invoice) => invoice.type === 'expense')
      .reduce((sum, invoice) => sum + toNumber(invoice.amount), 0);

    runningBalance += projectedIncome - projectedExpenses;

    const projection = await upsertProjection(supabase, {
      projection_date: projectionDate,
      projected_income: projectedIncome,
      projected_expenses: projectedExpenses,
      projected_balance: runningBalance,
      risk_level: calculateRiskLevel(runningBalance),
      created_at: new Date().toISOString(),
    });

    projections.push(projection);

    const alert = await maybeCreateAlert(supabase, projection, invoicesDue);
    if (alert) {
      alerts.push(alert);
    }
  }

  return {
    start_date: startDate,
    end_date: endDate,
    starting_balance: startingBalance,
    projections_created: projections.length,
    alerts_created: alerts.length,
    projections,
    alerts,
  };
}

export async function projectCashflow(req, res) {
  try {
    const result = await runProjectCashflow();
    res.status(200).json(result);
  } catch (error) {
    console.error(error);
    res.status(500).json({
      error: error.message,
    });
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  runProjectCashflow()
    .then((result) => {
      console.log(JSON.stringify(result, null, 2));
    })
    .catch((error) => {
      console.error(error.message);
      process.exit(1);
    });
}
