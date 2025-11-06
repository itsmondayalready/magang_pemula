# SQL Seeds for Kebencanaan

This folder contains SQL scripts to seed normalized kebencanaan tables in Supabase.

Tables used (normalized):
- public.kebencanaan_rekap
- public.kebencanaan_rt
- public.kebencanaan_bantuan
- public.kebencanaan_penanganan

## How to run

Option A — Supabase SQL Editor:
1. Open your Supabase project Dashboard.
2. Go to SQL > New query.
3. Paste the content of the desired seed file (e.g., `kebencanaan_seed_69696969.sql`).
4. Run. If RLS is enabled, the Dashboard SQL editor uses a service role and should succeed.

Option B — psql (service role):
- Ensure your `DATABASE_URL` (service role) is set. Then:

```bash
psql "$DATABASE_URL" -f docs/sql/kebencanaan_seed_69696969.sql
```

## Notes
- The script expects a row in `public.desa` with the matching `kode_wilayah`. If it's missing, create it first or adjust the script to insert it.
- The app queries with `jenis='banjir'` by default, so seeds use `banjir`.
- If you have RLS enabled for these tables and want to read the data from the app, ensure you have `SELECT` policies that allow your anon key to read rows for the target desa.
- Feel free to duplicate an existing seed and adjust values (periode, RT rows, bantuan items, penanganan steps).
