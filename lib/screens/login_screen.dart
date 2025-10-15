import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _friendlyMessageForCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun dengan email tersebut tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun dinonaktifkan. Hubungi dukungan.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await auth.signIn(email: _emailController.text.trim(), password: _passwordController.text.trim());
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'Login gagal');
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2), // Biru
              Color(0xFF00BCD4), // Sian
              Color(0xFF4CAF50), // Hijau
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  const Text('Welcome back', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Sign in to continue', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width < 420 ? MediaQuery.of(context).size.width : 420,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  hintStyle: const TextStyle(color: Colors.black45),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                                    child: const Icon(Icons.email, color: Colors.black54, size: 18),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Masukkan email' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(color: Colors.black45),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                                    child: const Icon(Icons.lock, color: Colors.black54, size: 18),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black45),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Masukkan password';
                                  if (v.length < 6) return 'Password minimal 6 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              if (_error != null) ...[
                                Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
                                const SizedBox(height: 10),
                              ],
                              SizedBox(
                                width: 180,
                                height: 44,
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Ink(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF1976D2), // Biru
                                          Color(0xFF00BCD4), // Sian
                                          Color(0xFF4CAF50), // Hijau
                                        ],
                                      ),
                                      borderRadius: BorderRadius.all(Radius.circular(30)),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(30),
                                      onTap: _isLoading ? null : _submit,
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                            : const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () async {
                                  final email = _emailController.text.trim();
                                  if (email.isEmpty) {
                                    setState(() => _error = 'Masukkan email untuk reset password');
                                    return;
                                  }
                                  final auth = Provider.of<AuthService>(context, listen: false);
                                  try {
                                    await auth.sendPasswordResetEmail(email);
                                    setState(() => _error = 'Instruksi reset dikirim ke email');
                                  } catch (e) {
                                    String msg = 'Gagal mengirim instruksi reset';
                                    try {
                                      final code = (e as dynamic).code as String?;
                                      if (code != null) msg = _friendlyMessageForCode(code) ?? msg;
                                    } catch (_) {}
                                    setState(() => _error = msg);
                                  }
                                },
                                child: const Text('Forgot password?', style: TextStyle(color: Colors.white70)),
                              ),
                            ],
                          ),
                        ),
                  ),
                  const SizedBox(height: 18),
                  const Text('BUILD: signin-v2', style: TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
