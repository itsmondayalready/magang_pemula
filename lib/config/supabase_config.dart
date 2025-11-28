import 'dart:convert';

/// Konfigurasi Supabase dengan obfuscation sederhana (Base64)
/// Catatan: Ini bukan keamanan penuh, tetapi menyulitkan pembacaan langsung.
class SupabaseConfig {
  // Base64 dari: https://gcqxynheshjonedcnwbp.supabase.co
  static const String _obfuscatedUrl =
      'aHR0cHM6Ly9nY3F4eW5oZXNoam9uZWRjbndicC5zdXBhYmFzZS5jbw==';

  // Base64 dari anon key JWT (disembunyikan sebagai string Base64)
  static const String _obfuscatedAnonKey =
      'ZXlKaGJHY2lPaUpJVXpJMU5pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SnBjM01pT2lKemRYQmhZbUZ6WlNJc0luSmxaaUk2SW1kamNYaDVibWhsYzJocWIyNWxaR051ZDJKd0lpd2ljbTlzWlNJNkltRnViMjRpTENKcFlYUWlPakUzTmpFMU1qUTNPVE1zSW1WNGNDSTZNakEzTnpFd01EYzVNMzAuUWFTcE1LNGZhNS1JTE9nYkNnMXgxZXRfWm1jSE93WWxDWnc0Sm44SmxWZw==';

  static String get url {
    try {
      return utf8.decode(base64.decode(_obfuscatedUrl));
    } catch (_) {
      return '';
    }
  }

  static String get anonKey {
    try {
      return utf8.decode(base64.decode(_obfuscatedAnonKey));
    } catch (_) {
      return '';
    }
  }
}
