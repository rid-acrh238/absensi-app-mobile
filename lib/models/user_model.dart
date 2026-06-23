// ============================================================
// user_model.dart – Model data User
// Tugas: Merepresentasikan data user yang dikembalikan API login.
//        Menyediakan factory constructor untuk parse JSON.
// ============================================================

class UserModel {
  final int userId;
  final String nama;
  final String nim;

  const UserModel({
    required this.userId,
    required this.nama,
    required this.nim,
  });

  /// Parse dari JSON response API login
  /// Contoh JSON: {"user_id": 1, "nama": "Ahmad Fauzi", "nim": "2021001"}
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      nama: json['nama']?.toString() ?? '',
      nim: json['nim']?.toString() ?? '',
    );
  }

  /// Konversi ke Map untuk disimpan ke SharedPreferences
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'nama': nama,
        'nim': nim,
      };
}
