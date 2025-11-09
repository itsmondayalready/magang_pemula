/// Kumpulan konstanta jenis pendidikan yang umum dipakai di aplikasi.
/// Disimpan sesuai label "jenis" pada domain 'pendidikan' dengan metric_name 'jumlah'.
class PendidikanConstants {
  // Pendidikan formal (umum)
  static const List<String> formal = <String>[
    'PAUD',
    'TK',
    'SD',
    'SMP',
    'SMA',
    'SMK',
    'Akademi/PT',
  ];

  // Luar Biasa (SLB)
  static const List<String> slb = <String>['SDLB', 'SMPLB', 'SMALB'];

  // Keagamaan yang berbentuk angka (jumlah unit)
  static const List<String> keagamaanInt = <String>['Pesantren', 'Madrasah'];

  // Keagamaan / literasi yang bersifat boolean (disimpan sebagai 0/1 pada value_int)
  static const List<String> keagamaanBool = <String>['Paket A/B/C', 'TBM'];

  // Keterampilan / kursus
  static const List<String> keterampilan = <String>[
    'Bahasa',
    'Komputer',
    'Menjahit',
    'Montir',
  ];

  /// Gabungan semua label standar (termasuk boolean & non-boolean)
  static Set<String> allKeys() => {
    ...formal,
    ...slb,
    ...keagamaanInt,
    ...keagamaanBool,
    ...keterampilan,
  };
}

// TODO(migration): Jika ingin menambah metric lain seperti 'guru_count', 'siswa_count',
// atau akses 'jarak_km' & 'waktu_menit', siapkan mapping metric_name tambahan
// dan editor multi-metric di UI. Saat ini hanya metric_name='jumlah'.
