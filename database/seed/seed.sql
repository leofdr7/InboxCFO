-- InboxCFO demo seed.
-- Run after database/schema/schema.sql.
-- Creates one starting account balance and 12 pending invoices due in the next 30 days.

truncate table alerts restart identity cascade;
truncate table cash_projections restart identity cascade;
truncate table processing_errors restart identity cascade;
truncate table invoices restart identity cascade;
truncate table account_balance restart identity cascade;

insert into account_balance (id, current_balance, updated_at)
values (
  '00000000-0000-0000-0000-000000000001',
  3250.00,
  now()
);

insert into invoices (
  id,
  email_id,
  vendor_name,
  amount,
  currency,
  type,
  category,
  issue_date,
  due_date,
  status,
  confidence,
  raw_snippet
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'email-001',
    'Acme Retail Group',
    4200.00,
    'USD',
    'income',
    'sales',
    current_date - interval '8 days',
    current_date + interval '3 days',
    'pending',
    0.94,
    'Invoice INV-001 due in 3 days for Acme Retail Group.'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'email-002',
    'CloudOps Hosting',
    1800.00,
    'USD',
    'expense',
    'hosting',
    current_date - interval '12 days',
    current_date + interval '4 days',
    'pending',
    0.91,
    'CloudOps monthly infrastructure bill.'
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    'email-003',
    'Payroll Provider',
    5200.00,
    'USD',
    'expense',
    'payroll',
    current_date - interval '15 days',
    current_date + interval '7 days',
    'pending',
    0.89,
    'Payroll debit scheduled for next week.'
  ),
  (
    '10000000-0000-0000-0000-000000000004',
    'email-004',
    'Northwind Foods',
    2600.00,
    'USD',
    'income',
    'sales',
    current_date - interval '10 days',
    current_date + interval '9 days',
    'pending',
    0.88,
    'Payment expected from Northwind Foods.'
  ),
  (
    '10000000-0000-0000-0000-000000000005',
    'email-005',
    'Office Lease LLC',
    2400.00,
    'USD',
    'expense',
    'rent',
    current_date - interval '20 days',
    current_date + interval '12 days',
    'pending',
    0.96,
    'Office lease invoice due this month.'
  ),
  (
    '10000000-0000-0000-0000-000000000006',
    'email-006',
    'Stripe Payout',
    3100.00,
    'USD',
    'income',
    'sales',
    current_date - interval '2 days',
    current_date + interval '14 days',
    'pending',
    0.83,
    'Expected Stripe payout based on invoice batch.'
  ),
  (
    '10000000-0000-0000-0000-000000000007',
    'email-007',
    'AdPlatform Ads',
    1600.00,
    'USD',
    'expense',
    'marketing',
    current_date - interval '5 days',
    current_date + interval '15 days',
    'pending',
    0.86,
    'Paid ads invoice for launch campaign.'
  ),
  (
    '10000000-0000-0000-0000-000000000008',
    'email-008',
    'Contoso Marketplace',
    1900.00,
    'USD',
    'income',
    'sales',
    current_date - interval '6 days',
    current_date + interval '18 days',
    'pending',
    0.90,
    'Marketplace settlement expected.'
  ),
  (
    '10000000-0000-0000-0000-000000000009',
    'email-009',
    'Legal Partners',
    2200.00,
    'USD',
    'expense',
    'legal',
    current_date - interval '14 days',
    current_date + interval '20 days',
    'pending',
    0.87,
    'Legal services invoice.'
  ),
  (
    '10000000-0000-0000-0000-000000000010',
    'email-010',
    'Enterprise Customer A',
    4800.00,
    'USD',
    'income',
    'sales',
    current_date - interval '18 days',
    current_date + interval '24 days',
    'pending',
    0.92,
    'Enterprise subscription invoice.'
  ),
  (
    '10000000-0000-0000-0000-000000000011',
    'email-011',
    'Hardware Supplier',
    3500.00,
    'USD',
    'expense',
    'equipment',
    current_date - interval '9 days',
    current_date + interval '25 days',
    'pending',
    0.84,
    'Laptop refresh invoice.'
  ),
  (
    '10000000-0000-0000-0000-000000000012',
    'email-012',
    'Consulting Client B',
    2900.00,
    'USD',
    'income',
    'consulting',
    current_date - interval '7 days',
    current_date + interval '29 days',
    'pending',
    0.89,
    'Consulting milestone payment.'
  );
