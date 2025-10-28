# Error Handling Documentation

## 📋 Overview

Aplikasi ini sudah dilengkapi dengan comprehensive error handling untuk berbagai kondisi error yang mungkin terjadi, dengan pesan user-friendly dalam Bahasa Indonesia.

---

## 🔐 **Login Errors**

### **1. Email atau Password Salah**
**Error dari Supabase:**
- `Invalid login credentials`
- `Invalid email or password`

**Pesan ke User:**
```
Email atau password salah.
```

**Penyebab:**
- Email tidak terdaftar di database
- Password tidak cocok dengan yang tersimpan

**Solusi:**
- Periksa kembali email dan password
- Gunakan fitur "Forgot password?" jika lupa password

---

### **2. Tidak Ada Koneksi Internet**
**Error dari System:**
- `SocketException`
- `Failed host lookup`
- `Network request failed`
- `Connection timeout`
- `Failed to fetch`

**Pesan ke User:**
```
Tidak ada koneksi internet. Periksa jaringan Anda.
```

**Penyebab:**
- WiFi/Data seluler tidak aktif
- Signal lemah
- Server Supabase tidak dapat dijangkau
- Firewall memblokir koneksi

**Solusi:**
- Aktifkan WiFi atau data seluler
- Pindah ke area dengan signal lebih baik
- Coba lagi setelah beberapa saat

---

### **3. Email Belum Diverifikasi**
**Error dari Supabase:**
- `Email not confirmed`

**Pesan ke User:**
```
Email belum diverifikasi. Cek inbox Anda.
```

**Penyebab:**
- User mendaftar tapi belum klik link verifikasi di email

**Solusi:**
- Cek inbox email (termasuk folder spam)
- Klik link verifikasi dari Supabase
- Request email verifikasi ulang jika perlu

---

### **4. Format Email Tidak Valid**
**Error dari Supabase:**
- `Invalid email`

**Pesan ke User:**
```
Format email tidak valid.
```

**Penyebab:**
- Email tidak memiliki format yang benar (contoh: `user@example.com`)

**Solusi:**
- Periksa penulisan email
- Pastikan ada `@` dan domain yang valid

---

### **5. Terlalu Banyak Percobaan Login**
**Error dari Supabase:**
- `Too many requests`
- `Rate limit exceeded`

**Pesan ke User:**
```
Terlalu banyak percobaan. Tunggu beberapa menit.
```

**Penyebab:**
- User mencoba login berkali-kali dalam waktu singkat
- Rate limiting dari Supabase Auth

**Solusi:**
- Tunggu 5-10 menit
- Coba login lagi dengan credentials yang benar

---

### **6. Akun Dinonaktifkan**
**Error dari Supabase:**
- `User disabled`
- `User banned`

**Pesan ke User:**
```
Akun dinonaktifkan. Hubungi administrator.
```

**Penyebab:**
- Admin menonaktifkan akun user
- Akun di-ban karena pelanggaran

**Solusi:**
- Hubungi administrator aplikasi
- Minta penjelasan kenapa akun dinonaktifkan

---

### **7. Server Error**
**Error dari Supabase:**
- `Database error`
- `Server error`
- `Internal server error`

**Pesan ke User:**
```
Server sedang bermasalah. Coba lagi nanti.
```

**Penyebab:**
- Supabase server down
- Database maintenance
- Bug di server-side

**Solusi:**
- Tunggu beberapa menit/jam
- Coba lagi nanti
- Laporkan ke developer jika berlanjut

---

## 👤 **Guest Login Errors**

### **1. Guest Login Disabled**
**Error dari Supabase:**
- `Anonymous sign-in is disabled`

**Pesan ke User:**
```
Login sebagai Guest tidak diaktifkan. Gunakan email/password.
```

**Penyebab:**
- Anonymous Auth belum dienable di Supabase Dashboard

**Solusi untuk Developer:**
1. Buka Supabase Dashboard
2. Authentication → Providers
3. Enable "Anonymous Users"

**Solusi untuk User:**
- Login menggunakan email dan password
- Buat akun baru jika belum punya

---

### **2. Network Error (Guest)**
**Pesan ke User:**
```
Tidak ada koneksi internet. Periksa jaringan Anda.
```

**Solusi:** Sama seperti network error di login biasa

---

## 🔑 **Password Reset Errors**

### **1. Email Tidak Ditemukan**
**Error dari Supabase:**
- `User not found`

**Pesan ke User:**
```
Akun tidak ditemukan. Periksa email Anda.
```

**Penyebab:**
- Email yang dimasukkan tidak terdaftar

**Solusi:**
- Periksa kembali penulisan email
- Gunakan email yang benar saat mendaftar

---

### **2. Network Error (Reset)**
**Pesan ke User:**
```
Gagal mengirim email. Periksa koneksi internet.
```

**Solusi:**
- Pastikan koneksi internet aktif
- Coba lagi setelah beberapa saat

---

### **3. Reset Success**
**Pesan ke User (Success):**
```
Instruksi reset dikirim ke email
```

**Next Steps:**
- Cek inbox email (termasuk spam)
- Klik link reset password
- Buat password baru

---

## ⚠️ **Validation Errors**

### **1. Email Kosong**
**Pesan ke User:**
```
Masukkan email
```

**Trigger:** User submit form tanpa mengisi email

---

### **2. Password Kosong**
**Pesan ke User:**
```
Masukkan password
```

**Trigger:** User submit form tanpa mengisi password

---

### **3. Password Terlalu Pendek**
**Pesan ke User:**
```
Password minimal 6 karakter
```

**Trigger:** User memasukkan password < 6 karakter

---

## 🛠️ **Developer Guide: Menambah Error Handling Baru**

### **Di `login_screen.dart`:**

Tambahkan kondisi baru di method `_getErrorMessage()`:

```dart
String _getErrorMessage(AuthException e) {
  final message = e.message.toLowerCase();
  
  // Tambahkan kondisi baru disini
  if (message.contains('kata_kunci_error')) {
    return 'Pesan user-friendly dalam Bahasa Indonesia';
  }
  
  // ... existing conditions ...
  
  return e.message; // fallback
}
```

### **Di `auth_service.dart`:**

Tambahkan catch block untuk error type baru:

```dart
try {
  // ... authentication code ...
} on AuthException catch (e) {
  rethrow;
} on NewErrorType catch (e) {
  throw AuthException('Custom message');
} catch (e) {
  // Generic handler
}
```

---

## 📊 **Error Handling Flow**

```
User Action (Login/Guest/Reset)
         ↓
Try authentication
         ↓
    ┌────────────────┐
    │  Success?      │
    └────────────────┘
      ↓           ↓
     YES          NO
      ↓           ↓
  Navigate     Catch Error
  to Main       ↓
  Menu     Check Error Type
              ↓
         AuthException? → _getErrorMessage()
              ↓
         Network Error? → "Tidak ada koneksi internet"
              ↓
         Other Error? → "Terjadi kesalahan"
              ↓
         Show Error to User
              ↓
         User can retry
```

---

## 🧪 **Testing Error Scenarios**

### **Test 1: Wrong Password**
1. Email: `admin@bps.co.id`
2. Password: `wrongpass`
3. **Expected:** "Email atau password salah."

### **Test 2: No Internet**
1. Matikan WiFi dan data seluler
2. Coba login
3. **Expected:** "Tidak ada koneksi internet. Periksa jaringan Anda."

### **Test 3: Invalid Email**
1. Email: `notanemail`
2. Password: `anything`
3. **Expected:** "Format email tidak valid."

### **Test 4: Empty Fields**
1. Email: (kosong)
2. Password: (kosong)
3. **Expected:** "Masukkan email"

### **Test 5: Short Password**
1. Email: `test@example.com`
2. Password: `123`
3. **Expected:** "Password minimal 6 karakter"

### **Test 6: Guest Login**
1. Klik "Masuk sebagai Guest"
2. **Expected:** Berhasil atau error sesuai konfigurasi

### **Test 7: Forgot Password**
1. Email: `admin@bps.co.id`
2. Klik "Forgot password?"
3. **Expected:** "Instruksi reset dikirim ke email"

---

## 🎯 **Best Practices**

### ✅ **DO:**
- Gunakan pesan error yang jelas dan spesifik
- Berikan solusi atau next steps ke user
- Log error detail di console untuk debugging
- Catch specific error types sebelum generic catch
- Validasi input di client-side sebelum kirim ke server

### ❌ **DON'T:**
- Jangan tampilkan error message teknis ke user (contoh: `SocketException`)
- Jangan hardcode pesan error di banyak tempat (gunakan helper function)
- Jangan ignore error tanpa handling
- Jangan block UI tanpa feedback saat error
- Jangan expose sensitive info di error message

---

## 📝 **Error Messages Reference**

| Error Type | User Message (ID) | Technical Cause |
|------------|-------------------|-----------------|
| Invalid credentials | Email atau password salah | Wrong email/password |
| Network error | Tidak ada koneksi internet | SocketException, timeout |
| Email not confirmed | Email belum diverifikasi | Unconfirmed signup |
| Invalid email format | Format email tidak valid | Malformed email |
| Too many requests | Terlalu banyak percobaan | Rate limit exceeded |
| User disabled | Akun dinonaktifkan | Admin disabled account |
| Server error | Server sedang bermasalah | Database/server issue |
| Anonymous disabled | Login Guest tidak diaktifkan | Anonymous auth disabled |
| Empty email | Masukkan email | Client validation |
| Empty password | Masukkan password | Client validation |
| Short password | Password minimal 6 karakter | Client validation |
| Reset success | Instruksi reset dikirim ke email | Success case |
| Reset failed | Gagal mengirim email | Network issue |

---

## 🔄 **Future Improvements**

### **Planned Features:**
- [ ] Retry mechanism dengan exponential backoff
- [ ] Offline mode dengan queue
- [ ] Error analytics/logging ke server
- [ ] Custom error dialog dengan action buttons
- [ ] Localization support (EN/ID)
- [ ] Biometric authentication error handling
- [ ] Session timeout handling
- [ ] Network status indicator

---

**Last Updated:** 2024  
**Maintained By:** Development Team
