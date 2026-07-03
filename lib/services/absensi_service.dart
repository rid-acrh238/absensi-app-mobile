// ============================================================
// absensi_service.dart – Service untuk Absensi & Riwayat
// Tugas: Menangani komunikasi dengan API absensi.php dan
//        riwayat.php. Mengirim data lokasi + foto ke server.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
  required String jenisAbsen,
  required double jarakMeter,
  required double latitude,
  required double longitude,
  Uint8List? fotoBytes,
}) async {
  String fotoBase64 = '';

  if (fotoBytes != null) {
    fotoBase64 =
        'data:image/jpeg;base64,${base64Encode(fotoBytes)}';
  }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.absensi),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'jenis_absen': jenisAbsen,
              'latitude': latitude,
              'longitude': longitude,
              'jarak_meter': jarakMeter,
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
    } on TimeoutException {
  throw Exception(
    'Koneksi ke server terlalu lama.',
  );
} on http.ClientException {
  throw Exception(
    'Tidak dapat terhubung ke server.',
  );
} on FormatException catch (e) {
  throw Exception(
    'Format data riwayat tidak cocok: $e',
  );
} catch (e) {
  throw Exception(
    e.toString().replaceFirst('Exception: ', ''),
  );
}
  }


  // ---- STATUS ABSENSI HARI INI -----------------------------
Future<Map<String, dynamic>> getStatusHariIni(int userId) async {
  try {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.absensi}?user_id=$userId',
          ),
        )
        .timeout(const Duration(seconds: 15));

    final json =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (json['status'] == 'success') {
      return json['data'] as Map<String, dynamic>;
    }

    throw Exception(
      json['message'] ?? 'Gagal mengambil status absensi',
    );
  } on TimeoutException {
    throw Exception('Koneksi ke server terlalu lama.');
  } on http.ClientException {
    throw Exception('Tidak dapat terhubung ke server.');
  } on FormatException {
    throw Exception('Respons server tidak valid.');
  } catch (e) {
    throw Exception(
      e.toString().replaceFirst('Exception: ', ''),
    );
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
    } on TimeoutException {
  throw Exception(
    'Koneksi ke server terlalu lama.',
  );
} on http.ClientException {
  throw Exception(
    'Tidak dapat terhubung ke server.',
  );
} on FormatException {
  throw Exception(
    'Respons server tidak valid.',
  );
} catch (e) {
  throw Exception(
    e.toString().replaceFirst('Exception: ', ''),
  );
}
}
}