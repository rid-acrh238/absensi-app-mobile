import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/absensi_model.dart';
import '../models/user_model.dart';

class DashboardScreen extends StatelessWidget {
  final UserModel? user;

  final bool statusLoading;
  final bool chartLoading;
  final bool sudahMasuk;
  final bool sudahPulang;

  final List<AbsensiModel> riwayat;

  final String? jamMasuk;
  final String? jamPulang;

  final VoidCallback onGoToAbsensi;
  final VoidCallback onGoToRiwayat;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.onGoToAbsensi,
    required this.onGoToRiwayat,
    this.statusLoading = false,
    this.chartLoading = false,
    this.riwayat = const [],
    this.sudahMasuk = false,
    this.sudahPulang = false,
    this.jamMasuk,
    this.jamPulang,
  });

  String _formatTanggal(DateTime date) {
    const namaHari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    const namaBulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final hari = namaHari[date.weekday - 1];
    final bulan = namaBulan[date.month - 1];

    return '$hari, ${date.day} $bulan ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tanggalHariIni = _formatTanggal(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final horizontalPadding = isWide ? 32.0 : 16.0;
        final contentWidth = isWide ? 1000.0 : double.infinity;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: contentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(
                      context,
                      tanggalHariIni,
                      isWide,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Status Absensi Hari Ini',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusSection(isWide),
                    const SizedBox(height: 24),
                    const Text(
                      'Grafik Kehadiran',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildGrafikKehadiran(),
                    const SizedBox(height: 24),
                    const Text(
                      'Menu Cepat',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNavigationSection(isWide),
                    const SizedBox(height: 24),
                    _buildInformationCard(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrafikKehadiran() {
    if (chartLoading) {
      return Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final dataMasuk = riwayat.where((item) {
      final jam = item.jamMasuk;

      return jam != null &&
          jam.isNotEmpty &&
          jam.toLowerCase() != 'null';
    }).toList();

    if (dataMasuk.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 42,
              color: Colors.grey,
            ),
            SizedBox(height: 10),
            Text(
              'Belum ada data kehadiran',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final terlambat = dataMasuk.where((item) {
      return item.status.toLowerCase() == 'terlambat';
    }).length;

    final hadir = dataMasuk.length - terlambat;
    final nilaiTertinggi = hadir > terlambat ? hadir : terlambat;

    final maxY = nilaiTertinggi == 0
        ? 1.0
        : nilaiTertinggi.toDouble() + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total ${dataMasuk.length} hari tercatat',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(
                  show: false,
                ),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }

                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Hadir',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        if (value.toInt() == 1) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Terlambat',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: hadir.toDouble(),
                        width: 34,
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: terlambat.toDouble(),
                        width: 34,
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartSummary(
                label: 'Hadir',
                total: hadir,
                color: Colors.green,
              ),
              _buildChartSummary(
                label: 'Terlambat',
                total: terlambat,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSummary({
    required String label,
    required int total,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$label: $total',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    String tanggal,
    bool isWide,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 28 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                _buildProfileIcon(),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildUserInformation(tanggal),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileIcon(),
                const SizedBox(height: 16),
                _buildUserInformation(tanggal),
              ],
            ),
    );
  }

  Widget _buildProfileIcon() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildUserInformation(String tanggal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selamat Datang,',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.nama ?? 'Mahasiswa',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'NIM: ${user?.nim ?? '-'}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 15,
              color: Colors.white70,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tanggal,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(bool isWide) {
    if (statusLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Memuat status absensi...',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final masukCard = _StatusCard(
      title: 'Absensi Masuk',
      time: jamMasuk ?? '--:--:--',
      isCompleted: sudahMasuk,
      completedText: 'Sudah Absen Masuk',
      incompleteText: 'Belum Absen Masuk',
      icon: Icons.login,
      completedColor: Colors.green,
    );

    final pulangCard = _StatusCard(
      title: 'Absensi Pulang',
      time: jamPulang ?? '--:--:--',
      isCompleted: sudahPulang,
      completedText: 'Sudah Absen Pulang',
      incompleteText: 'Belum Absen Pulang',
      icon: Icons.logout,
      completedColor: Colors.blue,
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: masukCard),
          const SizedBox(width: 16),
          Expanded(child: pulangCard),
        ],
      );
    }

    return Column(
      children: [
        masukCard,
        const SizedBox(height: 12),
        pulangCard,
      ],
    );
  }

  Widget _buildNavigationSection(bool isWide) {
    final absensiButton = _NavigationCard(
      title: 'Lakukan Absensi',
      subtitle: 'Masuk atau pulang',
      icon: Icons.fingerprint,
      onTap: onGoToAbsensi,
    );

    final riwayatButton = _NavigationCard(
      title: 'Riwayat Absensi',
      subtitle: 'Lihat catatan kehadiran',
      icon: Icons.history,
      onTap: onGoToRiwayat,
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: absensiButton),
          const SizedBox(width: 16),
          Expanded(child: riwayatButton),
        ],
      );
    }

    return Column(
      children: [
        absensiButton,
        const SizedBox(height: 12),
        riwayatButton,
      ],
    );
  }

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF2563EB),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pastikan lokasi dan kamera sudah aktif sebelum melakukan absensi.',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String time;
  final bool isCompleted;
  final String completedText;
  final String incompleteText;
  final IconData icon;
  final Color completedColor;

  const _StatusCard({
    required this.title,
    required this.time,
    required this.isCompleted,
    required this.completedText,
    required this.incompleteText,
    required this.icon,
    required this.completedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? completedColor : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle
                          : Icons.cancel_outlined,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        isCompleted
                            ? completedText
                            : incompleteText,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
