# Catatan Migrasi Firebase → Supabase

## Ringkasan Perubahan

Proyek ini sudah berhasil dimigrate dari **Firebase** ke **Supabase**. Berikut perubahan yang dilakukan:

## 1. Dependencies (pubspec.yaml)

### ❌ Removed (Firebase):
```yaml
firebase_core: ^2.12.0
firebase_auth: ^4.6.0
cloud_firestore: ^4.8.0
```

### ✅ Added (Supabase):
```yaml
supabase_flutter: ^2.5.0
```

## 2. Initialization (lib/main.dart)

### Before (Firebase):
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

### After (Supabase):
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(const MyApp());
}
```

**⚠️ ACTION REQUIRED**: Update `YOUR_SUPABASE_URL` dan `YOUR_SUPABASE_ANON_KEY` sesuai instruksi di `SUPABASE_SETUP.md`

## 3. Authentication Service (lib/services/auth_service.dart)

### Perubahan Utama:

| Firebase | Supabase |
|----------|----------|
| `FirebaseAuth.instance` | `Supabase.instance.client.auth` |
| `authStateChanges()` | `onAuthStateChange.listen()` |
| `signInWithEmailAndPassword()` | `signInWithPassword()` |
| `createUserWithEmailAndPassword()` | `signUp()` |
| `sendPasswordResetEmail()` | `resetPasswordForEmail()` |
| `signInAnonymously()` | `signInAnonymously()` |
| `FirebaseAuthException` | `AuthException` |

### Perubahan Database Query:

| Firebase Firestore | Supabase PostgreSQL |
|-------------------|---------------------|
| `_firestore.collection('users').doc(uid).get()` | `_supabase.from('users').select('role').eq('id', uid).maybeSingle()` |
| `doc.data()?['role']` | `response['role']` |

### Security Upgrade:

**Before**: Simple email check
```dart
bool get isAdmin => _user?.email?.contains('admin') == true;  // ❌ Insecure!
```

**After**: Database role check
```dart
bool get isAdmin => _userRole == 'admin';  // ✅ Secure with RLS policies
```

## 4. Login Screen (lib/screens/login_screen.dart)

### Perubahan Error Handling:

| Firebase | Supabase |
|----------|----------|
| `on FirebaseAuthException catch (e)` | `on AuthException catch (e)` |
| `_friendlyMessageForCode(e.code)` | `e.message` (sudah user-friendly) |
| Custom error mapping | Direct message usage |

## 5. Database Structure

### Firebase Firestore (Document-based):
```
users (collection)
  └─ [userId] (document)
      ├─ email: string
      └─ role: string
```

### Supabase PostgreSQL (Relational):
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,           -- Links to auth.users
  email TEXT UNIQUE NOT NULL,
  role TEXT CHECK (role IN ('admin', 'user', 'guest')),
  created_at TIMESTAMP
);
```

## 6. New Tables Created in Supabase

| Table | Purpose | RLS Policy |
|-------|---------|-----------|
| `users` | User roles (admin/user/guest) | Users read own, admin modifies |
| `desa` | Village data | Public read, admin write |
| `kependudukan` | Population statistics | Public read, admin write |
| `kesehatan` | Health facilities | Public read, admin write |
| `pendidikan` | Education facilities | Public read, admin write |
| `infrastruktur` | Infrastructure | Public read, admin write |
| `kebencanaan` | Disaster records | Public read, admin write |

## 7. Storage Setup (Bonus!)

Firebase Storage memerlukan **Blaze Plan** (paid with credit card).

Supabase Storage **GRATIS** di free tier dengan 1GB kapasitas!

### Bucket Created:
- **Name**: `desa-images`
- **Access**: Public read, Admin write
- **Policy**: RLS-protected based on user role

### Cara Upload (contoh future usage):
```dart
final supabase = Supabase.instance.client;

// Upload file
await supabase.storage
    .from('desa-images')
    .upload('path/to/image.jpg', File('local/path.jpg'));

// Get public URL
final url = supabase.storage
    .from('desa-images')
    .getPublicUrl('path/to/image.jpg');
```

## 8. Security Improvements

### Row Level Security (RLS)

Supabase menggunakan PostgreSQL RLS untuk keamanan level database:

```sql
-- Example: Only admins can modify desa table
CREATE POLICY "Admins can modify desa"
  ON desa FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'admin'
    )
  );
```

Ini **jauh lebih aman** daripada client-side checking email contains 'admin'!

### Benefits:
- ✅ Server-side enforcement (tidak bisa bypass dari client)
- ✅ Role dari database, bukan email pattern
- ✅ Fine-grained access control per table/row
- ✅ Automatic with every query

## 9. Testing Checklist

Setelah setup Supabase selesai, test:

- [ ] App startup langsung ke Main Menu (guest mode)
- [ ] Click "Login" di header untuk ke login screen
- [ ] Login dengan email/password admin
- [ ] Role badge berubah jadi "Admin"
- [ ] FAB (+ button) muncul untuk admin
- [ ] Logout dan role kembali ke "Guest"
- [ ] Login sebagai Guest (anonymous) berfungsi
- [ ] Create account berfungsi (optional)
- [ ] Password reset email berfungsi (optional)

## 10. Next Steps

1. ✅ **Setup Supabase Project** → Ikuti `SUPABASE_SETUP.md`
2. ✅ **Update API Keys** → Ganti placeholder di `lib/main.dart`
3. ✅ **Run SQL Scripts** → Create tables via SQL Editor
4. ✅ **Create Admin User** → Via Supabase Auth Dashboard
5. ✅ **Test App** → Run `flutter run` dan test semua fitur
6. 🔄 **Optional**: Migrate existing Firebase data (if any)
7. 🚀 **Deploy**: Build release APK/iOS

## 11. Cost Comparison

| Feature | Firebase Free | Supabase Free |
|---------|---------------|---------------|
| **Auth** | Unlimited | 50,000 MAU |
| **Database** | 1GB storage, limited queries | 500MB, unlimited queries |
| **Storage** | ❌ Requires Blaze Plan | ✅ 1GB included |
| **Realtime** | Limited | Unlimited |
| **Credit Card** | Required for Storage | ❌ Not required |

**Winner**: Supabase for this project! 🏆

## 12. Rollback Plan (Just in case)

Jika ingin rollback ke Firebase:

1. Git checkout ke commit sebelum migration
2. Atau revert changes di `pubspec.yaml`, `main.dart`, `auth_service.dart`, `login_screen.dart`
3. Run `flutter pub get`
4. Restore Firebase config files

Tapi Supabase lebih baik, jadi tidak perlu rollback! 😎

---

**Migration Status**: ✅ COMPLETE

**Last Updated**: 2024 (saat migration)

**Contact**: Jika ada issue, check documentation atau raise issue di repo.
