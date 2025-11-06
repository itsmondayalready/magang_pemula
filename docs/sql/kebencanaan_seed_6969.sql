-- Seed Kebencanaan (normalized) untuk KODE WILAYAH 6969
-- Gaya mengikuti contoh Anda (rekap -> rt -> bantuan -> penanganan),
-- dengan periode dinamis bulan berjalan dan jumlah RT lebih banyak (5 RT).
-- Catatan: pastikan public.desa memiliki baris dengan kode_wilayah='6969'.

-- Rekap agregat (UUID-aware: desa.id UUID)
insert into public.kebencanaan_rekap (
  jenis, kode_wilayah, desa_id,
  period_start, period_end, periode_date, periode_label,
  total_rumah, total_kk, total_jiwa, lansia, bumil, balita
)
select
  'banjir', '6969', d.id,
  date_trunc('month', now())::date,
  (date_trunc('month', now()) + interval '1 month - 1 day')::date,
  null, null,
  150, 120, 420, 18, 7, 25
from public.desa d
where d.kode_wilayah = '6969'
limit 1;

-- RT detail (5 RT contoh)
with s as (
  select id, desa_id
  from public.kebencanaan_rekap
  where kode_wilayah='6969' and jenis='banjir'
  order by created_at desc limit 1
)
insert into public.kebencanaan_rt (
  snapshot_id, desa_id, rt_code, rumah, kk, jiwa, lansia, bumil, balita, bayi
)
select id, desa_id, '001', 30, 25, 100, 5,  1, 6,  2 from s union all
select id, desa_id, '002', 28, 23,  90, 4,  2, 5,  1 from s union all
select id, desa_id, '003', 32, 26,  95, 3,  1, 7,  1 from s union all
select id, desa_id, '004', 25, 22,  70, 3,  1, 4,  1 from s union all
select id, desa_id, '005', 35, 24,  65, 3,  2, 3,  0 from s;

-- Bantuan (jenis dibuat konsisten agar UI menampilkan label yang rapi)
with s as (
  select id, desa_id
  from public.kebencanaan_rekap
  where kode_wilayah='6969' and jenis='banjir'
  order by created_at desc limit 1
)
insert into public.kebencanaan_bantuan (snapshot_id, desa_id, nama, jenis, jumlah)
select id, desa_id, 'Sembako',         'sembako',    120 from s union all
select id, desa_id, 'Paket makanan',   'makanan',    180 from s union all
select id, desa_id, 'Air minum galon', 'non-pangan',  60 from s union all
select id, desa_id, 'Selimut tebal',   'non-pangan',  40 from s;

-- Penanganan
with s as (
  select id, desa_id
  from public.kebencanaan_rekap
  where kode_wilayah='6969' and jenis='banjir'
  order by created_at desc limit 1
)
insert into public.kebencanaan_penanganan (snapshot_id, desa_id, urutan, deskripsi)
select id, desa_id, 1, 'Evakuasi dan pendirian posko' from s union all
select id, desa_id, 2, 'Distribusi logistik dan makanan siap saji' from s union all
select id, desa_id, 3, 'Pembersihan akses dan fasilitas umum' from s;
