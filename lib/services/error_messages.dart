import 'package:supabase_flutter/supabase_flutter.dart';

/// Map Supabase/Dart errors to friendly, localized messages for the UI.
String mapAuthError(Object error) {
  if (error is AuthException) {
    return mapAuthException(error);
  }

  final msg = error.toString().toLowerCase();
  if (msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('network') ||
      msg.contains('connection') ||
      msg.contains('timed out') ||
      msg.contains('timeout')) {
    return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}

String mapAuthException(AuthException e) {
  final message = e.message.toLowerCase();
  final code = (e.statusCode ?? '').toString();

  // Network related (sometimes wrapped into AuthException message)
  if (message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('timed out') ||
      message.contains('timeout')) {
    return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
  }

  // Invalid credentials
  if (message.contains('invalid login credentials') ||
      message.contains('invalid email or password') ||
      code == '400' || code == '401') {
    return 'Email atau password salah.';
  }

  // Email not confirmed
  if (message.contains('email not confirmed') ||
      message.contains('email not verified') ||
      message.contains('email_confirmation_required')) {
    return 'Email belum diverifikasi. Cek inbox Anda.';
  }

  // User not found
  if (message.contains('user not found') ||
      message.contains('unknown user')) {
    return 'Akun tidak ditemukan. Periksa email Anda.';
  }

  // Invalid email
  if (message.contains('invalid email')) {
    return 'Format email tidak valid.';
  }

  // Too many requests / rate limit
  if (message.contains('too many requests') ||
      message.contains('rate limit')) {
    return 'Terlalu banyak percobaan. Tunggu beberapa menit.';
  }

  // User disabled/banned
  if (message.contains('user disabled') || message.contains('banned')) {
    return 'Akun dinonaktifkan. Hubungi administrator.';
  }

  // Weak password (for sign up)
  if (message.contains('weak') && message.contains('password')) {
    return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
  }

  // OTP / reset password issues
  if (message.contains('otp') || message.contains('token')) {
    return 'Kode verifikasi tidak valid atau kedaluwarsa.';
  }

  // Server/internal
  if (message.contains('database') ||
      message.contains('server error') ||
      message.contains('internal')) {
    return 'Server sedang bermasalah. Coba lagi nanti.';
  }

  // Default: show original (already localized by us where possible)
  return e.message;
}

