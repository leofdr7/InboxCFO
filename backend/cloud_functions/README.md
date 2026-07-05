# Cloud Functions

## `project-cashflow`

Node.js function in `backend/cloud_functions/project-cashflow.js`.

It:

1. Reads the latest `account_balance`.
2. Reads pending `invoices` due in the next 30 days.
3. Calculates daily projected income, expenses, and balance.
4. Upserts rows into `cash_projections`.
5. Calls `RISK_EVALUATION_URL` for `medium` and `high` risk days.
6. Inserts rows into `alerts` when the risk response asks for an alert.

Run locally:

```bash
npm run project:cashflow
```

## Risk Endpoint Contract

Configure:

```bash
RISK_EVALUATION_URL=https://your-risk-service.example/evaluate-risk
RISK_EVALUATION_TOKEN=optional-bearer-token
```

Request body:

```json
{
  "projection_date": "2026-07-10",
  "projected_income": 0,
  "projected_expenses": 5200,
  "projected_balance": -1750,
  "risk_level": "high",
  "invoices_due": []
}
```

Expected response:

```json
{
  "should_alert": true,
  "severity": "high",
  "message": "Projected overdraft risk on 2026-07-10."
}
```

If `RISK_EVALUATION_URL` is not configured, the function creates fallback alerts for non-low risk days.
