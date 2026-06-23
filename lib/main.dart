// ============================================================
// main.dart – Entry point aplikasi
// Tugas: Inisialisasi Flutter, set tema, dan tentukan halaman
//        awal berdasarkan status login (ada sesi atau tidak).
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Pastikan binding Flutter siap sebelum akses plugin (SharedPreferences)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Attendance',
      debugShowCheckedModeBanner: false,

      // ---- Tema global aplikasi ----
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // biru utama
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',

        // Gaya AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E40AF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        // Gaya tombol utama
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Gaya input field
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),

      // ---- Tentukan halaman awal ----
      // FutureBuilder digunakan karena cek SharedPreferences bersifat async
      home: FutureBuilder<bool>(
        future: _cekSudahLogin(),
        builder: (context, snapshot) {
          // Tampilkan loading spinner saat mengecek sesi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Jika sudah login → langsung ke HomeScreen
          // Jika belum → ke LoginScreen
          final sudahLogin = snapshot.data ?? false;
          return sudahLogin ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }

  /// Cek apakah user sudah login dengan melihat SharedPreferences.
  /// Mengembalikan true jika user_id tersimpan dan > 0.
  Future<bool> _cekSudahLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    return userId > 0;
  }
}
