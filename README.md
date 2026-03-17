# Aplikasi Monitoring Kompos v2.0
## Sistem Role-Based dengan Super Admin Security

### 🔐 SISTEM KEAMANAN

#### 3 Level Role:
1. **Super Admin** - Bisa membuat/hapus admin & user
2. **Admin** - Monitoring sensor & alat (Read-only)
3. **User** - Penyetoran sampah & poin

#### Keamanan Admin:
- ✅ User biasa TIDAK BISA daftar sebagai admin
- ✅ Hanya Super Admin yang bisa buat akun admin
- ✅ Password di-hash dengan SHA256
- ✅ Audit trail (siapa yang membuat admin)

### 📱 AKUN DEMO

```
Super Admin:
Email: superadmin@kompos.com
Password: superadmin123

Admin:
Email: admin@kompos.com
Password: admin123

User:
Email: user@kompos.com
Password: user123
```

### 🚀 CARA INSTALL

1. Extract folder `kompos_app_v2`
2. Buka terminal di folder tersebut
3. Jalankan:
```bash
flutter pub get
flutter run
```

### 📂 STRUKTUR PROJECT

```
lib/
├── main.dart
├── models/
│   └── user_model.dart
├── services/
│   └── auth_service.dart
└── screens/
    ├── splash_screen.dart
    ├── login_screen.dart
    ├── signup_screen.dart        # Hanya bisa daftar sebagai User
    ├── super_admin_dashboard.dart # Kelola admin & user
    ├── admin_dashboard.dart       # Monitoring sensor
    └── user_dashboard.dart        # Setor sampah & poin
```

### 🎯 FITUR SUPER ADMIN

- Kelola Admin (Tambah/Hapus)
- Kelola User (Lihat/Hapus)
- Lihat statistik sistem
- Audit trail

### 🎯 FITUR ADMIN

- Dashboard monitoring real-time
- Kategori Suhu
- Kategori Kelembaban  
- Kategori pH
- Kategori Gas (MQ-4)
- History Log ON/OFF alat
- Notifikasi alert

### 🎯 FITUR USER

- Lihat poin saya
- Setor sampah organik
- Riwayat penyetoran
- Tukar poin dengan reward

### 🔧 DEPENDENCIES

```yaml
dependencies:
  flutter_sdk
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  fl_chart: ^0.68.0
  crypto (untuk hash password)
```

### ⚡ QUICK START

```bash
cd kompos_app_v2
flutter pub get
flutter run
```

Login sebagai Super Admin untuk membuat admin baru!
