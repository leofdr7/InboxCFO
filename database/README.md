# Database

InboxCFO uses Supabase/Postgres for the hackathon backend data layer.

## Setup

1. Create a Supabase project.
2. Open the Supabase SQL editor.
3. Run `database/schema/schema.sql`.
4. Run `database/seed/seed.sql` to load demo data.
5. Run `npm run project:cashflow` to generate 30-day projections and alerts.

Script-based seed:

```bash
cp .env.example .env
npm install
npm run seed:demo
```

## Tables

- `invoices`: extracted income/expense invoices from email.
- `account_balance`: current cash balance snapshot.
- `cash_projections`: daily 30-day projected balances.
- `alerts`: risk messages linked to risky projection days.
- `processing_errors`: failures from ingestion or risk evaluation.

## Frontend Notes

The schema enables public read policies for demo speed. Frontend teammates can read:

- pending invoices from `invoices`
- latest balance from `account_balance`
- chart data from `cash_projections`
- warnings from `alerts`

Tighten RLS before production.
