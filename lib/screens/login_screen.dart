import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/error_messages.dart';
import '../utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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

  Future<void> _signInGuest() async {
    setState(() => _error = null);
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await auth.signInAnonymously();
      // Login Guest berhasil - Consumer di main.dart akan redirect otomatis
    } on AuthException catch (e) {
      debugPrint('[Login] Guest sign-in AuthException: ${e.message}');
      final msg = _friendly(e);
      if (mounted) setState(() => _error = msg);
    } catch (e) {
      debugPrint('[Login] Guest sign-in unexpected error: $e');
      if (mounted) {
        setState(() => _error = _friendly(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Centralized error mapping (reuses services/error_messages.dart)
  String _friendly(Object error) => mapAuthError(error);

  Future<void> _submit() async {
    setState(() => _error = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    // Manual validation routed to a single message field
    if (email.isEmpty) {
      setState(() => _error = 'Masukkan email');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Masukkan password');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter');
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await auth.signIn(
        email: email,
        password: password,
      );
      // Login berhasil - Consumer di main.dart akan otomatis redirect ke MainMenu
    } on AuthException catch (e) {
      debugPrint('[Login] AuthException: ${e.message}');
      final msg = _friendly(e);
      if (mounted) setState(() => _error = msg);
    } catch (e) {
      debugPrint('[Login] Unexpected error: $e');
      if (mounted) {
        setState(() => _error = _friendly(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  Builder(builder: (context) {
                    return Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.rf(26),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(color: Colors.white70, fontSize: context.rf(14)),
                  ),
                  const SizedBox(height: 20),
                  Container(
          width: MediaQuery.of(context).size.width < 420
            ? MediaQuery.of(context).size.width
            : 420,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
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
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: const TextStyle(color: Colors.black45),
                              filled: true,
                              fillColor: Colors.grey[100],
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.email,
                                  color: Colors.black54,
                                  size: 18,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) {
                              if (_error != null) setState(() => _error = null);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(color: Colors.black45),
                              filled: true,
                              fillColor: Colors.grey[100],
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.black54,
                                  size: 18,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.black45,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) {
                              if (_error != null) setState(() => _error = null);
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orangeAccent.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.orangeAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(30),
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: _isLoading ? null : _submit,
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Sign In',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: context.rf(14),
                                            ),
                                          ),
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
                                setState(
                                  () => _error =
                                      'Masukkan email untuk reset password',
                                );
                                return;
                              }
                              final auth = Provider.of<AuthService>(
                                context,
                                listen: false,
                              );
                              try {
                                await auth.sendPasswordResetEmail(email);
                                setState(
                                  () => _error =
                                      'Instruksi reset dikirim ke email',
                                );
                              } on AuthException catch (e) {
                                final msg = _friendly(e);
                                setState(() => _error = msg);
                              } catch (e) {
                                debugPrint('[Login] Reset password error: $e');
                                setState(() => _error = _friendly(e));
                              }
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 220,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInGuest,
                      icon: const Icon(Icons.person_2),
                      label: const Text('Masuk sebagai Guest'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
