# Setup Supabase untuk Proyek Login Firebase

## Langkah 1: Buat Proyek Supabase

1. Buka https://supabase.com dan buat akun (gratis)
2. Klik "New Project"
3. Isi detail project:
   - **Name**: loginfirebase (atau nama lain)
   - **Database Password**: Buat password yang kuat dan simpan
   - **Region**: Southeast Asia (Singapore) - terdekat dengan Indonesia
4. Klik "Create new project" dan tunggu ~2 menit

## Langkah 2: Dapatkan API Keys

1. Setelah project dibuat, buka **Settings** (ikon gear di sidebar)
2. Klik **API**
3. Copy 2 nilai ini:
   - **Project URL** (contoh: `https://xxxxxxxxxxxxx.supabase.co`)
   - **anon public** key (dibawah "Project API keys")

## Langkah 3: Update Kode Flutter

Buka `lib/main.dart` dan ganti placeholder dengan nilai yang di-copy:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',        // Ganti dengan Project URL
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // Ganti dengan anon public key
);
```

## Langkah 4: Buat Database Tables

1. Di Supabase Dashboard, buka **SQL Editor** (ikon </> di sidebar)
2. Klik "New query"
3. Copy-paste SQL berikut dan klik **Run**:

```sql
-- 1. Create users table with role-based access
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user', 'guest')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Users can read their own data
CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- 4. Policy: Only admins can update roles
CREATE POLICY "Admins can update roles"
  ON users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'admin'
    )
  );

-- 5. Policy: Service role can insert users (for sign-up)
CREATE POLICY "Service can insert users"
  ON users FOR INSERT
  WITH CHECK (true);

-- 6. Create desa table
CREATE TABLE IF NOT EXISTS desa (
  id SERIAL PRIMARY KEY,
  nama TEXT NOT NULL,
  kode_wilayah TEXT UNIQUE NOT NULL,
  kecamatan TEXT,
  kabupaten TEXT,
  provinsi TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Create kependudukan table
CREATE TABLE IF NOT EXISTS kependudukan (
  id SERIAL PRIMARY KEY,
  desa_id INTEGER REFERENCES desa(id) ON DELETE CASCADE,
  total_penduduk INTEGER DEFAULT 0,
  total_kk INTEGER DEFAULT 0,
  laki_laki INTEGER DEFAULT 0,
  perempuan INTEGER DEFAULT 0,
  tahun INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Create kesehatan table
CREATE TABLE IF NOT EXISTS kesehatan (
  id SERIAL PRIMARY KEY,
  desa_id INTEGER REFERENCES desa(id) ON DELETE CASCADE,
  posyandu INTEGER DEFAULT 0,
  puskesmas INTEGER DEFAULT 0,
  bidan INTEGER DEFAULT 0,
  balita_gizi_buruk INTEGER DEFAULT 0,
  tahun INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Create pendidikan table
CREATE TABLE IF NOT EXISTS pendidikan (
  id SERIAL PRIMARY KEY,
  desa_id INTEGER REFERENCES desa(id) ON DELETE CASCADE,
  tk INTEGER DEFAULT 0,
  sd INTEGER DEFAULT 0,
  smp INTEGER DEFAULT 0,
  sma INTEGER DEFAULT 0,
  tahun INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. Create infrastruktur table
CREATE TABLE IF NOT EXISTS infrastruktur (
  id SERIAL PRIMARY KEY,
  desa_id INTEGER REFERENCES desa(id) ON DELETE CASCADE,
  jalan_aspal_km NUMERIC(10,2) DEFAULT 0,
  jalan_tanah_km NUMERIC(10,2) DEFAULT 0,
  jembatan INTEGER DEFAULT 0,
  irigasi_km NUMERIC(10,2) DEFAULT 0,
  tahun INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. Create kebencanaan table
CREATE TABLE IF NOT EXISTS kebencanaan (
  id SERIAL PRIMARY KEY,
  desa_id INTEGER REFERENCES desa(id) ON DELETE CASCADE,
  jenis_bencana TEXT NOT NULL,
  tanggal DATE NOT NULL,
  korban_jiwa INTEGER DEFAULT 0,
  kerusakan_rumah INTEGER DEFAULT 0,
  kerugian_estimasi NUMERIC(15,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. Enable RLS for all tables
ALTER TABLE desa ENABLE ROW LEVEL SECURITY;
ALTER TABLE kependudukan ENABLE ROW LEVEL SECURITY;
ALTER TABLE kesehatan ENABLE ROW LEVEL SECURITY;
ALTER TABLE pendidikan ENABLE ROW LEVEL SECURITY;
ALTER TABLE infrastruktur ENABLE ROW LEVEL SECURITY;
ALTER TABLE kebencanaan ENABLE ROW LEVEL SECURITY;

-- 13. Policies: Public read, admin write
CREATE POLICY "Public can read desa"
  ON desa FOR SELECT
  USING (true);

CREATE POLICY "Admins can modify desa"
  ON desa FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'admin'
    )
  );

-- Repeat for other tables
CREATE POLICY "Public can read kependudukan" ON kependudukan FOR SELECT USING (true);
CREATE POLICY "Admins can modify kependudukan" ON kependudukan FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

CREATE POLICY "Public can read kesehatan" ON kesehatan FOR SELECT USING (true);
CREATE POLICY "Admins can modify kesehatan" ON kesehatan FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

CREATE POLICY "Public can read pendidikan" ON pendidikan FOR SELECT USING (true);
CREATE POLICY "Admins can modify pendidikan" ON pendidikan FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

CREATE POLICY "Public can read infrastruktur" ON infrastruktur FOR SELECT USING (true);
CREATE POLICY "Admins can modify infrastruktur" ON infrastruktur FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

CREATE POLICY "Public can read kebencanaan" ON kebencanaan FOR SELECT USING (true);
CREATE POLICY "Admins can modify kebencanaan" ON kebencanaan FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);
```

## Langkah 5: Setup Authentication

1. Di Supabase Dashboard, buka **Authentication** > **Providers**
2. Enable providers yang diperlukan:
   - ✅ **Email** (sudah enabled by default)
   - ✅ **Anonymous Users** (toggle ON jika ingin guest login)

## Langkah 6: Setup Storage (untuk upload gambar/file)

1. Di Supabase Dashboard, buka **Storage**
2. Klik "Create a new bucket"
3. Isi detail:
   - **Name**: `desa-images`
   - **Public bucket**: ✅ Check (agar guest bisa lihat gambar)
4. Klik "Create bucket"

5. Buat Storage Policy:
   - Klik bucket `desa-images`
   - Klik tab **Policies**
   - Klik "New Policy" > "For full customization"
   - **Policy name**: Public read, admin write
   - **Allowed operation**: SELECT, INSERT, UPDATE, DELETE
   - **Target roles**: authenticated, anon
   
   Atau gunakan SQL berikut di SQL Editor:

```sql
-- Storage policy: Public read, admin write
CREATE POLICY "Public can view images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'desa-images');

CREATE POLICY "Admins can upload images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'desa-images' AND
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'admin'
    )
  );

CREATE POLICY "Admins can update images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'desa-images' AND
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'admin'
    )
  );

CREATE POLICY "Admins can delete images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'desa-images' AND
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'admin'
    )
  );
```

## Langkah 7: Buat Admin User

1. Di Supabase Dashboard, buka **Authentication** > **Users**
2. Klik "Add user" > "Create new user"
3. Isi:
   - **Email**: admin@desaapp.com (atau email admin Anda)
   - **Password**: Buat password yang kuat
   - **Auto Confirm User**: ✅ Check
4. Klik "Create user"

5. Copy **User UID** yang baru dibuat (contoh: `550e8400-e29b-41d4-a716-446655440000`)

6. Di **SQL Editor**, jalankan query ini untuk set role admin:

```sql
-- Insert admin role ke users table
INSERT INTO users (id, email, role)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',  -- Ganti dengan User UID yang di-copy
  'admin@desaapp.com',                      -- Ganti dengan email admin
  'admin'
)
ON CONFLICT (id) DO UPDATE SET role = 'admin';
```

## Langkah 8: Insert Sample Data (Opsional)

```sql
-- Insert sample desa
INSERT INTO desa (nama, kode_wilayah, kecamatan, kabupaten, provinsi)
VALUES ('Desa Melayu Ilir', '6303052009', 'Kendawangan', 'Ketapang', 'Kalimantan Barat')
ON CONFLICT (kode_wilayah) DO NOTHING;

-- Insert sample kependudukan
INSERT INTO kependudukan (desa_id, total_penduduk, total_kk, laki_laki, perempuan, tahun)
SELECT id, 1250, 320, 630, 620, 2024
FROM desa WHERE kode_wilayah = '6303052009';
```

## Langkah 9: Test App

1. Build dan run aplikasi Flutter:
   ```bash
   flutter run
   ```

2. Test skenario:
   - ✅ App startup langsung ke Main Menu (guest mode)
   - ✅ Klik "Login" di header
   - ✅ Login dengan admin@desaapp.com
   - ✅ Role badge berubah jadi "Admin"
   - ✅ FAB (+ button) muncul untuk admin
   - ✅ Logout dan role kembali ke "Guest"

## Troubleshooting

### Error: "Invalid API key"
- Pastikan URL dan anonKey di `main.dart` sudah benar
- Re-copy dari Supabase Dashboard > Settings > API

### Error: "Row Level Security policy violation"
- Cek apakah user sudah ada di table `users` dengan role yang benar
- Jalankan query check:
  ```sql
  SELECT * FROM users WHERE email = 'admin@desaapp.com';
  ```

### Anonymous login tidak berfungsi
- Pastikan Anonymous Auth sudah enabled di Authentication > Providers

## Migrasi Data dari Firebase (Opsional)

Jika Anda punya data di Firestore yang ingin dipindahkan:

1. Export Firestore data ke JSON
2. Convert JSON ke SQL INSERT statements
3. Import ke Supabase via SQL Editor

Atau gunakan script Python/Node.js untuk automasi migration.

## Keuntungan Supabase vs Firebase

✅ **Free Tier Generous**:
- 500MB Database (vs Firestore 1GB tapi limited queries)
- 1GB Storage (vs Firebase Storage perlu Blaze Plan)
- 50,000 monthly active users
- Unlimited API requests

✅ **SQL-based**: Lebih familiar dan powerful untuk query kompleks

✅ **Built-in Auth + Storage + Realtime**: All-in-one platform

✅ **Open Source**: Self-hosting option tersedia

---

**Selamat! Proyek Anda sudah berhasil dimigrate ke Supabase!** 🎉
