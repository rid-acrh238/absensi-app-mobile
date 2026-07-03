// ============================================================
// dashboard_screen.dart – Halaman Dashboard
// Tampilan: Dirombak total menjadi layout modern, responsif, 
// dengan Hero Banner dan Grid Status, tanpa menyentuh logika.
// ============================================================

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
    const namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
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
        final horizontalPadding = isWide ? 32.0 : 20.0;
        final contentWidth = isWide ? 1000.0 : double.infinity;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Profil & Tanggal
                    _buildModernHeader(tanggalHariIni),
                    const SizedBox(height: 28),

                    // 2. Hero Banner (Aksi Utama)
                    _buildHeroBanner(),
                    const SizedBox(height: 28),

                    // 3. Grid Status Absensi Hari Ini
                    const Text(
                      'Status Hari Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusGrid(isWide),
                    const SizedBox(height: 28),

                    // 4. Grafik Kehadiran
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Statistik Kehadiran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: onGoToRiwayat,
                          child: const Text('Lihat Riwayat'),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildGrafikKehadiran(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- KOMPONEN 1: Header Modern ----
  Widget _buildModernHeader(String tanggal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tanggal,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Halo, ${user?.nama ?? 'Mahasiswa'} 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 32,
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  // ---- KOMPONEN 2: Hero Banner ----
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Waktunya Absen',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Jangan lupa catat\nkehadiranmu hari ini!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onGoToAbsensi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size(140, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Mulai Absensi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Ilustrasi ikon besar transparan di kanan
          const Icon(
            Icons.fingerprint_rounded,
            size: 100,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }

  // ---- KOMPONEN 3: Grid Status (Masuk & Pulang) ----
  Widget _buildStatusGrid(bool isWide) {
    if (statusLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    Widget cardMasuk = _GridStatusCard(
      title: 'Masuk',
      time: jamMasuk ?? '--:--',
      isCompleted: sudahMasuk,
      icon: Icons.login_rounded,
      color: Colors.green,
    );

    Widget cardPulang = _GridStatusCard(
      title: 'Pulang',
      time: jamPulang ?? '--:--',
      isCompleted: sudahPulang,
      icon: Icons.logout_rounded,
      color: Colors.blue,
    );

    return Row(
      children: [
        Expanded(child: cardMasuk),
        const SizedBox(width: 16),
        Expanded(child: cardPulang),
      ],
    );
  }

  // ---- KOMPONEN 4: Grafik Kehadiran (Tetap memakai logika asli) ----
  Widget _buildGrafikKehadiran() {
    if (chartLoading) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final dataMasuk = riwayat.where((item) {
      final jam = item.jamMasuk;
      return jam != null && jam.isNotEmpty && jam.toLowerCase() != 'null';
    }).toList();

    if (dataMasuk.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada data kehadiran',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final terlambat = dataMasuk.where((item) => item.status.toLowerCase() == 'terlambat').length;
    final hadir = dataMasuk.length - terlambat;
    final nilaiTertinggi = hadir > terlambat ? hadir : terlambat;
    final maxY = nilaiTertinggi == 0 ? 1.0 : nilaiTertinggi.toDouble() + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildChartSummary(label: 'Hadir', total: hadir, color: Colors.green),
              const SizedBox(width: 16),
              _buildChartSummary(label: 'Terlambat', total: terlambat, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                ),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text('Hadir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          );
                        }
                        if (value.toInt() == 1) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text('Terlambat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                        width: 32,
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: terlambat.toDouble(),
                        width: 32,
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSummary({required String label, required int total, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $total',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
      ],
    );
  }
}

// ---- Widget Ekstra untuk Grid Status ----
class _GridStatusCard extends StatelessWidget {
  final String title;
  final String time;
  final bool isCompleted;
  final IconData icon;
  final Color color;

  const _GridStatusCard({
    required this.title,
    required this.time,
    required this.isCompleted,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Memperpendek format jam agar rapi di grid (misal "08:30:15" jadi "08:30")
    String displayTime = time;
    if (time.length > 5 && time.contains(':')) {
       final parts = time.split(':');
       if(parts.length >= 2) displayTime = '${parts[0]}:${parts[1]}';
    }

    final activeColor = isCompleted ? color : Colors.grey.shade400;
    final bgColor = isCompleted ? color.withOpacity(0.1) : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: activeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isCompleted ? displayTime : '--:--',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isCompleted ? const Color(0xFF1E293B) : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                size: 14,
                color: activeColor,
              ),
              const SizedBox(width: 4),
              Text(
                isCompleted ? 'Tercatat' : 'Belum',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}