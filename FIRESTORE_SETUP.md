# Firestore Database Setup

## Required Collection Structure

### Collection: `users`

Setiap user yang terdaftar di Firebase Authentication harus memiliki dokumen di Firestore dengan struktur berikut:

```
users/{userId}/
  ├── email: string       // Email user (sama dengan Firebase Auth)
  ├── role: string        // Role user: "admin" atau "user"
  ├── name: string        // (Opsional) Nama lengkap user
  └── createdAt: timestamp // (Opsional) Waktu pembuatan akun
```

## Contoh Data

### Admin User
```json
{
  "email": "admin@bps.co.id",
  "role": "admin",
  "name": "Administrator BPS",
  "createdAt": "2025-10-20T10:00:00Z"
}
```

### Regular User
```json
{
  "email": "user@example.com",
  "role": "user",
  "name": "User Biasa",
  "createdAt": "2025-10-20T10:05:00Z"
}
```

## Cara Setup di Firebase Console

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project Anda
3. Klik **Firestore Database** di menu kiri
4. Klik **Start collection**
5. Collection ID: `users`
6. Document ID: gunakan UID dari Firebase Authentication user
7. Tambahkan field:
   - `email` (string): email user
   - `role` (string): `admin` atau `user`
   - `name` (string): nama user
   - `createdAt` (timestamp): waktu saat ini

## Security Rules (Recommended)

Tambahkan di Firestore Rules untuk keamanan:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users dapat membaca data mereka sendiri
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      // Hanya admin yang dapat menulis/update role
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Cara Menambahkan User Baru

### Opsi 1: Manual via Firebase Console
1. User daftar via aplikasi (Firebase Auth)
2. Setelah berhasil, tambahkan dokumen manual di Firestore dengan UID user tersebut

### Opsi 2: Otomatis via Cloud Function (Recommended)
Buat Cloud Function yang otomatis membuat dokumen Firestore saat user baru daftar:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.createUserDocument = functions.auth.user().onCreate((user) => {
  return admin.firestore().collection('users').doc(user.uid).set({
    email: user.email,
    role: 'user', // default role
    name: user.displayName || '',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
});
```

## Testing

Setelah setup, test dengan:
1. Login dengan akun yang memiliki `role: "admin"` → FAB dan menu admin muncul
2. Login dengan akun yang memiliki `role: "user"` → FAB tersembunyi, ditampilkan sebagai Guest

## Troubleshooting

**Q: User berhasil login tapi selalu dianggap sebagai 'user' bukan 'admin'?**
A: Pastikan:
- Dokumen di Firestore ada dengan UID yang sama dengan Firebase Auth
- Field `role` tertulis `"admin"` (huruf kecil semua, tanpa spasi)
- Firestore Rules mengizinkan read untuk user tersebut

**Q: Error "Failed to fetch user role"?**
A: Periksa:
- Internet connection
- Firestore Rules tidak terlalu restrictive
- Collection `users` sudah dibuat di Firestore
