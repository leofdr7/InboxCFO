# InboxCFO Architecture

InboxCFO is planned as a financial copilot that turns invoice emails into structured cash flow data.

## Components

- `automation/n8n`: email polling, attachment extraction, and workflow orchestration.
- `automation/llm`: prompt templates for invoice extraction and categorization.
- `backend/api`: API layer for ingestion, dashboard queries, and future integrations.
- `backend/cloud_functions`: Supabase Edge Functions or scheduled jobs.
- `database`: Supabase/Postgres schema and seed data.
- `frontend/flutter_dashboard`: dashboard UI for invoices, forecasts, and alerts.

## Data Flow

1. n8n receives or polls invoice emails.
2. Attachments and email metadata are sent to an extraction step.
3. Extracted invoice fields are saved into `invoices`.
4. Forecast rows are generated from due dates, direction, payment status, and confidence.
5. Flutter reads Supabase views/tables through the API or direct Supabase client.

## Security Notes

- Keep service role keys only in backend scripts, Supabase functions, or trusted automation.
- Flutter and browser code must use anon keys plus Row Level Security.
- `.env` is ignored; use `.env.example` as the template.
