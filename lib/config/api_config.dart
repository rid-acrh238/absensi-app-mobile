// ============================================================
// api_config.dart – Konfigurasi URL API
// Tugas: Menyimpan semua URL endpoint API di satu tempat
//        agar mudah diubah saat pindah server/IP.
// ============================================================

class ApiConfig {
  // ----------------------------------------------------------------
  // GANTI IP ini dengan IP komputer yang menjalankan XAMPP.
  // Cara cek IP: buka CMD → ketik "ipconfig" → lihat IPv4 Address.
  // Contoh: 192.168.1.100
  // Jangan gunakan "localhost" karena di Android = loopback HP sendiri.
  // ----------------------------------------------------------------
  static const String serverIp = '192.168.56.1';
  static const String baseUrl = 'http://$serverIp/absensi/api';

  // Endpoint login – POST nim & password
  static const String login = '$baseUrl/login.php';

  // Endpoint absensi – POST user_id, latitude, longitude, foto (base64)
  static const String absensi = '$baseUrl/absensi.php';

  // Endpoint riwayat – GET ?user_id=xxx
  static const String riwayat = '$baseUrl/riwayat.php';

  // Endpoint settings – GET koordinat kampus & radius
  static const String settings = '$baseUrl/settings.php';

  // Base URL untuk foto (digunakan untuk menampilkan gambar dari server)
  // Contoh: http://192.168.0.170/absensi/uploads/foto_1_xxx.jpg
  static const String fotoBase = 'http://$serverIp/absensi';
}
