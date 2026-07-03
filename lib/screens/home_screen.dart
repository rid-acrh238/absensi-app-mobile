// ============================================================
// home_screen.dart – Halaman Utama (Tab Container)
// Tugas: Menampilkan NavigationBar Material 3 yang modern.
// ============================================================

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/absensi_service.dart';
import 'absensi_screen.dart';
import 'riwayat_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../models/absensi_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUser;
  final AbsensiService _absensiService = AbsensiService();

  bool _loadingStatus = true;
  bool _sudahMasuk = false;
  bool _sudahPulang = false;
  bool _loadingGrafik = true;
  List<AbsensiModel> _riwayatDashboard = [];

  String? _jamMasuk;
  String? _jamPulang;

  final _authService = AuthService();

  final GlobalKey<RiwayatScreenState> _riwayatKey =
      GlobalKey<RiwayatScreenState>();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }
  
  void _goToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadUser() async {
    final user = await _authService.getSesi();

    if (!mounted) return;

    setState(() {
      _currentUser = user;
    });

    await _loadStatusHariIni();
    await _loadGrafikKehadiran();
  }

  void _onAbsensiSuccess() {
    _loadStatusHariIni();
    _loadGrafikKehadiran();
    _riwayatKey.currentState?.loadRiwayat();
  }

  Future<void> _loadStatusHariIni() async {
    final user = _currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingStatus = false);
      return;
    }

    try {
      final data = await _absensiService.getStatusHariIni(user.userId);
      if (!mounted) return;

      final jamMasuk = data['jam_masuk']?.toString();
      final jamPulang = data['jam_pulang']?.toString();

      final sudahMasuk = data['sudah_masuk'] == true ||
          (jamMasuk != null && jamMasuk.isNotEmpty && jamMasuk != 'null');

      final sudahPulang = data['sudah_pulang'] == true ||
          (jamPulang != null && jamPulang.isNotEmpty && jamPulang != 'null');

      setState(() {
        _jamMasuk = jamMasuk;
        _jamPulang = jamPulang;
        _sudahMasuk = sudahMasuk;
        _sudahPulang = sudahPulang;
        _loadingStatus = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStatus = false);
      debugPrint('Gagal memuat status dashboard: $e');
    }
  }

  Future<void> _loadGrafikKehadiran() async {
    final user = _currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingGrafik = false);
      return;
    }

    try {
      final data = await _absensiService.getRiwayat(user.userId);
      if (!mounted) return;

      setState(() {
        _riwayatDashboard = data;
        _loadingGrafik = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingGrafik = false);
      debugPrint('Gagal memuat grafik kehadiran: $e');
    }
  }

  Future<void> _doLogout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(100, 45),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;
    await _authService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        user: _currentUser,
        statusLoading: _loadingStatus,
        chartLoading: _loadingGrafik,
        riwayat: _riwayatDashboard,
        sudahMasuk: _sudahMasuk,
        sudahPulang: _sudahPulang,
        jamMasuk: _jamMasuk,
        jamPulang: _jamPulang,
        onGoToAbsensi: () => _goToPage(1),
        onGoToRiwayat: () => _goToPage(2),
      ),
      AbsensiScreen(
        user: _currentUser,
        onAbsensiSuccess: _onAbsensiSuccess,
      ),
      RiwayatScreen(
        key: _riwayatKey,
        user: _currentUser,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentUser?.nama ?? 'Smart Attendance',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_currentUser != null)
              Text(
                'NIM: ${_currentUser!.nim}',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: _doLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      // Navigasi Mobile Modern bergaya Pill (Material 3)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            _riwayatKey.currentState?.loadRiwayat();
          }
        },
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: const Color(0xFFDBEAFE),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF1D4ED8)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.fingerprint_outlined),
            selectedIcon: Icon(Icons.fingerprint, color: Color(0xFF1D4ED8)),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF1D4ED8)),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}