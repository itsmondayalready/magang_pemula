import 'package:flutter/material.dart';

class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen>
    with SingleTickerProviderStateMixin {
  // Data metadata berdasarkan Excel sheet
  final List<Map<String, dynamic>> _metadataList = [
    {
      'nama': 'Jumlah Penduduk',
      'definisi': 'Total penduduk yang berdomisili di desa',
      'sumber': 'Data kependudukan desa',
      'satuan': 'Jiwa',
      'tahun': '2024',
      'frekuensi': 'Triwulan',
      'penanggungjawab': 'Kasi Pemerintahan',
    },
    {
      'nama': 'Rumah Tangga Miskin',
      'definisi': 'RT yang masuk kategori miskin menurut DTKS',
      'sumber': 'DTKS / Pendataan lokal',
      'satuan': 'Rumah Tangga',
      'tahun': '2024',
      'frekuensi': 'Tahunan',
      'penanggungjawab': 'Kaur Kesejahteraan',
    },
    {
      'nama': 'Anak Tidak Sekolah',
      'definisi': 'Anak usia sekolah yang tidak sekolah',
      'sumber': 'Kader/PKK/Karang Taruna',
      'satuan': 'Orang',
      'tahun': '2023',
      'frekuensi': 'Tahunan',
      'penanggungjawab': 'Kaur Umum',
    },
    {
      'nama': 'Luas Lahan Pertanian',
      'definisi': 'Total luas sawah dan ladang aktif',
      'sumber': 'Data PBB / PPL Pertanian',
      'satuan': 'Hektar',
      'tahun': '2023',
      'frekuensi': 'Semesteran',
      'penanggungjawab': 'Kaur Perencanaan',
    },
    {
      'nama': 'Jumlah Warga yang Terdampak Kriteria Debit Air yang Masuk kedalam Rumah Setinggi 30-50 Cm',
      'definisi': 'Jumlah Jiwa (orang) dengan kriteria Debit Air yang Masuk kedalam Rumah Setinggi 30-50 Cm',
      'sumber': 'Kaling/Rt/Aparat Desa',
      'satuan': 'Jiwa',
      'tahun': '2025',
      'frekuensi': 'Tahunan',
      'penanggungjawab': 'Kaur Kesejahteraan',
    },
    {
      'nama': 'Updating Pendataan Penerima Bantuan Keluarga Miskin',
      'definisi': 'Keluarga yang masih tergolong miskin',
      'sumber': 'Pendataan langsung dan Ketua RT',
      'satuan': 'Keluarga',
      'tahun': '2023-2025',
      'frekuensi': 'Tahunan',
      'penanggungjawab': 'Kasi Kesejahteraan',
    },
    {
      'nama': 'Jumlah Rumah Tangga Yang belum Terpasang PDAM',
      'definisi': 'Total Rumah Tangga yang belum masang PDAM yang berdomisili di tempat',
      'sumber': 'Kaling/Rt/Aparat Desa',
      'satuan': 'Rumah Tangga',
      'tahun': '2023-2024',
      'frekuensi': 'sekali data',
      'penanggungjawab': 'Kepala Lingkungan',
    },
    {
      'nama': 'Jumlah Anak Kurang Gizi (Stunting)',
      'definisi': 'Anak usia di bawah 5 Tahun',
      'sumber': 'Kader/Bidan Desa',
      'satuan': 'Anak',
      'tahun': '2025',
      'frekuensi': 'Tahunan',
      'penanggungjawab': 'Kader KPM',
    },
    {
      'nama': 'Jumlah Lansia di Desa',
      'definisi': 'Lansia (59 tahun ke atas)',
      'sumber': 'Kaling/Rt/Aparat Desa',
      'satuan': 'Orang tua',
      'tahun': '2025',
      'frekuensi': 'Tahunan',
      'penanggungjawab': 'Kasi Pemerintahan',
    },
  ];

  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMetadata {
    if (_searchQuery.isEmpty) {
      return _metadataList;
    }
    return _metadataList.where((item) {
      final nama = item['nama'].toString().toLowerCase();
      final definisi = item['definisi'].toString().toLowerCase();
      final sumber = item['sumber'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nama.contains(query) ||
          definisi.contains(query) ||
          sumber.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 100,
            toolbarHeight: 56,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Metadata',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            flexibleSpace: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFFA3E635)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Informasi Metadata',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_metadataList.length} data tersedia',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama data, definisi, sumber...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF16A34A),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF16A34A),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Terbaru'),
                Tab(text: 'Favorit'),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMetadataList(_filteredMetadata),
                    _buildMetadataList(
                      _filteredMetadata
                          .where((item) =>
                              item['tahun'].toString().contains('2025'))
                          .toList(),
                    ),
                    _buildMetadataList(
                      _filteredMetadata
                          .where((item) => item['frekuensi'] == 'Tahunan')
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data ditemukan',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMetadataCard(item, index);
      },
    );
  }

  Widget _buildMetadataCard(Map<String, dynamic> item, int index) {
    final colors = [
      const Color(0xFF16A34A),
      const Color(0xFF0EA5A5),
      const Color(0xFF2563EB),
      const Color(0xFFF97316),
      const Color(0xFFDC2626),
      const Color(0xFF7C3AED),
    ];
    final color = colors[index % colors.length];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(item, color),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.05), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.article_outlined,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['nama'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    item['definisi'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(
                      Icons.source_outlined,
                      item['sumber'],
                      Colors.blue,
                    ),
                    _buildChip(
                      Icons.straighten_rounded,
                      item['satuan'],
                      Colors.orange,
                    ),
                    _buildChip(
                      Icons.calendar_today_rounded,
                      item['tahun'],
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['frekuensi'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['penanggungjawab'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> item, Color color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detail Metadata',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Nama Data', item['nama'], Icons.title),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Definisi',
                        item['definisi'],
                        Icons.description,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Sumber Data',
                        item['sumber'],
                        Icons.source,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailRow(
                              'Satuan',
                              item['satuan'],
                              Icons.straighten,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailRow(
                              'Tahun Data',
                              item['tahun'],
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Frekuensi Update',
                        item['frekuensi'],
                        Icons.schedule,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Penanggung Jawab',
                        item['penanggungjawab'],
                        Icons.person,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
