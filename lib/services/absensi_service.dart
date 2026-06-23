// ============================================================
// absensi_service.dart – Service untuk Absensi & Riwayat
// Tugas: Menangani komunikasi dengan API absensi.php dan
//        riwayat.php. Mengirim data lokasi + foto ke server.
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/absensi_model.dart';

class AbsensiService {
  // ---- KIRIM ABSENSI ----------------------------------------
  /// Kirim data absensi ke server.
  /// [userId]    : ID user yang login
  /// [latitude]  : koordinat lintang dari GPS
  /// [longitude] : koordinat bujur dari GPS
  /// [fotoFile]  : file foto selfie (boleh null jika tidak ada)
  

  Future<Map<String, dynamic>> kirimAbsensi({
    required int userId,
    required double latitude,
    required double longitude,
    File? fotoFile,
  }) async {
    // Encode foto ke Base64 jika ada
    String fotoBase64 = '';
    if (fotoFile != null) {
      final bytes = await fotoFile.readAsBytes();
      fotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.absensi),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'latitude': latitude,
              'longitude': longitude,
              'foto': fotoBase64,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
          ); // timeout lebih lama karena upload foto

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['status'] == 'success') {
        return json['data'] as Map<String, dynamic>;
      } else {
        throw Exception(json['message'] ?? 'Absensi gagal');
      }
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi jaringan.',
      );
    } on Exception {
      rethrow;
    }
  }

  // ---- AMBIL RIWAYAT ----------------------------------------
  /// Ambil 30 riwayat absensi terakhir untuk user tertentu.
  
  Future<List<AbsensiModel>> getRiwayat(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.riwayat}?user_id=$userId'))
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['status'] == 'success') {
        final List<dynamic> data = json['data'] as List<dynamic>;
        return data
            .map((item) => AbsensiModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'Gagal memuat riwayat');
      }
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server.');
    } on Exception {
      rethrow;
    }
  }
}
