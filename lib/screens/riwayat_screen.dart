// ============================================================
// riwayat_screen.dart – Halaman Riwayat Absensi
// Tugas: Menampilkan daftar 30 riwayat absensi terakhir.
//        State dibuat public (RiwayatScreenState) agar
//        HomeScreen bisa memanggil loadRiwayat() dari luar
//        untuk auto-refresh setelah absensi berhasil.
// ============================================================

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/absensi_model.dart';
import '../models/user_model.dart';
import '../services/absensi_service.dart';

class RiwayatScreen extends StatefulWidget {
  final UserModel? user;
  const RiwayatScreen({super.key, this.user});

  @override
  // State dibuat public agar bisa diakses via GlobalKey dari HomeScreen
  RiwayatScreenState createState() => RiwayatScreenState();
}

class RiwayatScreenState extends State<RiwayatScreen> {
  final _service = AbsensiService();

  List<AbsensiModel> _riwayat = [];
  bool _isLoading = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    loadRiwayat();
  }

  @override
  void didUpdateWidget(covariant RiwayatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user?.userId != widget.user?.userId && widget.user != null) {
      loadRiwayat();
    }
  }

  /// Public method – bisa dipanggil dari HomeScreen via GlobalKey
  Future<void> loadRiwayat() async {
    if (widget.user == null) return;

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final data = await _service.getRiwayat(widget.user!.userId);
      if (mounted) setState(() => _riwayat = data);
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadRiwayat,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMsg, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadRiwayat,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_riwayat.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada riwayat absensi',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Tarik ke bawah untuk memuat ulang',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _riwayat.length,
      itemBuilder: (ctx, i) => _buildItem(_riwayat[i]),
    );
  }

  Widget _buildItem(AbsensiModel item) {
    // Format tanggal & jam — pakai teks biasa tanpa karakter unicode aneh
    final bulanList = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final hariList = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final tgl = '${hariList[item.waktu.weekday - 1]}, '
        '${item.waktu.day} ${bulanList[item.waktu.month]} ${item.waktu.year}';
    final jam = '${item.waktu.hour.toString().padLeft(2, '0')}:'
        '${item.waktu.minute.toString().padLeft(2, '0')}';

    final isHadir = item.isHadir;
    final badgeColor = isHadir ? Colors.green : Colors.orange;
    final badgeText = isHadir ? 'HADIR' : 'TERLAMBAT';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.foto.isNotEmpty
                  ? Image.network(
                      '${ApiConfig.fotoBase}/${item.foto}',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fotoPlaceholder(),
                    )
                  : _fotoPlaceholder(),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tanggal & jam
                  Text('$tgl  $jam',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),

                  // Badge status – pakai icon Flutter bukan emoji
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isHadir
                                  ? Icons.check_circle
                                  : Icons.warning_amber,
                              size: 12,
                              color: badgeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(badgeText,
                                style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Koordinat – pakai icon Flutter bukan emoji
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${item.latitude.toStringAsFixed(5)}, '
                          '${item.longitude.toStringAsFixed(5)}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Icon(Icons.person, color: Colors.grey, size: 30),
    );
  }
}
