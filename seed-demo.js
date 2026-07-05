import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const requiredEnv = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
const missingEnv = requiredEnv.filter((key) => !process.env[key]);

if (missingEnv.length > 0) {
  console.error(`Missing required environment variables: ${missingEnv.join(', ')}`);
  console.error('Create .env from .env.example before running this script.');
  process.exit(1);
}

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  },
);

const today = new Date();

function isoDate(offsetDays) {
  const date = new Date(today);
  date.setDate(date.getDate() + offsetDays);
  return date.toISOString().slice(0, 10);
}

const accountBalance = {
  id: '00000000-0000-0000-0000-000000000001',
  current_balance: 3250,
  updated_at: new Date().toISOString(),
};

const invoices = [
  ['email-001', 'Acme Retail Group', 4200, 'income', 'sales', -8, 3, 0.94],
  ['email-002', 'CloudOps Hosting', 1800, 'expense', 'hosting', -12, 4, 0.91],
  ['email-003', 'Payroll Provider', 5200, 'expense', 'payroll', -15, 7, 0.89],
  ['email-004', 'Northwind Foods', 2600, 'income', 'sales', -10, 9, 0.88],
  ['email-005', 'Office Lease LLC', 2400, 'expense', 'rent', -20, 12, 0.96],
  ['email-006', 'Stripe Payout', 3100, 'income', 'sales', -2, 14, 0.83],
  ['email-007', 'AdPlatform Ads', 1600, 'expense', 'marketing', -5, 15, 0.86],
  ['email-008', 'Contoso Marketplace', 1900, 'income', 'sales', -6, 18, 0.9],
  ['email-009', 'Legal Partners', 2200, 'expense', 'legal', -14, 20, 0.87],
  ['email-010', 'Enterprise Customer A', 4800, 'income', 'sales', -18, 24, 0.92],
  ['email-011', 'Hardware Supplier', 3500, 'expense', 'equipment', -9, 25, 0.84],
  ['email-012', 'Consulting Client B', 2900, 'income', 'consulting', -7, 29, 0.89],
].map(([emailId, vendorName, amount, type, category, issueOffset, dueOffset, confidence], index) => ({
  id: `10000000-0000-0000-0000-${String(index + 1).padStart(12, '0')}`,
  email_id: emailId,
  vendor_name: vendorName,
  amount,
  currency: 'USD',
  type,
  category,
  issue_date: isoDate(issueOffset),
  due_date: isoDate(dueOffset),
  status: 'pending',
  confidence,
  raw_snippet: `${vendorName} ${type} invoice for $${amount}, due in ${dueOffset} days.`,
}));

async function deleteAll(table) {
  const { error } = await supabase.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000');
  if (error) {
    throw new Error(`${table} delete failed: ${error.message}`);
  }
}

async function insertOrThrow(table, rows) {
  const { error } = await supabase.from(table).insert(rows);
  if (error) {
    throw new Error(`${table} insert failed: ${error.message}`);
  }
}

try {
  await deleteAll('alerts');
  await deleteAll('cash_projections');
  await deleteAll('processing_errors');
  await deleteAll('invoices');
  await deleteAll('account_balance');

  await insertOrThrow('account_balance', accountBalance);
  await insertOrThrow('invoices', invoices);

  console.log('Seed complete: 12 invoices and initial account balance inserted.');
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
