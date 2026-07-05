# Scripts

Use this folder for project automation scripts that do not belong to the app runtime.

Current script entry points:

- `npm run seed:demo`: inserts demo data into Supabase using `seed-demo.js`.
- `npm run check:js`: validates JavaScript syntax for the demo script.

Keep secrets in `.env`; do not commit local credentials.
