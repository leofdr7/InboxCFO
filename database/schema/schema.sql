-- InboxCFO hackathon schema for Supabase/Postgres.
-- Run this file first in the Supabase SQL editor.

create extension if not exists pgcrypto;

create table if not exists invoices (
  id uuid primary key default gen_random_uuid(),
  email_id text,
  vendor_name text,
  amount numeric(12, 2) not null check (amount >= 0),
  currency text not null default 'USD',
  type text not null check (type in ('income', 'expense')),
  category text,
  issue_date date,
  due_date date not null,
  status text not null default 'pending',
  confidence numeric(5, 2) check (confidence is null or (confidence >= 0 and confidence <= 1)),
  raw_snippet text,
  created_at timestamptz not null default now()
);

create table if not exists account_balance (
  id uuid primary key default gen_random_uuid(),
  current_balance numeric(12, 2) not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists cash_projections (
  id uuid primary key default gen_random_uuid(),
  projection_date date not null unique,
  projected_income numeric(12, 2) not null default 0,
  projected_expenses numeric(12, 2) not null default 0,
  projected_balance numeric(12, 2) not null default 0,
  risk_level text not null default 'low',
  created_at timestamptz not null default now()
);

create table if not exists alerts (
  id uuid primary key default gen_random_uuid(),
  alert_date date not null,
  severity text not null,
  message text not null,
  related_projection_id uuid references cash_projections(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists processing_errors (
  id uuid primary key default gen_random_uuid(),
  email_id text,
  error_message text not null,
  raw_payload text,
  created_at timestamptz not null default now()
);

create index if not exists invoices_due_date_idx on invoices(due_date);
create index if not exists invoices_status_due_date_idx on invoices(status, due_date);
create index if not exists invoices_type_idx on invoices(type);
create index if not exists cash_projections_projection_date_idx on cash_projections(projection_date);
create index if not exists alerts_alert_date_idx on alerts(alert_date);
create index if not exists alerts_related_projection_id_idx on alerts(related_projection_id);
create index if not exists processing_errors_email_id_idx on processing_errors(email_id);

-- Simple hackathon-friendly read access for frontend demos.
-- Tighten these policies before production.
alter table invoices enable row level security;
alter table account_balance enable row level security;
alter table cash_projections enable row level security;
alter table alerts enable row level security;
alter table processing_errors enable row level security;

drop policy if exists "public read invoices" on invoices;
create policy "public read invoices"
on invoices for select
using (true);

drop policy if exists "public read account balance" on account_balance;
create policy "public read account balance"
on account_balance for select
using (true);

drop policy if exists "public read cash projections" on cash_projections;
create policy "public read cash projections"
on cash_projections for select
using (true);

drop policy if exists "public read alerts" on alerts;
create policy "public read alerts"
on alerts for select
using (true);

drop policy if exists "public read processing errors" on processing_errors;
create policy "public read processing errors"
on processing_errors for select
using (true);
