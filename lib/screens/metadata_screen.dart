import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
// supabase is used within repository, no direct import needed here
import '../services/metadata_repository.dart';
import '../services/auth_service.dart';

class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen>
    with SingleTickerProviderStateMixin {
  // Repository & state
  final _repo = MetadataRepository();
  List<Map<String, dynamic>> _metadataList = [];
  bool _loading = false;
  String? _kodeWilayah; // disimpan agar bisa dipakai saat edit
  bool _hasChanges = false; // Track if data has been modified

  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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

  Future<void> _load() async {
    try {
      if (mounted) setState(() => _loading = true);
      // Ambil kode wilayah dari route args atau SharedPreferences
      String? kode;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        kode = (args['kodeWilayah'] as String?)?.trim();
      }
      if (kode == null || kode.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        kode = prefs.getString('last_desa_kode');
      }
      kode ??= '6303052009';
      debugPrint('[Metadata] Memuat data untuk kode_wilayah: ' + kode);
      // Ambil data via repository (akan handle kode_wilayah & fallback desa_id)
      final items = await _repo.fetchAll(kode);
      if (mounted) {
        setState(() {
          _metadataList = items;
          _kodeWilayah = kode;
        });
      }
    } catch (e) {
      debugPrint('Error load metadata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Mapping kini ditangani di MetadataRepository

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    return WillPopScope(
      onWillPop: () async {
        // Return the hasChanges flag when popping
        Navigator.of(context).pop(_hasChanges);
        return false; // Prevent default pop since we handle it manually
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          NestedScrollView(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                              .where(
                                (item) =>
                                    item['tahun'].toString().contains('2025'),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withOpacity(0.08),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ), // End Stack body
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _openEditMetadataSheet,
              backgroundColor: const Color(0xFF16A34A),
              child: const Icon(Icons.edit, color: Colors.white),
            )
          : null,
    ), // End Scaffold
    ); // End WillPopScope
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  void _openEditMetadataSheet() {
    if (_kodeWilayah == null) return;
    final initial = _metadataList.map((m) => Map<String, dynamic>.from(m)).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MetadataEditSheet(
        initialItems: initial,
        kodeWilayah: _kodeWilayah!,
        onSaved: () async {
          if (!mounted) return;
          _hasChanges = true; // Mark that data has been modified
          setState(() => _loading = true);
          await _load();
          if (mounted) setState(() => _loading = false);
        },
      ),
    );
  }
}

InputDecoration _metaDec(String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    );

class _MetaEditItem {
  final TextEditingController namaCtl;
  final TextEditingController definisiCtl;
  final TextEditingController sumberCtl;
  final TextEditingController satuanCtl;
  final TextEditingController tahunCtl;
  final TextEditingController frekuensiCtl;
  final TextEditingController pjCtl;
  final Map<String, dynamic> raw;
  final String? existingNama;
  bool removed = false;
  _MetaEditItem({
    required this.namaCtl,
    required this.definisiCtl,
    required this.sumberCtl,
    required this.satuanCtl,
    required this.tahunCtl,
    required this.frekuensiCtl,
    required this.pjCtl,
    required this.raw,
    this.existingNama,
  });
}

class _MetadataEditSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final String kodeWilayah;
  final Future<void> Function() onSaved;
  const _MetadataEditSheet({
    Key? key,
    required this.initialItems,
    required this.kodeWilayah,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<_MetadataEditSheet> createState() => _MetadataEditSheetState();
}

class _MetadataEditSheetState extends State<_MetadataEditSheet> {
  final List<_MetaEditItem> items = [];
  final _formKey = GlobalKey<FormState>();
  bool saving = false;
  late final MetadataRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = MetadataRepository();
    if (widget.initialItems.isNotEmpty) {
      for (final m in widget.initialItems) {
        items.add(
          _MetaEditItem(
            namaCtl: TextEditingController(text: m['nama'] ?? ''),
            definisiCtl: TextEditingController(text: m['definisi'] ?? ''),
            sumberCtl: TextEditingController(text: m['sumber'] ?? ''),
            satuanCtl: TextEditingController(text: m['satuan'] ?? ''),
            tahunCtl: TextEditingController(text: m['tahun'] ?? ''),
            frekuensiCtl: TextEditingController(text: m['frekuensi'] ?? ''),
            pjCtl: TextEditingController(text: m['penanggungjawab'] ?? ''),
            raw: const {},
            existingNama: m['nama']?.toString(),
          ),
        );
      }
    } else {
      items.add(
        _MetaEditItem(
          namaCtl: TextEditingController(),
          definisiCtl: TextEditingController(),
          sumberCtl: TextEditingController(),
          satuanCtl: TextEditingController(),
          tahunCtl: TextEditingController(),
          frekuensiCtl: TextEditingController(),
          pjCtl: TextEditingController(),
          raw: const {},
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final i in items) {
      i.namaCtl.dispose();
      i.definisiCtl.dispose();
      i.sumberCtl.dispose();
      i.satuanCtl.dispose();
      i.tahunCtl.dispose();
      i.frekuensiCtl.dispose();
      i.pjCtl.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final names = <String, int>{};
      for (final it in items.where((e) => !e.removed)) {
        final n = it.namaCtl.text.trim();
        if (n.isEmpty) continue;
        names[n] = (names[n] ?? 0) + 1;
      }
      final dups = names.entries.where((e) => e.value > 1).map((e) => e.key).toList();
      if (dups.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nama duplikat: ${dups.join(', ')}')),
          );
        }
        setState(() => saving = false);
        return;
      }

      final desaId = await _repo.getDesaIdByKode(widget.kodeWilayah);
      for (final i in items) {
        final nama = i.namaCtl.text.trim();
        if (nama.isEmpty) continue;
        if (i.removed) {
          await _repo.deleteItem(kodeWilayah: widget.kodeWilayah, nama: nama);
          continue;
        }
        await _repo.upsertItem(
          kodeWilayah: widget.kodeWilayah,
          desaId: desaId,
          nama: nama,
          definisi: i.definisiCtl.text.trim(),
          sumber: i.sumberCtl.text.trim(),
          satuan: i.satuanCtl.text.trim(),
          tahunText: i.tahunCtl.text.trim(),
          frekuensi: i.frekuensiCtl.text.trim(),
          penanggungJawab: i.pjCtl.text.trim(),
        );
      }

      await widget.onSaved();
      if (!mounted) return;
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metadata berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Material(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFFA3E635)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Metadata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Kelola definisi & atribut data desa', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...items.where((e) => !e.removed).map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: e.namaCtl,
                                        enabled: e.existingNama == null,
                                        decoration: _metaDec('Nama Data'),
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Hapus Item',
                                      onPressed: () => setState(() => e.removed = true),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: e.definisiCtl,
                                  maxLines: 3,
                                  decoration: _metaDec('Definisi'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: e.sumberCtl,
                                        decoration: _metaDec('Sumber'),
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: e.satuanCtl,
                                        decoration: _metaDec('Satuan'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: e.tahunCtl,
                                        decoration: _metaDec('Tahun (teks)'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: e.frekuensiCtl,
                                        decoration: _metaDec('Frekuensi'),
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: e.pjCtl,
                                  decoration: _metaDec('Penanggung Jawab'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => items.add(
                              _MetaEditItem(
                                namaCtl: TextEditingController(),
                                definisiCtl: TextEditingController(),
                                sumberCtl: TextEditingController(),
                                satuanCtl: TextEditingController(),
                                tahunCtl: TextEditingController(),
                                frekuensiCtl: TextEditingController(),
                                pjCtl: TextEditingController(),
                                raw: const {},
                              ),
                            )),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: saving ? null : _handleSave,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Simpan Perubahan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
