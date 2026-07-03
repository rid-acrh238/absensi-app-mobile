// ============================================================
// absensi_model.dart – Model data Absensi
// Tugas: Merepresentasikan satu record absensi dari API riwayat.
//        Menyediakan factory constructor untuk parse JSON.
// ============================================================

class AbsensiModel {
  final int id;
  final String tanggal;
final String? jamMasuk;
final String? jamPulang;
  final String jenisAbsen;
  final double latitude;
  final double longitude;
  final double? jarakMeter;
  final String foto; // path relatif, misal: uploads/foto_1_xxx.jpg
  final DateTime waktu;
  final String status; // 'hadir' atau 'terlambat'
  final String nama;
  final String nim;

  const AbsensiModel({
    required this.id,
     required this.tanggal,
     this.jamMasuk,
     this.jamPulang,
    required this.jenisAbsen,
    required this.latitude,
    required this.longitude,
    required this.jarakMeter,
    required this.foto,
    required this.waktu,
    required this.status,
    required this.nama,
    required this.nim,
  });

  /// Parse dari JSON response API riwayat
  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
  final waktuText = json['waktu']?.toString() ?? '';

  final jamMasukText = json['jam_masuk']?.toString();
  final jamPulangText = json['jam_pulang']?.toString();

  return AbsensiModel(
    id: int.tryParse(
          json['id']?.toString() ?? '',
        ) ??
        0,

    tanggal: json['tanggal']?.toString() ??
        (waktuText.contains(' ')
            ? waktuText.split(' ').first
            : waktuText),

    jamMasuk: jamMasukText == null ||
            jamMasukText.isEmpty ||
            jamMasukText == 'null'
        ? null
        : jamMasukText,

    jamPulang: jamPulangText == null ||
            jamPulangText.isEmpty ||
            jamPulangText == 'null'
        ? null
        : jamPulangText,

    jenisAbsen:
    json['jenis_absen']?.toString() ?? 'masuk',

    latitude: double.tryParse(
          json['latitude']?.toString() ?? '',
        ) ??
        0,

    longitude: double.tryParse(
          json['longitude']?.toString() ?? '',
        ) ??
        0,

    jarakMeter: double.tryParse(
      json['jarak_meter']?.toString() ?? '',
      ),


    foto: json['foto']?.toString() ?? '',

    waktu: DateTime.tryParse(waktuText) ??
        DateTime.now(),

    status: json['status']?.toString() ?? 'hadir',
    nama: json['nama']?.toString() ?? '',
    nim: json['nim']?.toString() ?? '',
  );
}

  /// Apakah status ini hadir (bukan terlambat)
  bool get isMasuk => status == 'masuk';
  bool get isPulang =>  jenisAbsen == 'pulang';
  bool get isHadir => status == 'hadir';
  bool get sudahMasuk =>
    jamMasuk != null && jamMasuk!.isNotEmpty;

bool get sudahPulang =>
    jamPulang != null && jamPulang!.isNotEmpty;
  bool get isTerlambat => status == 'terlambat';
}
