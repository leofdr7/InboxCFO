# InboxCFO AI Edge Functions

These Supabase Edge Functions provide the hackathon AI layer:

- `extract-invoice`: extracts invoice fields from email and attachment text using Claude.
- `evaluate-risk`: evaluates cash-flow risk with deterministic rules and uses Claude only to write the final explanation.

## Environment

Create `supabase/functions/.env` locally:

```env
ANTHROPIC_API_KEY=sk-ant-...
# Optional. Defaults to claude-3-5-haiku-latest.
ANTHROPIC_MODEL=claude-3-5-haiku-latest
```

Do not commit `.env` files.

## Run Locally

```bash
supabase login
supabase link --project-ref <project-ref>
supabase functions serve --env-file supabase/functions/.env
```

Local endpoints:

- `http://127.0.0.1:54321/functions/v1/extract-invoice`
- `http://127.0.0.1:54321/functions/v1/evaluate-risk`

## Deploy

Set production secrets:

```bash
supabase secrets set --env-file supabase/functions/.env
```

Deploy both functions:

```bash
supabase functions deploy extract-invoice evaluate-risk
```

Remote endpoints:

- `https://<project-ref>.supabase.co/functions/v1/extract-invoice`
- `https://<project-ref>.supabase.co/functions/v1/evaluate-risk`

The current `supabase/config.toml` sets `verify_jwt = false` for quick hackathon demos. If you enable JWT verification later, include `apikey` and `Authorization: Bearer <token>` headers.

## Test `extract-invoice`

```bash
curl -X POST "http://127.0.0.1:54321/functions/v1/extract-invoice" \
  -H "Content-Type: application/json" \
  -d '{
    "email_id": "email_001",
    "raw_text": "Hi, attached is your July invoice from Acme Cloud.",
    "attachment_text": "Invoice #A-1001\nAcme Cloud LLC\nIssue Date: 2026-07-01\nDue Date: 2026-07-15\nTotal Due: USD 149.00",
    "received_at": "2026-07-04T10:00:00Z"
  }'
```

Expected response shape:

```json
{
  "vendor_name": "Acme Cloud LLC",
  "amount": 149,
  "currency": "USD",
  "type": "invoice",
  "category": "software",
  "issue_date": "2026-07-01",
  "due_date": "2026-07-15",
  "confidence": 0.95
}
```

## Test `evaluate-risk`

```bash
curl -X POST "http://127.0.0.1:54321/functions/v1/evaluate-risk" \
  -H "Content-Type: application/json" \
  -d '{
    "projection_date": "2026-07-31",
    "projected_income": 12000,
    "projected_expenses": 18000,
    "projected_balance": -2500,
    "historical_balances": [
      { "date": "2026-05-31", "balance": 9000 },
      { "date": "2026-06-30", "balance": 4200 }
    ]
  }'
```

Expected response shape:

```json
{
  "risk_level": "critical",
  "should_alert": true,
  "severity": 4,
  "message": "Your projected balance is negative by July 31, driven by expenses exceeding income. Review upcoming payments or bring forward receivables."
}
```

## Invoice Extraction Fixtures

Use these examples to validate the extractor. Claude output can vary slightly, but it should match the same field values and JSON shape.

### 1. SaaS invoice

Input text:

```text
Subject: Your Acme Cloud invoice
Invoice #A-1001
Acme Cloud LLC
Issue Date: July 1, 2026
Due Date: July 15, 2026
Subscription: Team plan
Subtotal: $139.00
Tax: $10.00
Total Due: USD 149.00
```

Expected JSON:

```json
{
  "vendor_name": "Acme Cloud LLC",
  "amount": 149,
  "currency": "USD",
  "type": "invoice",
  "category": "software",
  "issue_date": "2026-07-01",
  "due_date": "2026-07-15",
  "confidence": 0.95
}
```

### 2. Utility bill

Input text:

```text
Metro Electric
Statement date: 06/28/2026
Account 448921
Service period: Jun 1 - Jun 30
Amount due: $312.45
Payment due by 07/12/2026
```

Expected JSON:

```json
{
  "vendor_name": "Metro Electric",
  "amount": 312.45,
  "currency": "USD",
  "type": "invoice",
  "category": "utilities",
  "issue_date": "2026-06-28",
  "due_date": "2026-07-12",
  "confidence": 0.93
}
```

### 3. Rent invoice

Input text:

```text
North Loop Properties
Commercial Rent Invoice
Invoice date: 2026-07-01
Rent for Suite 410, July 2026
Please pay 4,800.00 USD by 2026-07-05.
```

Expected JSON:

```json
{
  "vendor_name": "North Loop Properties",
  "amount": 4800,
  "currency": "USD",
  "type": "invoice",
  "category": "rent",
  "issue_date": "2026-07-01",
  "due_date": "2026-07-05",
  "confidence": 0.96
}
```

### 4. Marketing services

Input text:

```text
BrightAds Studio
Invoice BA-7782
Issued: 2026-06-30
Campaign creative and landing page testing
Balance due: $1,250.00
Net 15
```

Expected JSON, assuming `received_at` is `2026-07-04T10:00:00Z`:

```json
{
  "vendor_name": "BrightAds Studio",
  "amount": 1250,
  "currency": "USD",
  "type": "invoice",
  "category": "marketing",
  "issue_date": "2026-06-30",
  "due_date": "2026-07-15",
  "confidence": 0.9
}
```

### 5. Contractor payroll

Input text:

```text
Invoice from Ana Gomez
Finance operations support, June 2026
Invoice date: June 29, 2026
Due on receipt
Total: $2,200.00 USD
```

Expected JSON:

```json
{
  "vendor_name": "Ana Gomez",
  "amount": 2200,
  "currency": "USD",
  "type": "invoice",
  "category": "payroll",
  "issue_date": "2026-06-29",
  "due_date": "2026-07-04",
  "confidence": 0.88
}
```

### 6. Insurance premium

Input text:

```text
ShieldSure Insurance
Premium Invoice
Policy: GL-2026-881
Invoice issued 2026-07-02
Payment due 2026-07-20
Total premium due: USD 685.75
```

Expected JSON:

```json
{
  "vendor_name": "ShieldSure Insurance",
  "amount": 685.75,
  "currency": "USD",
  "type": "invoice",
  "category": "insurance",
  "issue_date": "2026-07-02",
  "due_date": "2026-07-20",
  "confidence": 0.95
}
```

### 7. Office supplies receipt

Input text:

```text
PaperTrail Office Supply
Receipt 88219
Date: 2026-07-03
Printer paper, pens, shipping labels
Visa ending 4242
Total paid: $86.34
```

Expected JSON:

```json
{
  "vendor_name": "PaperTrail Office Supply",
  "amount": 86.34,
  "currency": "USD",
  "type": "receipt",
  "category": "office",
  "issue_date": "2026-07-03",
  "due_date": null,
  "confidence": 0.94
}
```

### 8. Professional services

Input text:

```text
LedgerLaw LLP
Invoice LL-4910
Matter: incorporation and contract review
Issued: 2026-06-25
Due: 2026-07-25
Amount Due: $3,750.00
```

Expected JSON:

```json
{
  "vendor_name": "LedgerLaw LLP",
  "amount": 3750,
  "currency": "USD",
  "type": "invoice",
  "category": "professional_services",
  "issue_date": "2026-06-25",
  "due_date": "2026-07-25",
  "confidence": 0.96
}
```

### 9. Travel invoice in EUR

Input text:

```text
EuroStay Hotels
Invoice ES-3392
Guest: InboxCFO Team
Invoice Date: 2026-07-02
Due Date: 2026-07-09
Total amount: EUR 918.20
```

Expected JSON:

```json
{
  "vendor_name": "EuroStay Hotels",
  "amount": 918.2,
  "currency": "EUR",
  "type": "invoice",
  "category": "travel",
  "issue_date": "2026-07-02",
  "due_date": "2026-07-09",
  "confidence": 0.95
}
```

### 10. Tax payment notice

Input text:

```text
State Department of Revenue
Quarterly Sales Tax Notice
Notice date: July 1, 2026
Payment due: July 31, 2026
Amount to remit: $1,104.60
```

Expected JSON:

```json
{
  "vendor_name": "State Department of Revenue",
  "amount": 1104.6,
  "currency": "USD",
  "type": "invoice",
  "category": "taxes",
  "issue_date": "2026-07-01",
  "due_date": "2026-07-31",
  "confidence": 0.92
}
```
