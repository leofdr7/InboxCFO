# API Notes

The API layer is not implemented yet. The first endpoints should match the database model and support the dashboard without exposing Supabase service credentials.

## Planned Endpoints

- `POST /ingestion/email`: receive parsed email metadata and extracted invoice fields.
- `GET /invoices`: list pending income and expense invoices.
- `GET /cash-projections`: return 30-day forecast rows grouped by date.
- `GET /alerts`: return projected cash risk alerts.
- `PATCH /invoices/:id/status`: update invoice payment status.

## Auth

Backend-only jobs may use `SUPABASE_SERVICE_ROLE_KEY`. Client applications must not use that key.
