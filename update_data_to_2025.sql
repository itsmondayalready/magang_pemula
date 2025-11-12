-- ===========================================
-- QUICK FIX: Update All Data to 2025
-- ===========================================
-- Run this in Supabase SQL Editor to set ALL existing data to year 2025

-- Update all tables to year 2025
UPDATE kependudukan SET tahun = 2025 WHERE tahun IS NOT NULL;
UPDATE kesehatan SET tahun = 2025 WHERE tahun IS NOT NULL;
UPDATE infrastruktur SET year = 2025 WHERE year IS NOT NULL;
UPDATE pendidikan SET year = 2025 WHERE year IS NOT NULL;
UPDATE aparatur_desa SET year = 2025 WHERE year IS NOT NULL;
UPDATE desa_profile SET year = 2025 WHERE year IS NOT NULL;

-- Update kebencanaan period dates to 2025
UPDATE kebencanaan_rekap SET
  period_start = DATE '2025-01-01',
  period_end = DATE '2025-12-31',
  periode_date = DATE '2025-12-31'
WHERE period_end IS NOT NULL;

-- ===========================================
-- VERIFICATION: Check data distribution by year
-- ===========================================
-- Run this after update to verify all data is now in 2025
SELECT 'kependudukan' as table_name, tahun as year, COUNT(*) as count
FROM kependudukan GROUP BY tahun
UNION ALL
SELECT 'kesehatan' as table_name, tahun as year, COUNT(*) as count
FROM kesehatan GROUP BY tahun
UNION ALL
SELECT 'infrastruktur' as table_name, year, COUNT(*) as count
FROM infrastruktur GROUP BY year
UNION ALL
SELECT 'pendidikan' as table_name, year, COUNT(*) as count
FROM pendidikan GROUP BY year
UNION ALL
SELECT 'aparatur_desa' as table_name, year, COUNT(*) as count
FROM aparatur_desa GROUP BY year
UNION ALL
SELECT 'desa_profile' as table_name, year, COUNT(*) as count
FROM desa_profile GROUP BY year
ORDER BY table_name, year;