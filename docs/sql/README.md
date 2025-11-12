# SQL Seeds and Migrations

This folder contains SQL scripts for seeding and migrating the Supabase database used by the Flutter application.

## Files

### Seed Files
- `kebencanaan_seed_6969.sql` - Sample kebencanaan data for desa code 6969
- `kebencanaan_seed_69696969.sql` - Sample kebencanaan data for desa code 69696969

## Year Selection Migration

**⚠️ IMPORTANT: Run the year migration BEFORE using the year selection feature**

The year selection feature requires specific database columns to work properly. Use the `supabase_year_migration.sql` file in the project root.

### Tables and Required Columns
- `kependudukan` - `tahun` (INTEGER) - already exists
- `kesehatan` - `tahun` (INTEGER) - already exists
- `infrastruktur` - `year` (INTEGER) - already exists
- `pendidikan` - `year` (INTEGER) - already exists
- `kebencanaan_rekap` - `period_end` (DATE) - already exists
- `aparatur_desa` - `year` (INTEGER) - **needs to be added**
- `desa_profile` - `year` (INTEGER) - **needs to be added**

### Running the Migration

1. Copy the content of `supabase_year_migration.sql` from the project root
2. Go to your Supabase Dashboard → SQL → New Query
3. Paste and run the script

### Verification

After running the migration, verify that all tables have the required columns by running the verification query included at the bottom of the migration file.

## Kebencanaan Seeds

The kebencanaan seed files populate normalized kebencanaan tables with sample data.

### Tables Used
- `public.kebencanaan_rekap` - Summary data
- `public.kebencanaan_rt` - RT-level details
- `public.kebencanaan_bantuan` - Aid distribution
- `public.kebencanaan_penanganan` - Handling procedures

### Running Seeds

Option A — Supabase SQL Editor:
1. Open your Supabase project Dashboard
2. Go to SQL > New query
3. Paste the content of the desired seed file
4. Run

Option B — psql:
```bash
psql "$DATABASE_URL" -f docs/sql/kebencanaan_seed_69696969.sql
```

## Notes
- Ensure the target `desa` record exists before running seeds
- The app queries with `jenis='banjir'` by default
- If RLS is enabled, ensure proper policies are set
- Year migration must be run before using year selection features
