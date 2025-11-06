-- Seed Kebencanaan (normalized) untuk kode_wilayah 69696969
-- Catatan:
-- - Skrip ini mengasumsikan tabel normalized sudah ada:
--   public.kebencanaan_rekap, public.kebencanaan_rt, public.kebencanaan_bantuan, public.kebencanaan_penanganan
-- - Pastikan baris desa (public.desa) dengan kode_wilayah='69696969' sudah ada.
-- - Jika RLS aktif dan Anda mengeksekusi lewat Dashboard SQL editor (role: service), skrip akan berjalan.
-- - Jika Anda mengeksekusi dari klien biasa dengan RLS aktif, pastikan ada policy SELECT/INSERT yang mengizinkan.

BEGIN;

WITH d AS (
  SELECT id, kode_wilayah FROM public.desa WHERE kode_wilayah = '69696969'
), ins_rekap AS (
  INSERT INTO public.kebencanaan_rekap (
    desa_id,
    kode_wilayah,
    jenis,
    period_start,
    period_end,
    periode_label,
    total_rumah,
    total_kk,
    total_jiwa,
    lansia,
    bumil,
    balita
  )
  SELECT
    d.id,
    d.kode_wilayah,
    'banjir'::text,
    DATE '2025-10-01',
    DATE '2025-10-31',
    'Oktober 2025',
    120,  -- total_rumah
    95,   -- total_kk
    350,  -- total_jiwa
    20,   -- lansia
    8,    -- bumil
    30    -- balita
  FROM d
  RETURNING id, desa_id
)
-- RT detail
INSERT INTO public.kebencanaan_rt (
  snapshot_id,
  desa_id,
  rt_code,
  rumah,
  kk,
  jiwa,
  lansia,
  bumil,
  balita,
  bayi
)
SELECT
  r.id,
  r.desa_id,
  v.rt_code,
  v.rumah,
  v.kk,
  v.jiwa,
  v.lansia,
  v.bumil,
  v.balita,
  v.bayi
FROM ins_rekap r
JOIN (
  VALUES
    ('001', 40, 32, 115, 6, 3, 10, 1),
    ('002', 35, 28, 105, 7, 2, 12, 1),
    ('003', 45, 35, 130, 7, 3, 8,  2)
) AS v(rt_code, rumah, kk, jiwa, lansia, bumil, balita, bayi)
ON TRUE;

-- Bantuan
WITH r AS (
  SELECT id, desa_id FROM ins_rekap
)
INSERT INTO public.kebencanaan_bantuan (
  snapshot_id,
  desa_id,
  nama,
  jenis,
  jumlah
)
SELECT r.id, r.desa_id, b.nama, b.jenis, b.jumlah
FROM r
JOIN (
  VALUES
    ('Sembako',        'sembako',   100),
    ('Paket makanan',  'makanan',   150),
    ('Buah-buahan',    'makanan',    80),
    ('Selimut',        'non-pangan', 50)
) AS b(nama, jenis, jumlah)
ON TRUE;

-- Penanganan
WITH r AS (
  SELECT id, desa_id FROM ins_rekap
)
INSERT INTO public.kebencanaan_penanganan (
  snapshot_id,
  desa_id,
  urutan,
  deskripsi
)
SELECT r.id, r.desa_id, p.urutan, p.deskripsi
FROM r
JOIN (
  VALUES
    (1, 'Evakuasi warga terdampak ke posko sementara'),
    (2, 'Distribusi bantuan logistik oleh BPBD & relawan'),
    (3, 'Pembersihan rumah dan fasilitas umum pasca banjir')
) AS p(urutan, deskripsi)
ON TRUE;

COMMIT;
