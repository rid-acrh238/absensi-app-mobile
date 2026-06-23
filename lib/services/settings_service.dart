// ============================================================
// settings_service.dart – Service untuk baca Settings dari API
// Tugas: Mengambil koordinat kampus, radius, dan batas jam
//        dari API settings.php agar sinkron dengan admin panel.
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class KampusSettings {
  final double kampusLat;
  final double kampusLng;
  final double maxRadius;
  final int batasJam;
  final int batasMenit;

  const KampusSettings({
    required this.kampusLat,
    required this.kampusLng,
    required this.maxRadius,
    required this.batasJam,
    required this.batasMenit,
  });

  /// Nilai default jika API tidak bisa diakses
  factory KampusSettings.defaultValues() => const KampusSettings(
        kampusLat: -6.2088,
        kampusLng: 106.8456,
        maxRadius: 100,
        batasJam: 8,
        batasMenit: 0,
      );
}

class SettingsService {
  /// Ambil settings dari API settings.php
  /// Jika gagal, kembalikan nilai default agar app tetap berjalan
  Future<KampusSettings> getSettings() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.settings))
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['status'] == 'success' && json['data'] != null) {
        final data = json['data'] as Map<String, dynamic>;

        return KampusSettings(
          kampusLat:
              double.tryParse(data['kampus_lat']?['value']?.toString() ?? '') ??
                  -6.2088,
          kampusLng:
              double.tryParse(data['kampus_lng']?['value']?.toString() ?? '') ??
                  106.8456,
          maxRadius:
              double.tryParse(data['max_radius']?['value']?.toString() ?? '') ??
                  100,
          batasJam:
              int.tryParse(data['batas_jam']?['value']?.toString() ?? '') ?? 8,
          batasMenit:
              int.tryParse(data['batas_menit']?['value']?.toString() ?? '') ??
                  0,
        );
      }
    } on SocketException {
      // Tidak ada koneksi – pakai default
    } catch (_) {
      // Error lain – pakai default
    }

    return KampusSettings.defaultValues();
  }
}
