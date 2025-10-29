# Use Case Diagram

Diagram ini memetakan aktor dan kemampuan utama di aplikasi. Peran utama:
- Admin/Petugas: pengguna terotentikasi (bukan guest), bisa mengakses Aksi Cepat.
- Warga/Guest: bisa masuk sebagai tamu, hanya melihat data.
- Supabase (sistem eksternal): autentikasi dan sumber informasi peran pengguna.

```mermaid
flowchart TB
  %% Aktor
  actorAdmin([Admin / Petugas])
  actorGuest([Warga / Guest])
  actorSupabase[(Supabase Auth & DB)]

  %% Sistem
  subgraph App[Aplikasi Mobile Desa]
    UC_Login((Login Email/Password))
    UC_Guest((Masuk Sebagai Guest))
    UC_Reset((Reset Password))

    subgraph UC_View[Melihat Data]
      direction TB
      UC_Menu((Lihat Main Menu))
      UC_Wilayah((Ubah Wilayah))
      UC_Kependudukan((Lihat Kependudukan))
      UC_Kesehatan((Lihat Kesehatan))
      UC_Infrastruktur((Lihat Infrastruktur))
      UC_Pendidikan((Lihat Pendidikan))
      UC_Kebencanaan((Lihat Kebencanaan))
      UC_Metadata((Lihat Metadata & Cari))
      UC_MetaDetail((Lihat Detail Metadata))
    end

    UC_QA((Aksi Cepat: Rencana, Kebencanaan, Jadwal, Kuesioner))
    UC_Logout((Logout))
  end

  %% Relasi aktor → use case
  actorAdmin --> UC_Login
  actorAdmin --> UC_Reset
  actorAdmin --> UC_View
  actorAdmin --> UC_QA
  actorAdmin --> UC_Logout

  actorGuest --> UC_Guest
  actorGuest --> UC_View
  actorGuest --> UC_Logout

  %% Ketergantungan ke Supabase
  UC_Login --> actorSupabase
  UC_Reset --> actorSupabase
  UC_Guest --> actorSupabase

  %% Catatan hak akses
  note right of UC_QA
    Hanya Admin/Petugas.
    Guest tidak dapat menggunakan
    Aksi Cepat (dibatasi di UI).
  end note

  note right of UC_Metadata
    Pencarian metadata berdasarkan
    nama/definisi/sumber.
  end note
```

Catatan
- Aplikasi saat ini menampilkan data dummy untuk modul (grafik/daftar). Integrasi CRUD data dapat ditambahkan sebagai perluasan use case di masa depan.
- Peran Admin dibaca dari tabel `users.role` di Supabase setelah login.
