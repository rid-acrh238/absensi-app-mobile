// ============================================================
// absensi_screen.dart – Halaman Absensi
// Koordinat kampus diambil dari API settings.
// Setelah absensi berhasil, memanggil onAbsensiSuccess()
// agar RiwayatScreen di-refresh otomatis.
// Semua emoji diganti icon Flutter agar tidak muncul aneh
// di HP Android lama.
// ============================================================

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/user_model.dart';
import '../services/absensi_service.dart';
import '../services/settings_service.dart';

class AbsensiScreen extends StatefulWidget {
  final UserModel? user;

  /// Callback dipanggil setelah absensi berhasil
  /// agar HomeScreen bisa trigger refresh RiwayatScreen
  final VoidCallback? onAbsensiSuccess;

  const AbsensiScreen({
    super.key,
    this.user,
    this.onAbsensiSuccess,
  });

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  // ---- State Jam ----
  late Timer _jamTimer;
  String _jamSekarang = '';
  String _tanggalHari = '';

  // ---- State Lokasi ----
  double? _lat;
  double? _lng;
  double _jarak = 0;
  bool _dalamRadius = false;
  bool _loadingLokasi = true;
  String _pesanLokasi = 'Mendeteksi lokasi...';

  // ---- State Foto ----
  File? _fotoFile;
  final _picker = ImagePicker();

  // ---- State Absensi ----
  bool _isLoading = false;
  bool _sudahAbsen = false;
  String _statusAbsen = '';

  // ---- Map Controller ----
  final _mapController = MapController();

  // ---- Services ----
  final _absensiService = AbsensiService();
  final _settingsService = SettingsService();

  // ---- Koordinat kampus dari API settings ----
  double _kampusLat = -6.2088;
  double _kampusLng = 106.8456;
  double _maxRadius = 100;
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _startJamTimer();
    _loadSettingsThenLocation();
  }

  @override
  void dispose() {
    _jamTimer.cancel();
    super.dispose();
  }

  // ---- LOAD SETTINGS LALU GPS ------------------------------
  Future<void> _loadSettingsThenLocation() async {
    try {
      final s = await _settingsService.getSettings();
      if (mounted) {
        setState(() {
          _kampusLat = s.kampusLat;
          _kampusLng = s.kampusLng;
          _maxRadius = s.maxRadius;
          _settingsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _settingsLoaded = true);
    }
    await _getLocation();
  }

  // ---- JAM REAL-TIME ----------------------------------------
  void _startJamTimer() {
    _updateJam();
    _jamTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateJam());
  }

  void _updateJam() {
    final now = DateTime.now();
    final jam = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    final hariList = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final bulanList = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final tgl = '${hariList[now.weekday - 1]}, '
        '${now.day} ${bulanList[now.month]} ${now.year}';
    if (mounted) {
      setState(() {
        _jamSekarang = jam;
        _tanggalHari = tgl;
      });
    }
  }

  // ---- GPS --------------------------------------------------
  Future<void> _getLocation() async {
    setState(() {
      _loadingLokasi = true;
      _pesanLokasi = 'Mendeteksi lokasi...';
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _loadingLokasi = false;
        _pesanLokasi = 'GPS tidak aktif. Aktifkan di pengaturan.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _loadingLokasi = false;
          _pesanLokasi = 'Izin lokasi ditolak.';
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _loadingLokasi = false;
        _pesanLokasi =
            'Izin lokasi ditolak permanen. Buka Pengaturan > Aplikasi.';
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          ),
      );
      final jarak =
          _hitungJarak(pos.latitude, pos.longitude, _kampusLat, _kampusLng);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _jarak = jarak;
        _dalamRadius = jarak <= _maxRadius;
        _loadingLokasi = false;
        _pesanLokasi = '${pos.latitude.toStringAsFixed(6)}, '
            '${pos.longitude.toStringAsFixed(6)}';
      });
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
    } catch (e) {
      setState(() {
        _loadingLokasi = false;
        _pesanLokasi = 'Gagal mendapatkan lokasi: $e';
      });
    }
  }

  double _hitungJarak(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * pi / 180;

  // ---- KAMERA / FOTO ----------------------------------------
  Future<void> _ambilFotoKamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
      maxWidth: 640,
    );
    if (picked != null) setState(() => _fotoFile = File(picked.path));
  }

  Future<void> _pilihFotoGaleri() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 640,
    );
    if (picked != null) setState(() => _fotoFile = File(picked.path));
  }

  void _showPilihFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pilih Sumber Foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
              title: const Text('Buka Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _ambilFotoKamera();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF2563EB)),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pilihFotoGaleri();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---- PROSES ABSENSI ---------------------------------------
  Future<void> _doAbsensi() async {
    if (_lat == null || _lng == null) {
      _showSnackBar('Lokasi belum terdeteksi. Tekan Perbarui Lokasi.',
          isError: true);
      return;
    }
    if (_fotoFile == null) {
      _showSnackBar('Foto selfie wajib diambil sebelum absensi.',
          isError: true);
      return;
    }
    if (widget.user == null) {
      _showSnackBar('Sesi tidak valid. Silakan login ulang.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _absensiService.kirimAbsensi(
        userId: widget.user!.userId,
        latitude: _lat!,
        longitude: _lng!,
        fotoFile: _fotoFile,
      );

      if (!mounted) return;

      final status = result['status']?.toString() ?? 'hadir';
      final jarak = result['jarak']?.toString() ?? '-';
      final waktu = result['waktu']?.toString() ?? '-';

      setState(() {
        _sudahAbsen = true;
        _statusAbsen = status;
      });

      // Panggil callback agar RiwayatScreen auto-refresh
      widget.onAbsensiSuccess?.call();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(
              status == 'hadir' ? Icons.check_circle : Icons.warning_amber,
              color: status == 'hadir' ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Absensi Berhasil'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Status', status.toUpperCase(),
                  color: status == 'hadir' ? Colors.green : Colors.orange),
              _infoRow('Jarak', jarak),
              _infoRow('Waktu', waktu),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''),
          isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- HELPER -----------------------------------------------
  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ]),
    );
  }

  // ---- BUILD ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (!_settingsLoaded) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat konfigurasi...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 12),
          _buildLokasiCard(),
          const SizedBox(height: 12),
          _buildFotoCard(),
          const SizedBox(height: 16),
          _buildTombolAbsen(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---- STATUS CARD ------------------------------------------
  Widget _buildStatusCard() {
    final Color badgeColor;
    final String badgeText;
    final IconData badgeIcon;

    if (_sudahAbsen) {
      if (_statusAbsen == 'hadir') {
        badgeColor = Colors.green;
        badgeText = 'Hadir';
        badgeIcon = Icons.check_circle;
      } else {
        badgeColor = Colors.orange;
        badgeText = 'Terlambat';
        badgeIcon = Icons.warning_amber;
      }
    } else {
      badgeColor = Colors.grey.shade400;
      badgeText = 'Belum Absen Hari Ini';
      badgeIcon = Icons.radio_button_unchecked;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Tanggal & jam – pakai icon bukan emoji
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(_tanggalHari,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
              Row(children: [
                const Icon(Icons.access_time, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(_jamSekarang,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace')),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 16, color: badgeColor),
                const SizedBox(width: 6),
                Text(badgeText,
                    style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ---- LOKASI CARD ------------------------------------------
  Widget _buildLokasiCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul – pakai icon bukan emoji
            Row(children: const [
              Icon(Icons.location_on, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text('Lokasi Anda',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),

            // Peta
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_kampusLat, _kampusLng),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.absensi.absensi_app',
                    ),
                    CircleLayer(circles: [
                      CircleMarker(
                        point: LatLng(_kampusLat, _kampusLng),
                        radius: _maxRadius,
                        useRadiusInMeter: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      ),
                    ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(_kampusLat, _kampusLng),
                        width: 36,
                        height: 36,
                        child: const Icon(Icons.school,
                            color: Colors.blue, size: 32),
                      ),
                      if (_lat != null && _lng != null)
                        Marker(
                          point: LatLng(_lat!, _lng!),
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.location_pin,
                              color: Colors.red, size: 36),
                        ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _lokasiRow('Koordinat', _pesanLokasi),
            _lokasiRow(
              'Jarak ke Kampus',
              _lat == null
                  ? '-'
                  : '${_jarak.round()} m (maks ${_maxRadius.round()} m)',
            ),
            _lokasiRow(
              'Status Lokasi',
              _lat == null
                  ? '-'
                  : _dalamRadius
                      ? 'Dalam radius kampus'
                      : 'Di luar radius kampus',
              valueColor: _lat == null
                  ? null
                  : _dalamRadius
                      ? Colors.green
                      : Colors.red,
              valueIcon: _lat == null
                  ? null
                  : _dalamRadius
                      ? Icons.check_circle
                      : Icons.cancel,
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadingLokasi ? null : _getLocation,
                icon: _loadingLokasi
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label:
                    Text(_loadingLokasi ? 'Mendeteksi...' : 'Perbarui Lokasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lokasiRow(String label, String value,
      {Color? valueColor, IconData? valueIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (valueIcon != null) ...[
                  Icon(valueIcon, size: 13, color: valueColor),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: valueColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- FOTO CARD --------------------------------------------
  Widget _buildFotoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.camera_alt, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text('Foto Selfie',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            if (_fotoFile != null)
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_fotoFile!,
                      width: double.infinity, height: 220, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _fotoFile = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ])
            else
              GestureDetector(
                onTap: _showPilihFoto,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade50,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 36, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Ketuk untuk ambil foto',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ambilFotoKamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pilihFotoGaleri,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ---- TOMBOL ABSEN -----------------------------------------
  Widget _buildTombolAbsen() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: (_isLoading || _sudahAbsen) ? null : _doAbsensi,
        style: ElevatedButton.styleFrom(
          backgroundColor: _sudahAbsen ? Colors.grey : const Color(0xFF2563EB),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Icon(_sudahAbsen ? Icons.check : Icons.fingerprint),
        label: Text(
          _isLoading
              ? 'Memproses...'
              : _sudahAbsen
                  ? 'Sudah Absen Hari Ini'
                  : 'Lakukan Absensi',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
