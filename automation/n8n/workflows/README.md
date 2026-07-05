# n8n Workflows

Planned workflows:

- Email invoice intake: watch inbox, download attachments, and capture `email_id` plus source snippets.
- Invoice extraction: send document text or OCR output to the LLM prompt contract.
- Supabase sync: insert rows into `invoices` with `type` as `income` or `expense`.

Export production workflows as JSON into this folder once they are built in n8n.
