// ============================================================
// auth_service.dart – Service untuk Login & Sesi
// Tugas: Menangani komunikasi dengan API login.php,
//        menyimpan/menghapus sesi user di SharedPreferences.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  // ---- LOGIN ------------------------------------------------
  /// Kirim NIM dan password ke API, kembalikan UserModel jika berhasil.
  /// Lempar Exception dengan pesan error jika gagal.
  Future<UserModel> login(String nim, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: {'Content-Type': 'application/json'},
            // Kirim sebagai JSON body
            body: jsonEncode({'nim': nim, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['status'] == 'success') {
        final user = UserModel.fromJson(json['data']);
        // Simpan sesi ke SharedPreferences
        await _simpanSesi(user);
        return user;
      } else {
        throw Exception(json['message'] ?? 'Login gagal');
      }
    } on Exception {
      rethrow; // lempar ulang agar bisa ditangkap di UI
    }
  }

  // ---- SIMPAN SESI ------------------------------------------
  /// Simpan data user ke SharedPreferences setelah login berhasil.
  Future<void> _simpanSesi(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.userId);
    await prefs.setString('nama', user.nama);
    await prefs.setString('nim', user.nim);
  }

  // ---- AMBIL SESI -------------------------------------------
  /// Ambil data user dari SharedPreferences (untuk auto-login).
  /// Mengembalikan null jika belum login.
  Future<UserModel?> getSesi() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    if (userId == 0) return null;
    return UserModel(
      userId: userId,
      nama: prefs.getString('nama') ?? '',
      nim: prefs.getString('nim') ?? '',
    );
  }

  // ---- LOGOUT -----------------------------------------------
  /// Hapus semua data sesi dari SharedPreferences.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
