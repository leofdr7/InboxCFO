# LLM Prompts

Use this file to version prompts for invoice extraction and categorization.

## Invoice Extraction Contract

Return JSON with these fields:

```json
{
  "email_id": "string",
  "vendor_name": "string",
  "amount": 0,
  "currency": "USD",
  "type": "income | expense",
  "category": "string",
  "issue_date": "YYYY-MM-DD",
  "due_date": "YYYY-MM-DD",
  "confidence": 0.0,
  "raw_snippet": "short source text"
}
```

Prefer `null` for missing optional fields. Do not invent amounts when the source document is unclear.
