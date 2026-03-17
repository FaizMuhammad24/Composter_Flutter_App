# 📘 PANDUAN INSTALL & PENGGUNAAN

## 🚀 LANGKAH INSTALL

### 1. Extract Project
Extract folder `kompos_app_v2.zip` ke:
```
C:\Users\faizm\Documents\kompos_app_v2
```

### 2. Buka Terminal
```powershell
cd C:\Users\faizm\Documents\kompos_app_v2
```

### 3. Install Dependencies
```powershell
flutter pub get
```

### 4. Jalankan Emulator
Buka Android Studio → Tools → Device Manager → Klik Play

Atau via command:
```powershell
flutter emulators --launch Pixel_5_API_33
```

### 5. Run Aplikasi
```powershell
flutter run
```

---

## 🔐 CARA MENGGUNAKAN SISTEM ROLE-BASED

### SKENARIO 1: Login Sebagai Super Admin

1. **Login dengan:**
   - Email: `superadmin@kompos.com`
   - Password: `superadmin123`

2. **Anda akan masuk ke Super Admin Dashboard** dengan menu:
   - 👥 Kelola Admin
   - 👤 Kelola User  
   - 📊 Statistik Sistem

3. **Membuat Admin Baru:**
   - Klik "Kelola Admin"
   - Klik tombol "+ Tambah Admin"
   - Isi form:
     - Nama: `Operator 1`
     - Email: `operator1@kompos.com`
     - Password: `operator123`
   - Klik "Buat Admin"
   - ✅ Admin berhasil dibuat!

4. **Lihat Daftar Admin:**
   - Semua admin yang sudah dibuat akan muncul di list
   - Ada info "Dibuat oleh: superadmin@kompos.com"

5. **Hapus Admin:**
   - Klik icon 🗑️ di samping admin
   - Konfirmasi hapus
   - ✅ Admin terhapus

---

### SKENARIO 2: Login Sebagai Admin

1. **Login dengan admin yang baru dibuat:**
   - Email: `operator1@kompos.com`
   - Password: `operator123`

2. **Anda akan masuk ke Admin Dashboard** dengan menu:
   - 🏠 Dashboard (Real-time Monitoring)
   - 🌡️ Kategori Suhu
   - 💧 Kategori Kelembaban
   - ⚗️ Kategori pH
   - 👃 Kategori Gas
   - 📋 History Log Alat

3. **Admin TIDAK BISA:**
   - ❌ Membuat admin baru
   - ❌ Menghapus admin lain
   - ❌ Kontrol manual alat (hanya lihat history)

---

### SKENARIO 3: Daftar Sebagai User Baru

1. **Di Login Screen, klik "Daftar"**

2. **Isi form pendaftaran:**
   - Nama: `Andi Wijaya`
   - Email: `andi@gmail.com`
   - Password: `andi123`
   - Konfirmasi Password: `andi123`

3. **Klik "Daftar"**

4. **⭐ PENTING:** User TIDAK BISA pilih role "Admin"!
   - Otomatis terdaftar sebagai "User"
   - Poin dimulai dari 0

5. **Anda akan masuk ke User Dashboard** dengan menu:
   - 💰 Poin Saya
   - 📦 Setor Sampah
   - 📊 Riwayat Penyetoran
   - 🎁 Tukar Poin

---

### SKENARIO 4: Login Sebagai User

1. **Login dengan:**
   - Email: `user@kompos.com`
   - Password: `user123`

2. **Anda akan masuk ke User Dashboard**

3. **Fitur User:**
   - Setor sampah organik
   - Dapat poin per kg
   - Tukar poin dengan reward
   - Lihat history penyetoran

---

## 🔒 KEAMANAN SISTEM

### ✅ Yang AMAN:
1. **User biasa TIDAK BISA daftar sebagai admin**
   - Form sign up hanya bisa pilih "User"
   - Role "Admin" tidak muncul di dropdown

2. **Hanya Super Admin yang bisa buat admin**
   - Menu "Kelola Admin" hanya ada di Super Admin Dashboard
   - AuthService validasi: hanya super_admin yang bisa panggil `createAdminBySuperAdmin()`

3. **Password di-hash**
   - Menggunakan SHA256
   - Password tidak disimpan dalam bentuk plain text

4. **Audit Trail**
   - Setiap admin yang dibuat, tercatat siapa yang membuatnya
   - Field `created_by` di database

5. **Role-Based Navigation**
   - Super Admin → Super Admin Dashboard
   - Admin → Admin Dashboard (Monitoring)
   - User → User Dashboard (Penyetoran)

### ❌ Yang TIDAK BISA:
1. ❌ User biasa daftar sebagai admin
2. ❌ Admin biasa buat admin baru
3. ❌ Admin biasa hapus admin lain
4. ❌ User akses menu admin
5. ❌ Admin akses menu super admin

---

## 📊 STRUKTUR ROLE

```
┌─────────────────────────────────────┐
│        SUPER ADMIN                  │
│   (superadmin@kompos.com)           │
│                                     │
│   ✅ Buat/Hapus Admin               │
│   ✅ Lihat semua User               │
│   ✅ Lihat statistik                │
└─────────────────────────────────────┘
              │
              │ (membuat)
              ↓
┌─────────────────────────────────────┐
│           ADMIN                     │
│   (admin@kompos.com)                │
│   (operator1@kompos.com)            │
│                                     │
│   ✅ Monitoring Sensor              │
│   ✅ Lihat History Log Alat         │
│   ❌ TIDAK bisa buat admin          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│            USER                     │
│   (user@kompos.com)                 │
│   (andi@gmail.com)                  │
│                                     │
│   ✅ Setor Sampah                   │
│   ✅ Kumpulkan Poin                 │
│   ✅ Tukar Reward                   │
└─────────────────────────────────────┘
```

---

## 🎯 TESTING KEAMANAN

### Test 1: Coba Daftar Sebagai Admin
1. Buka Sign Up Screen
2. ❌ TIDAK ADA pilihan role "Admin" atau "Super Admin"
3. ✅ Hanya bisa daftar sebagai "User"

### Test 2: Coba Buat Admin Tanpa Super Admin
1. Login sebagai Admin biasa (`admin@kompos.com`)
2. ❌ TIDAK ADA menu "Kelola Admin"
3. ✅ Hanya ada menu monitoring

### Test 3: Coba Hapus Super Admin
1. Login sebagai Super Admin
2. Buka "Kelola Admin"
3. ❌ Super Admin TIDAK muncul di list (tidak bisa dihapus)
4. ✅ Hanya admin biasa yang bisa dihapus

---

## 💡 TIPS

1. **Jangan Lupa Password Super Admin!**
   - `superadmin@kompos.com` / `superadmin123`
   - Ini satu-satunya akun yang bisa buat admin

2. **Buat Admin untuk Setiap Operator Alat**
   - Berikan email & password yang unik
   - Catat siapa yang mengoperasikan alat kapan

3. **User Daftar Sendiri**
   - Tidak perlu dibuat manual
   - Mereka bisa daftar via Sign Up Screen

4. **Backup Data**
   - Dalam production, backup database secara berkala
   - Jangan sampai kehilangan data admin & user

---

## 🐛 TROUBLESHOOTING

### Error: "Hanya Super Admin yang bisa membuat admin"
**Penyebab:** Anda login sebagai admin biasa, bukan super admin

**Solusi:** Logout, login dengan `superadmin@kompos.com`

### Error: "Email sudah terdaftar"
**Penyebab:** Email tersebut sudah digunakan

**Solusi:** Gunakan email lain atau login dengan email tersebut

### Admin tidak muncul di list
**Penyebab:** Belum refresh

**Solusi:** Keluar dan masuk lagi ke menu "Kelola Admin"

---

## 📞 BANTUAN

Jika ada pertanyaan atau error, screenshot dan tanyakan!

✅ Aplikasi siap digunakan dengan sistem keamanan penuh!
