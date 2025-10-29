# Sequence Diagram per Fitur

Diagram urutan interaksi antar komponen untuk setiap modul.

Catatan umum
- Saat ini data berada di dalam state lokal/widget; tidak ada panggilan ke backend selain autentikasi.
- Lifeline utama: User → MainMenuPage → <Feature>Screen → (Widget Komponen/Chart) → (opsional) Dialog.

## Kependudukan

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant MM as MainMenuPage
  participant KPD as KependudukanScreen
  participant TAB as TabBarView
  participant CH as Chart Widgets

  U->>MM: Tap "Kependudukan"
  MM->>KPD: Navigator.push()
  KPD-->>U: Render ringkasan (Total/KK/RT/RW)
  U->>TAB: Pilih Tab (Gender/Pendidikan/Pekerjaan)
  TAB->>CH: Build chart sesuai tab
  CH-->>U: Tampilkan grafik & legenda
  U->>TAB: Ganti Tab / Back
  TAB-->>U: Navigasi sesuai aksi
```

## Kesehatan

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant MM as MainMenuPage
  participant KS as KesehatanScreen
  participant TAB as TabBarView
  participant CH as Chart Widgets

  U->>MM: Tap "Kesehatan"
  MM->>KS: Navigator.push()
  KS-->>U: Render ringkasan (Fasilitas/Tenaga/Imunisasi/Penyakit)
  U->>TAB: Pilih Tab (Fasilitas/Tenaga/Imunisasi)
  TAB->>CH: Build chart
  CH-->>U: Tampilkan Pie/Bar/Legend
  U->>TAB: Ganti Tab / Back
```

## Infrastruktur

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant MM as MainMenuPage
  participant INF as InfrastrukturScreen
  participant TAB as TabBarView
  participant CH as Chart Widgets

  U->>MM: Tap "Infrastruktur"
  MM->>INF: Navigator.push()
  INF-->>U: Render ringkasan (Pendidikan/Kesehatan/Transport/Sanitasi)
  U->>TAB: Pilih Tab (Pendidikan/Kesehatan/Transportasi/Komunikasi/Sanitasi)
  TAB->>CH: Build chart/kartu sesuai tab
  CH-->>U: Lihat bar/pie/kartu indikator
  U->>TAB: Ganti Tab / Back
```

## Pendidikan

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant MM as MainMenuPage
  participant PD as PendidikanScreen
  participant TAB as TabBarView
  participant UI as List/Chips Widgets

  U->>MM: Tap "Pendidikan"
  MM->>PD: Navigator.push()
  PD-->>U: Render ringkasan Negeri/Swasta
  U->>TAB: Pilih Tab (Negeri/Swasta/LB & Keagamaan)
  TAB->>UI: Tampilkan banner 0/daftar lokal-terdekat/chips
  UI-->>U: Baca informasi
  U->>TAB: Ganti Tab / Back
```

## Kebencanaan

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant MM as MainMenuPage
  participant KB as KebencanaanScreen
  participant TAB as TabBarView
  participant UI as Cards/Charts

  U->>MM: Tap "Kebencanaan"
  MM->>KB: Navigator.push()
  KB-->>U: Render ringkasan (Rumah/KK/Jiwa/Rentan)
  U->>TAB: Pilih Tab (Statistik/Per RT/Bantuan/Penanganan)
  TAB->>UI: Bangun komponen sesuai tab
  UI-->>U: Lihat bar/progress/daftar/timeline
  U->>TAB: Ganti Tab / Back
```

## Metadata

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant MM as MainMenuPage
  participant MD as MetadataScreen
  participant FL as Filter/Search
  participant D as Detail Dialog

  U->>MM: Tap "Metadata"
  MM->>MD: Navigator.push()
  MD-->>U: Render daftar metadata
  U->>FL: Ketik kata kunci
  FL->>MD: Terapkan filter list
  U->>MD: Tap item metadata
  MD->>D: showDialog(detail)
  D-->>U: Tampilkan detail lengkap
  U->>MD: Tutup dialog / Back
```
