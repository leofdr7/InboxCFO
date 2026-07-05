# InboxCFO

AI-powered financial copilot that extracts invoices from email and predicts cash flow using Supabase, automation, LLMs, and Flutter.

## Hackathon Backend Status

The data backend is ready for frontend teammates to continue against stable Supabase tables.

Implemented:

- `database/schema/schema.sql` with `invoices`, `account_balance`, `cash_projections`, `alerts`, and `processing_errors`.
- `database/seed/seed.sql` with 12 demo invoices and an initial cash balance.
- `seed-demo.js` for script-based seeding through Supabase.
- `backend/cloud_functions/project-cashflow.js` to calculate 30-day cash projections and alerts.

## Quick Start

```bash
npm install
cp .env.example .env
```

Fill `.env` with Supabase values, then run:

```bash
npm run seed:demo
npm run project:cashflow
```

Or use Supabase SQL editor:

1. Run `database/schema/schema.sql`.
2. Run `database/seed/seed.sql`.
3. Run `npm run project:cashflow` to populate `cash_projections` and `alerts`.

## Frontend Tables

- `invoices`: pending income and expense invoices.
- `account_balance`: current balance.
- `cash_projections`: 30-day cash-flow chart source.
- `alerts`: risk messages for projected low/negative balance.

Do not commit `.env`; use `.env.example` as the template.
