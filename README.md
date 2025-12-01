<div align="center">

<h1>Desa Cantik</h1>

Sistem pengelolaan dan visualisasi data desa — modern, ringan, dan siap didistribusikan.

<br/>

<img src="https://img.shields.io/badge/Flutter-3.9%2B-blue" alt="Flutter"/>
<img src="https://img.shields.io/badge/Dart-stable-0175C2" alt="Dart"/>
<img src="https://img.shields.io/badge/Supabase-Integrated-00C49A" alt="Supabase"/>

</div>

---

Desa Cantik adalah aplikasi Flutter untuk pengelolaan dan visualisasi data desa: kependudukan, kesehatan, pendidikan, infrastruktur, tematik/kebencanaan, metadata, serta administrasi log masuk. Terintegrasi dengan Supabase dan mendukung ekspor laporan ke PDF dan Excel.

## Daftar Isi
- Gambaran Umum
- Persyaratan
- Instalasi Cepat
- Konfigurasi Supabase
- Penggunaan
- Fitur Utama
- Build & Distribusi
- Resources
- Struktur Proyek
- Troubleshooting
- Developer

## Persyaratan
- Flutter SDK 3.9+ (stable)
- Dart SDK sesuai versi Flutter
- Android Studio atau VS Code dengan Flutter & Dart plugin
- JDK 17 untuk build Android
- Xcode untuk build iOS (opsional, macOS)
- Akun Supabase dan project aktif (URL & anon key)

## Instalasi
1) Clone repository:
```
git clone https://github.com/itsmondayalready/magang_pemula.git
cd magang_pemula
```
2) Pasang dependencies Flutter:
```
flutter pub get
```
3) Konfigurasi Supabase:
- Isi file konfigurasi Supabase pada `lib/services/supabase_config.dart` (URL & anon key). Kunci disimpan dengan obfuscation sederhana (Base64) untuk menghindari hardcode langsung.
- Pastikan RLS (Row Level Security) aktif dan policy tabel telah diatur sesuai kebutuhan aplikasi.

4) Jalankan aplikasi (Android emulator atau device):
```
flutter run
```

## Penggunaan
- Login: pengguna admin dan pengguna biasa/guest didukung; peran mempengaruhi akses fitur.
- Pemilihan wilayah: pilih desa melalui bottom sheet; pemilihan terakhir disimpan untuk sesi berikutnya.
- Dashboard: ringkasan desa dan carousel statistik (luas wilayah, RT/RW, penduduk, pendidikan, kesehatan).
- Navigasi fitur: grid fitur utama untuk CRUD dan visualisasi per domain.
- Ekspor: PDF dan Excel multi-sheet untuk laporan dan arsip.

## Fitur Utama
- Profil Desa: detail profil, termasuk luas, RT/RW, dan kontak kantor.
- Kependudukan: total penduduk, KK, dan ringkasan terbaru.
- Kesehatan: fasilitas dan tenaga medis.
- Pendidikan: akumulasi unit pendidikan negeri dan swasta (konversi label otomatis).
- Infrastruktur: pengelolaan data infrastruktur, utilitas, dan catatan.
- Tematik/Kebencanaan: data tematik untuk kebencanaan dan visualisasi.
- Metadata: catatan tambahan dan informasi administratif.
- Log Masuk (Admin): melihat dan menghapus riwayat login.
- Ekspor PDF: simpan laporan; di Android diarahkan ke folder Downloads bila memungkinkan.
- Ekspor Excel: multi-sheet per domain; berbagi file atau menyimpan lokal.
- Keamanan Distribusi: build obfuscated dan shrink R8/ProGuard untuk APK.

## Build & Distribusi
- Build release (Android) dengan obfuscation dan split debug symbols:
```
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```
- Pastikan `proguard-rules.pro` tersetting bila diperlukan untuk menjaga simbol penting.
- Gambar ikon aplikasi diatur via `flutter_launcher_icons` (lihat `pubspec.yaml`).

## Resources
- Supabase: https://supabase.com/docs
- Flutter: https://docs.flutter.dev
- Paket yang digunakan (utama):
	- `supabase_flutter`, `provider`, `shared_preferences`, `url_launcher`
	- `pdf`, `printing`, `path_provider`
	- `excel` (opsional jika ekspor Excel dipakai), `share_plus`, `permission_handler`
	- `image_picker`, `fl_chart`, `intl`, `font_awesome_flutter`

## Struktur Proyek (ringkas)
## Troubleshooting
- Izin penyimpanan Android: untuk ekspor PDF/Excel ke `Downloads`, pastikan izin diberikan. Gunakan `permission_handler` bila diperlukan.
- RLS Supabase: aktifkan Row Level Security dan buat policy yang mengizinkan akses sesuai peran (admin/user/guest). Cek error di konsol Supabase bila query ditolak.
- Versi paket: jika `flutter pub get` menunjukkan banyak paket out-of-range, jalankan `flutter pub outdated` lalu pilih upgrade yang aman.
- Build gagal karena JDK: gunakan JDK 17 (disarankan) dan pastikan `ANDROID_HOME` terkonfigurasi.
- `lib/main.dart`: bootstrap aplikasi, routing, init Supabase
- `lib/screens/`: halaman fitur (main menu, profil, kependudukan, dll.)
- `lib/services/`: repository data & layanan ekspor
- `lib/utils/`: konstanta dan helper responsif
- `assets/`: data CSV contoh dan aset lain
- `docs/`: dokumentasi alur & SQL seed

## Developer
Kelompok Magang ILKOM 2025
