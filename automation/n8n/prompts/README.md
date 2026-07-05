# n8n Prompt Usage

Store n8n-specific prompt notes here when workflows need a stable extraction format.

The canonical extraction shape is documented in `automation/llm/prompts.md`. n8n workflows should pass model output to Supabase only after validating required fields such as `email_id`, `vendor_name`, `amount`, `type`, `due_date`, and `confidence`.
