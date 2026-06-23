// ============================================================
// absensi_model.dart – Model data Absensi
// Tugas: Merepresentasikan satu record absensi dari API riwayat.
//        Menyediakan factory constructor untuk parse JSON.
// ============================================================

class AbsensiModel {
  final int id;
  final double latitude;
  final double longitude;
  final String foto; // path relatif, misal: uploads/foto_1_xxx.jpg
  final DateTime waktu;
  final String status; // 'hadir' atau 'terlambat'
  final String nama;
  final String nim;

  const AbsensiModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.foto,
    required this.waktu,
    required this.status,
    required this.nama,
    required this.nim,
  });

  /// Parse dari JSON response API riwayat
  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
    return AbsensiModel(
      id: int.parse(json['id'].toString()),
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      foto: json['foto'] ?? '',
      // API mengembalikan format "2026-05-11 11:25:46"
      waktu: DateTime.parse(json['waktu']),
      status: json['status'] ?? 'hadir',
      nama: json['nama'] ?? '',
      nim: json['nim'] ?? '',
    );
  }

  /// Apakah status ini hadir (bukan terlambat)
  bool get isHadir => status == 'hadir';
}
