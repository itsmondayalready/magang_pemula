import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  String? _userRole; // 'admin', 'user', or 'guest' from Supabase users table

  AuthService() {
    debugPrint('');
    debugPrint('🚀 ══════════════════════════════════════════════════════');
    debugPrint('[AuthService] INITIALIZING AUTH SERVICE');
    debugPrint('🚀 ══════════════════════════════════════════════════════');
    
    // Initialize with current session user
    _user = _supabase.auth.currentUser;
    
    debugPrint('');
    debugPrint('[AuthService] Current Session Check:');
    debugPrint('[AuthService] Has existing session: ${_user != null}');
    if (_user != null) {
      debugPrint('[AuthService] Existing User ID: ${_user!.id}');
      debugPrint('[AuthService] Existing User Email: ${_user!.email}');
      debugPrint('[AuthService] Is Anonymous: ${_user!.isAnonymous}');
      _fetchUserRole(_user!.id);
    } else {
      debugPrint('[AuthService] No existing session - user needs to login');
    }
    debugPrint('');
    
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      debugPrint('');
      debugPrint('🔄 ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] AUTH STATE CHANGE DETECTED');
      debugPrint('[AuthService] Event: ${data.event}');
      debugPrint('🔄 ══════════════════════════════════════════════════════');
      
      _user = data.session?.user;
      
      if (_user != null) {
        debugPrint('[AuthService] New User State:');
        debugPrint('[AuthService] User ID: ${_user!.id}');
        debugPrint('[AuthService] Email: ${_user!.email}');
        debugPrint('[AuthService] Is Anonymous: ${_user!.isAnonymous}');
        await _fetchUserRole(_user!.id);
      } else {
        debugPrint('[AuthService] User logged out - clearing role');
        _userRole = null;
      }
      debugPrint('');
      
      notifyListeners();
    });
  }

  String? get userEmail => _user?.email;
  bool get isSignedIn {
    final signedIn = _user != null;
    debugPrint('[AuthService] 🔍 isSignedIn getter called: $signedIn (user: ${_user?.email ?? "null"})');
    return signedIn;
  }
  bool get isGuest {
    final guest = _user != null && _user!.isAnonymous;
    debugPrint('[AuthService] 🔍 isGuest getter called: $guest');
    return guest;
  }
  bool get isAdmin {
    final admin = _userRole == 'admin';
    debugPrint('[AuthService] 🔍 isAdmin getter called: $admin (role: $_userRole)');
    return admin;
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      debugPrint('');
      debugPrint('🔐 ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] LOGIN ATTEMPT');
      debugPrint('[AuthService] Email: $email');
      debugPrint('🔐 ══════════════════════════════════════════════════════');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
      
      debugPrint('');
      debugPrint('✅ ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] LOGIN SUCCESSFUL');
      debugPrint('[AuthService] Email: $email');
      debugPrint('[AuthService] User ID: ${_user?.id}');
      debugPrint('[AuthService] User Email: ${_user?.email}');
      debugPrint('[AuthService] Is Anonymous: ${_user?.isAnonymous}');
      debugPrint('✅ ══════════════════════════════════════════════════════');
      debugPrint('');
      
      // Fetch role from Supabase users table
      if (_user != null) {
        await _fetchUserRole(_user!.id);
      }
      
      debugPrint('');
      debugPrint('🎯 ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] LOGIN COMPLETE');
      debugPrint('[AuthService] Final User Role: $_userRole');
      debugPrint('[AuthService] Is Admin: ${_userRole == 'admin'}');
      debugPrint('[AuthService] Is Signed In: $_user != null = ${_user != null}');
      debugPrint('🎯 ══════════════════════════════════════════════════════');
      debugPrint('');
      
      notifyListeners();
    } on AuthException catch (e) {
      debugPrint('');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] SUPABASE AUTH ERROR');
      debugPrint('[AuthService] Error Message: ${e.message}');
      debugPrint('[AuthService] Error Code: ${e.statusCode}');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('');
      rethrow;
    } on FormatException catch (e) {
      debugPrint('');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] FORMAT ERROR (possibly network issue)');
      debugPrint('[AuthService] Error: $e');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('');
      throw AuthException('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } catch (e) {
      debugPrint('');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] UNEXPECTED ERROR DURING SIGN IN');
      debugPrint('[AuthService] Error: $e');
      debugPrint('[AuthService] Error Type: ${e.runtimeType}');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('');
      
      // Check if it's a network-related error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection')) {
        throw AuthException('Tidak ada koneksi internet. Periksa jaringan Anda.');
      }
      
      throw AuthException('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  // Helper method to fetch user role from Supabase users table
  Future<void> _fetchUserRole(String uid) async {
    try {
      debugPrint('');
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('[AuthService] 🔍 FETCHING USER ROLE');
      debugPrint('[AuthService] UID: $uid');
      debugPrint('[AuthService] UID Type: ${uid.runtimeType}');
      debugPrint('[AuthService] UID Length: ${uid.length}');
      debugPrint('[AuthService] Query: SELECT role FROM users WHERE id = \'$uid\'');
      debugPrint('════════════════════════════════════════════════════════');

      // 0) Try to read role from JWT first (app_metadata/user_metadata) to avoid DB hit when possible
      try {
        final appMeta = _user?.appMetadata ?? const <String, dynamic>{};
        final userMeta = _user?.userMetadata ?? const <String, dynamic>{};
        final jwtRole = (appMeta['role'] ?? userMeta['role'])?.toString();
        if (jwtRole != null && jwtRole.isNotEmpty) {
          debugPrint('[AuthService] Found role in JWT metadata: $jwtRole');
          _userRole = jwtRole;
          return;
        }
      } catch (_) {
        // Ignore metadata parsing issues and fall through to DB lookup
      }
      
    // 1) Try direct query to users table (RLS must allow reading own row)
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      
      debugPrint('');
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('[AuthService] 📦 QUERY RESPONSE');
      debugPrint('[AuthService] Response: $response');
      debugPrint('[AuthService] Response Type: ${response.runtimeType}');
      debugPrint('[AuthService] Is Null: ${response == null}');
      
      // 2) Try alternative query with explicit UUID cast
      if (response == null) {
        debugPrint('');
        debugPrint('[AuthService] ⚠️ First query returned null, trying with explicit cast...');
        final altResponse = await _supabase
            .from('users')
            .select('*')
            .eq('id', uid)
            .limit(1)
            .maybeSingle();
        debugPrint('[AuthService] Alternative query response: $altResponse');
      }
      
      debugPrint('════════════════════════════════════════════════════════');
      
      if (response != null) {
        final roleFromDb = response['role'];
        debugPrint('');
        debugPrint('════════════════════════════════════════════════════════');
        debugPrint('[AuthService] ✅ USER FOUND IN DATABASE');
        debugPrint('[AuthService] Role from DB: $roleFromDb');
        debugPrint('[AuthService] Role Type: ${roleFromDb.runtimeType}');
        _userRole = roleFromDb ?? 'user';
        debugPrint('[AuthService] Final Role Set: $_userRole');
        debugPrint('════════════════════════════════════════════════════════');
        debugPrint('');
      } else {
        debugPrint('');
        debugPrint('════════════════════════════════════════════════════════');
        debugPrint('[AuthService] ⚠️ USER NOT FOUND IN USERS TABLE');
        debugPrint('[AuthService] Setting default role: user');
        debugPrint('[AuthService] ⚠️ ACTION REQUIRED:');
        debugPrint('[AuthService] 1. Check if UID exists in Supabase users table');
        debugPrint('[AuthService] 2. Run: SELECT * FROM users WHERE id = \'$uid\'::UUID');
        debugPrint('[AuthService] 3. If no results, INSERT the user manually');
        debugPrint('════════════════════════════════════════════════════════');
        debugPrint('');
        _userRole = 'user';
      }
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('[AuthService] ❌ ERROR FETCHING ROLE');
      debugPrint('[AuthService] Error: $e');
      debugPrint('[AuthService] Error Type: ${e.runtimeType}');
      debugPrint('[AuthService] Stack Trace:');
      debugPrint(stackTrace.toString());
      debugPrint('[AuthService] Setting default role: user');
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('');
      _userRole = 'user';
    }
  }

  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      _user = response.user;
      
      // Insert user into users table with default 'user' role
      if (_user != null) {
        await _supabase.from('users').insert({
          'id': _user!.id,
          'email': email,
          'role': 'user',
          'created_at': DateTime.now().toIso8601String(),
        });
        _userRole = 'user';
      }
      
      notifyListeners();
    } on AuthException {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException {
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    try {
      debugPrint('');
      debugPrint('👤 ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] GUEST LOGIN ATTEMPT');
      debugPrint('👤 ══════════════════════════════════════════════════════');
      
      final response = await _supabase.auth.signInAnonymously();
      _user = response.user;
      _userRole = 'guest';
      
      debugPrint('');
      debugPrint('✅ ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] GUEST LOGIN SUCCESSFUL');
      debugPrint('[AuthService] User ID: ${_user?.id}');
      debugPrint('[AuthService] Role: $_userRole');
      debugPrint('✅ ══════════════════════════════════════════════════════');
      debugPrint('');
      
      notifyListeners();
    } on AuthException catch (e) {
      debugPrint('');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] GUEST LOGIN ERROR');
      debugPrint('[AuthService] Error: ${e.message}');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('');
      rethrow;
    } on FormatException catch (e) {
      debugPrint('');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] FORMAT ERROR (network issue)');
      debugPrint('[AuthService] Error: $e');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('');
      throw AuthException('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } catch (e) {
      debugPrint('');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('[AuthService] UNEXPECTED GUEST LOGIN ERROR');
      debugPrint('[AuthService] Error: $e');
      debugPrint('❌ ══════════════════════════════════════════════════════');
      debugPrint('');
      
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection')) {
        throw AuthException('Tidak ada koneksi internet. Periksa jaringan Anda.');
      }
      
      throw AuthException('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  Future<void> signOut() async {
    debugPrint('');
    debugPrint('🚪 ══════════════════════════════════════════════════════');
    debugPrint('[AuthService] LOGOUT');
    debugPrint('[AuthService] Previous User: ${_user?.email ?? 'Guest'}');
    debugPrint('[AuthService] Previous Role: $_userRole');
    debugPrint('🚪 ══════════════════════════════════════════════════════');
    debugPrint('');
    
    await _supabase.auth.signOut();
    _user = null;
    _userRole = null;
    
    debugPrint('✅ Logout successful - returning to Login Screen');
    debugPrint('');
    
    notifyListeners();
  }
}
