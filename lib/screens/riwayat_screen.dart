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
  const namaBulan = [
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
    'Des',
  ];

  String formatJam(String? value) {
    if (value == null || value.isEmpty || value == 'null') {
      return '--:--';
    }

    final bagian = value.split(':');

    if (bagian.length >= 2) {
      return '${bagian[0]}:${bagian[1]}';
    }

    return value;
  }

  final tanggal = DateTime.tryParse(item.tanggal);

  final teksTanggal = tanggal == null
      ? item.tanggal
      : '${tanggal.day} ${namaBulan[tanggal.month]} ${tanggal.year}';

  final sudahMasuk =
      item.jamMasuk != null && item.jamMasuk!.isNotEmpty;

  final sudahPulang =
      item.jamPulang != null && item.jamPulang!.isNotEmpty;

  final String badgeText;
  final Color badgeColor;
  final IconData badgeIcon;

  if (sudahPulang) {
    badgeText = 'LENGKAP';
    badgeColor = Colors.green;
    badgeIcon = Icons.check_circle;
  } else if (sudahMasuk) {
    badgeText = 'BELUM PULANG';
    badgeColor = Colors.orange;
    badgeIcon = Icons.schedule;
  } else {
    badgeText = 'BELUM MASUK';
    badgeColor = Colors.red;
    badgeIcon = Icons.cancel_outlined;
  }

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.foto.isNotEmpty
                ? Image.network(
                    ApiConfig.getFotoUrl(item.foto),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,

                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,


                    errorBuilder: (context, error, stackTrace) {
  debugPrint(
    'URL FOTO RIWAYAT: ${ApiConfig.getFotoUrl(item.foto)}',
  );
  debugPrint('ERROR FOTO: $error');

  return _fotoPlaceholder();
},
                  )
                : _fotoPlaceholder(),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        teksTanggal,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            badgeIcon,
                            size: 12,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildJamInfo(
                        title: 'Jam Masuk',
                        jam: formatJam(item.jamMasuk),
                        icon: Icons.login,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildJamInfo(
                        title: 'Jam Pulang',
                        jam: formatJam(item.jamPulang),
                        icon: Icons.logout,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.status == 'terlambat'
                          ? 'Status masuk: Terlambat'
                          : 'Status masuk: Hadir',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.status == 'terlambat'
                            ? Colors.orange
                            : Colors.grey,
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
  Widget _buildJamInfo({
  required String title,
  required String jam,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                jam,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
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
