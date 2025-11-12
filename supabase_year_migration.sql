-- ===========================================
-- YEAR SELECTION MIGRATION FOR SUPABASE
-- ===========================================
-- Run this script in Supabase SQL Editor to add year columns
-- Required for year selection feature in Flutter app

-- Add year columns to tables that don't have them (default to 2025)
ALTER TABLE aparatur_desa ADD COLUMN IF NOT EXISTS year INTEGER DEFAULT 2025;
ALTER TABLE desa_profile ADD COLUMN IF NOT EXISTS year INTEGER DEFAULT 2025;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_kependudukan_tahun ON kependudukan(tahun);
CREATE INDEX IF NOT EXISTS idx_kesehatan_tahun ON kesehatan(tahun);
CREATE INDEX IF NOT EXISTS idx_infrastruktur_year ON infrastruktur(year);
CREATE INDEX IF NOT EXISTS idx_pendidikan_year ON pendidikan(year);
CREATE INDEX IF NOT EXISTS idx_kebencanaan_period_end ON kebencanaan_rekap(period_end);
CREATE INDEX IF NOT EXISTS idx_aparatur_year ON aparatur_desa(year);
CREATE INDEX IF NOT EXISTS idx_desa_profile_year ON desa_profile(year);

-- Update existing records to have year 2025 if year is null
UPDATE aparatur_desa SET year = 2025 WHERE year IS NULL;
UPDATE desa_profile SET year = 2025 WHERE year IS NULL;

-- ===========================================
-- UPDATE ALL EXISTING DATA TO YEAR 2025
-- ===========================================
-- Uncomment and run this section if you want to set ALL existing data to year 2025

-- Update all existing data to year 2025
UPDATE kependudukan SET tahun = 2025 WHERE tahun IS NOT NULL;
UPDATE kesehatan SET tahun = 2025 WHERE tahun IS NOT NULL;
UPDATE infrastruktur SET year = 2025 WHERE year IS NOT NULL;
UPDATE pendidikan SET year = 2025 WHERE year IS NOT NULL;
UPDATE aparatur_desa SET year = 2025 WHERE year IS NOT NULL;
UPDATE desa_profile SET year = 2025 WHERE year IS NOT NULL;

-- For kebencanaan_rekap, update period_end to 2025 dates
UPDATE kebencanaan_rekap SET
  period_start = DATE '2025-01-01',
  period_end = DATE '2025-12-31',
  periode_date = DATE '2025-12-31'
WHERE period_end IS NOT NULL;

-- ===========================================
-- VERIFICATION QUERY (Run this after migration)
-- ===========================================
-- SELECT
--     t.table_name,
--     c.column_name,
--     c.data_type
-- FROM information_schema.tables t
-- LEFT JOIN information_schema.columns c ON t.table_name = c.table_name
-- WHERE t.table_schema = 'public'
--     AND t.table_name IN ('kependudukan', 'kesehatan', 'infrastruktur', 'pendidikan', 'kebencanaan_rekap', 'aparatur_desa', 'desa_profile')
--     AND c.column_name IN ('tahun', 'year', 'period_end')
-- ORDER BY t.table_name, c.column_name;