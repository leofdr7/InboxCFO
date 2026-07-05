# Backend API

This folder will contain the API service for InboxCFO.

Initial responsibilities:

- Accept invoice data extracted from n8n or LLM pipelines.
- Validate organization access before reading or writing financial records.
- Serve invoice and cash flow data to the dashboard.

Use the schema in `database/schema/schema.sql` as the source of truth for the first endpoints.
