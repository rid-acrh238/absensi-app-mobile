// ============================================================
// login_screen.dart – Halaman Login
// Tugas: Menampilkan form NIM + Password, validasi input,
//        memanggil AuthService.login(), dan navigasi ke
//        HomeScreen jika berhasil.
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk membaca nilai input field
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();

  // Key untuk validasi form
  final _formKey = GlobalKey<FormState>();

  // State loading dan tampil/sembunyikan password
  bool _isLoading = false;
  bool _passwordVisible = false;

  final _authService = AuthService();

  @override
  void dispose() {
    // Bersihkan controller saat widget dihapus dari tree
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---- PROSES LOGIN -----------------------------------------
  Future<void> _doLogin() async {
    // Validasi form terlebih dahulu
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Login berhasil – tidak perlu simpan return value
      await _authService.login(
        _nimController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      // Tampilkan pesan error di SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- BUILD UI ---------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background gradient biru
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF38BDF8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ---- Logo & Judul ----
                  const Icon(
                    Icons.assignment_turned_in,
                    size: 72,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Smart Attendance',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Sistem Absensi Digital',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  // ---- Card Form Login ----
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Input NIM
                            TextFormField(
                              controller: _nimController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'NIM',
                                hintText: 'Masukkan NIM Anda',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                      ? 'NIM wajib diisi'
                                      : null,
                            ),
                            const SizedBox(height: 16),

                            // Input Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_passwordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Masukkan password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                // Tombol show/hide password
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _passwordVisible = !_passwordVisible,
                                  ),
                                ),
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                      ? 'Password wajib diisi'
                                      : null,
                              // Submit form saat tekan Enter di keyboard
                              onFieldSubmitted: (_) => _doLogin(),
                            ),
                            const SizedBox(height: 24),

                            // Tombol Login
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _doLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
