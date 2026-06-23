// ============================================================
// home_screen.dart – Halaman Utama (Tab Container)
// Tugas: Menampilkan BottomNavigationBar dengan 2 tab.
//        Menyediakan GlobalKey untuk RiwayatScreen agar
//        AbsensiScreen bisa memicu refresh riwayat otomatis
//        setelah absensi berhasil.
// ============================================================

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'absensi_screen.dart';
import 'riwayat_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  final _authService = AuthService();

  // GlobalKey untuk mengakses method refresh di RiwayatScreen
  final GlobalKey<RiwayatScreenState> _riwayatKey =
      GlobalKey<RiwayatScreenState>();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getSesi();
    if (mounted) setState(() => _currentUser = user);
  }

  /// Dipanggil oleh AbsensiScreen setelah absensi berhasil
  /// agar RiwayatScreen langsung refresh tanpa perlu pull-to-refresh
  void _onAbsensiSuccess() {
    _riwayatKey.currentState?.loadRiwayat();
  }

  Future<void> _doLogout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      // Kirim callback onAbsensiSuccess agar riwayat auto-refresh
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_currentUser != null)
              Text(
                'NIM: ${_currentUser!.nim}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _doLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Refresh riwayat setiap kali tab Riwayat dibuka
          if (index == 1) {
            _riwayatKey.currentState?.loadRiwayat();
          }
        },
        selectedItemColor: const Color(0xFF2563EB),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'Absensi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}
