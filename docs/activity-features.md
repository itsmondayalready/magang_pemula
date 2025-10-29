# Activity Diagram per Fitur (Swimlane)

Berikut aktivitas utama untuk setiap modul/fitur menggunakan swimlane (subgraph sebagai lane). Orientasi kiri→kanan agar lane tersusun horizontal.

## Kependudukan

```mermaid
flowchart LR
  %% Lanes
  subgraph U[User]
    U1(Tap Kependudukan)
    U2{Pilih Tab}
    U3[Ganti Tab / Back]
  end

  subgraph MM[MainMenuPage]
    MM1(Navigator.push ke KependudukanScreen)
  end

  subgraph KPD[KependudukanScreen]
    K1[Render ringkasan Total/KK/RT/RW]
  end

  subgraph CMP[Komponen - TabBar & Chart]
    C1[Build chart: Gender]
    C2[Build bar: Pendidikan]
    C3[Build pie: Pekerjaan]
    C4[Tampilkan grafik + legenda]
  end

  %% Flow
  U1 --> MM1 --> K1 --> U2
  U2 -->|Gender| C1 --> C4 --> U3
  U2 -->|Pendidikan| C2 --> C4 --> U3
  U2 -->|Pekerjaan| C3 --> C4 --> U3
  U3 -->|Ganti Tab| U2
```

## Kesehatan

```mermaid
flowchart LR
  subgraph U[User]
    U1(Tap Kesehatan)
    U2{Pilih Tab}
    U3[Ganti Tab / Back]
  end

  subgraph MM[MainMenuPage]
    MM1(Navigator.push ke KesehatanScreen)
  end

  subgraph KS[KesehatanScreen]
    K1[Render ringkasan Fasilitas/Tenaga/Imunisasi/Penyakit]
  end

  subgraph CMP[Komponen]
    C1[Pie: Fasilitas]
    C2[Bar: Tenaga Medis]
    C3[Bar: Imunisasi]
  end

  U1 --> MM1 --> K1 --> U2
  U2 -->|Fasilitas| C1 --> U3
  U2 -->|Tenaga| C2 --> U3
  U2 -->|Imunisasi| C3 --> U3
  U3 -->|Ganti Tab| U2
```

## Infrastruktur

```mermaid
flowchart LR
  subgraph U[User]
    U1(Tap Infrastruktur)
    U2{Pilih Tab}
    U3[Ganti Tab / Back]
  end

  subgraph MM[MainMenuPage]
    MM1(Navigator.push ke InfrastrukturScreen)
  end

  subgraph INF[InfrastrukturScreen]
    I1[Render ringkasan Pendidikan/Kesehatan/Transport/Sanitasi]
  end

  subgraph CMP[Komponen]
    C1[Bar: Pendidikan]
    C2[Pie+Leg: Faskes]
    C3[Bar: Jenis Jalan + Stats Angkutan + Akses]
    C4[Kartu Indikator: Komunikasi/Informasi]
    C5[Bar: Sanitasi + Chips Kebencanaan]
  end

  U1 --> MM1 --> I1 --> U2
  U2 -->|Pendidikan| C1 --> U3
  U2 -->|Kesehatan| C2 --> U3
  U2 -->|Transportasi| C3 --> U3
  U2 -->|Komunikasi| C4 --> U3
  U2 -->|Sanitasi| C5 --> U3
  U3 -->|Ganti Tab| U2
```

## Pendidikan

```mermaid
flowchart LR
  subgraph U[User]
    U1(Tap Pendidikan)
    U2{Pilih Tab}
    U3[Ganti Tab / Back]
  end

  subgraph MM[MainMenuPage]
    MM1(Navigator.push ke PendidikanScreen)
  end

  subgraph PD[PendidikanScreen]
    P1[Render ringkasan Negeri / Swasta Lokal]
  end

  subgraph CMP[Komponen]
    C1[Banner 0 + Chips Negeri]
    C2[List Swasta: Lokal/Terdekat + Badge Akses]
    C3[Chips: SLB, Keagamaan, TBM, Keterampilan]
  end

  U1 --> MM1 --> P1 --> U2
  U2 -->|Negeri| C1 --> U3
  U2 -->|Swasta| C2 --> U3
  U2 -->|LB & Keagamaan| C3 --> U3
  U3 -->|Ganti Tab| U2
```

## Kebencanaan

```mermaid
flowchart LR
  subgraph U[User]
    U1(Tap Kebencanaan)
    U2{Pilih Tab}
    U3[Ganti Tab / Back]
  end

  subgraph MM[MainMenuPage]
    MM1(Navigator.push ke KebencanaanScreen)
  end

  subgraph KB[KebencanaanScreen]
    K1[Render ringkasan Rumah/KK/Jiwa/Rentan]
  end

  subgraph CMP[Komponen]
    C1[Bar per RT + Pie Kelompok Rentan]
    C2[Progress + Kartu per RT]
    C3[Pie Jenis Bantuan + Daftar]
    C4[Timeline Penanganan]
  end

  U1 --> MM1 --> K1 --> U2
  U2 -->|Statistik| C1 --> U3
  U2 -->|Per RT| C2 --> U3
  U2 -->|Bantuan| C3 --> U3
  U2 -->|Penanganan| C4 --> U3
  U3 -->|Ganti Tab| U2
```

## Metadata

```mermaid
flowchart LR
  subgraph U[User]
    U1(Tap Metadata)
    U2{Ketik kata kunci?}
    U3{Pilih item?}
    U4[Tutup dialog / Back]
  end

  subgraph MM[MainMenuPage]
    MM1(Navigator.push ke MetadataScreen)
  end

  subgraph MD[MetadataScreen]
    M1[Render daftar metadata]
    M2[Filter list nama/definisi/sumber]
  end

  subgraph D[Detail Dialog]
    D1[Tampilkan detail metadata]
  end

  U1 --> MM1 --> M1
  M1 --> U2
  U2 -->|Ya| M2 --> U3
  U2 -->|Tidak| U3
  U3 -->|Ya| D1 --> U4 --> M1
```

Catatan umum
- Semua modul saat ini menggunakan data dummy/konstanta; tidak ada I/O jaringan.
- Akses tamu (Guest) bersifat read-only—tidak ada aksi pembuatan data.
