# 📦 I-Compost v2.0 — Dokumentasi Proyek

> **Aplikasi Flutter** untuk monitoring dan manajemen sistem kompos pintar berbasis IoT (ESP32 + Firebase).  
> Dibangun sebagai bagian dari Tugas Akhir.

---

## 📋 Daftar Isi

1. [Gambaran Umum](#gambaran-umum)
2. [Tech Stack](#tech-stack)
3. [Struktur Direktori](#struktur-direktori)
4. [Arsitektur & Alur Data](#arsitektur--alur-data)
5. [Role & Hak Akses](#role--hak-akses)
6. [Panduan Screens](#panduan-screens)
7. [Services & Logika Bisnis](#services--logika-bisnis)
8. [Models](#models)
9. [Widgets](#widgets)
10. [Constants & Utils](#constants--utils)
11. [Assets](#assets)
12. [Firebase & Database Schema](#firebase--database-schema)
13. [Environment & Konfigurasi](#environment--konfigurasi)
14. [Status Bug & TODO](#status-bug--todo)
15. [Panduan Pengembangan](#panduan-pengembangan)

---

## Gambaran Umum

I-Compost adalah aplikasi mobile Flutter yang menghubungkan **pengguna akhir**, **operator admin**, dan **super admin** dalam satu ekosistem pengelolaan kompos pintar. Sistem ini terintegrasi dengan perangkat keras ESP32 yang memantau kondisi komposter secara real-time.

### Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| **Monitoring Real-time** | Data sensor (suhu, kelembaban, pH, gas) distream langsung dari ESP32 via Firebase RTDB |
| **Sistem Poin** | User mendapat poin tiap setoran sampah yang diapprove admin |
| **Tukar Reward** | User bisa tukar poin dengan reward (voucher, produk, merchandise) |
| **Notifikasi Multi-layer** | Local push notification + Firestore stream per role |
| **QoS Monitoring** | Admin bisa lihat delay, packet loss, uptime ESP32 |
| **Offline Detection** | Otomatis detect ESP32 offline dengan toleransi 60 detik |

---

## Tech Stack

### Framework & Language
- **Flutter** — Cross-platform mobile framework
- **Dart** — Bahasa pemrograman

### Backend & Database
| Layanan | Fungsi |
|---------|--------|
| **Firebase Auth** | Autentikasi user (email/password + Google Sign-In) |
| **Cloud Firestore** | Database utama (profil user, setoran, reward, notifikasi) |
| **Firebase Realtime Database** | Data sensor ESP32 real-time |

### Storage & Media
- **Cloudinary** — Upload foto setoran sampah user (`cloud_name: dwnym5d5h`)

### Package Penting
```yaml
firebase_core: ^3.x
firebase_auth: ^5.x
cloud_firestore: ^5.x
firebase_database: ^11.x
flutter_local_notifications: ^18.x  # Push notification lokal
fl_chart: ^0.x                       # Grafik sensor
share_plus: ^10.x                    # Export CSV
google_sign_in: ^6.x                 # Google login
shared_preferences: ^2.x             # Simpan sesi lokal
intl: ^0.x                           # Format tanggal/angka
image_picker: ^1.x                   # Ambil foto kamera/galeri
http: ^1.x                           # Upload ke Cloudinary
```

---

## Struktur Direktori

```
kompos_app_v2/
├── android/                        # Konfigurasi Android native
├── ios/                            # Konfigurasi iOS native
├── assets/
│   ├── fonts/                      # Font Poppins (18 varian)
│   └── images/
│       ├── logo.png                # Logo aplikasi
│       └── reward_placeholder.png  # Placeholder gambar reward
├── lib/
│   ├── main.dart                   # Entry point, setup Firebase & tema
│   ├── firebase_options.dart       # Konfigurasi Firebase (auto-generated)
│   ├── constants/                  # Design tokens global
│   │   ├── app_colors.dart         # Palet warna per role & status
│   │   ├── app_spacing.dart        # Sistem spacing konsisten
│   │   └── app_text_styles.dart    # Sistem tipografi
│   ├── models/                     # Data models (plain Dart classes)
│   │   ├── user_model.dart
│   │   ├── sensor_data_model.dart
│   │   ├── compost_model.dart
│   │   ├── reward_model.dart
│   │   ├── actuator_log_model.dart
│   │   ├── alert_model.dart
│   │   └── app_notification_model.dart
│   ├── services/                   # Logika bisnis & akses data
│   │   ├── admin/
│   │   │   └── admin_service.dart          # CRUD admin (pakai secondary Firebase app)
│   │   ├── auth/
│   │   │   ├── auth_service.dart           # Logout & cek status auth
│   │   │   ├── login_service.dart          # Login email/password
│   │   │   ├── signup_service.dart         # Registrasi user baru
│   │   │   ├── session_service.dart        # Simpan/baca sesi ke SharedPreferences
│   │   │   ├── google_sign_in_service.dart # Google OAuth
│   │   │   └── password_service.dart       # Reset password via email
│   │   ├── compost/
│   │   │   └── compost_service.dart        # CRUD data setoran kompos
│   │   ├── history/
│   │   │   └── history_service.dart        # Query histori setoran per user / global
│   │   ├── notifications/
│   │   │   ├── admin_notification_service.dart       # Monitor sensor RTDB, alert, local push
│   │   │   ├── user_notification_service.dart        # Monitor notifikasi Firestore untuk user
│   │   │   ├── super_admin_notification_service.dart # Notifikasi khusus super admin
│   │   │   └── app_notification_service.dart         # Helper kirim notifikasi ke Firestore
│   │   ├── rewards/
│   │   │   └── reward_service.dart         # CRUD reward, klaim, approve, populer
│   │   ├── user/
│   │   │   ├── user_service.dart           # CRUD profil user
│   │   │   └── points_service.dart         # Tambah/kurang poin user
│   │   └── database/
│   │       └── storage_service.dart        # Upload gambar ke Cloudinary
│   ├── screens/                    # UI per fitur
│   │   ├── authentication/
│   │   │   ├── splash_screen.dart          # Cek sesi & routing awal
│   │   │   ├── login_screen.dart           # Form login + Google Sign-In
│   │   │   ├── signup_screen.dart          # Form registrasi user
│   │   │   └── reset_password_screen.dart  # Form reset password
│   │   ├── admin/
│   │   │   ├── admin_main_screen.dart          # Scaffold utama admin (IndexedStack)
│   │   │   ├── dashboard/
│   │   │   │   └── admin_dashboard.dart             # Dashboard monitoring sensor
│   │   │   ├── system/
│   │   │   │   ├── admin_system_status_screen.dart  # Status ESP32, QoS, uptime
│   │   │   │   ├── admin_history_log_screen.dart    # Log aktivitas aktuator
│   │   │   │   ├── admin_sensor_history_screen.dart # Rekap data QoS (1 menit)
│   │   │   │   ├── admin_category_temperature_screen.dart  # Detail grafik suhu
│   │   │   │   ├── admin_category_humidity_screen.dart     # Detail grafik kelembaban
│   │   │   │   ├── admin_category_ph_screen.dart           # Detail grafik pH
│   │   │   │   └── admin_category_gas_screen.dart          # Detail grafik gas
│   │   │   ├── compost/
│   │   │   │   └── admin_compost_status_screen.dart # Halaman pantau kompos dan maturity
│   │   │   ├── profile/
│   │   │   │   └── admin_profile_screen.dart        # Profil admin & logout
│   │   │   ├── notifications/
│   │   │   │   └── admin_system_notifications_screen.dart  # Notifikasi sensor & alert
│   │   │   └── widgets/
│   │   │       ├── admin_header.dart            # AppBar admin dengan badge notifikasi
│   │   │       ├── admin_bottom_nav.dart         # Bottom navigation bar admin
│   │   │       ├── sensor_calibration_card.dart  # Widget kalibrasi sensor
│   │   │       └── sensor_history_toggle.dart    # Toggle tampilan histori sensor
│   │   ├── super_admin/
│   │   │   ├── super_admin_main_screen.dart         # Scaffold utama super admin
│   │   │   ├── super_admin_dashboard.dart            # Dashboard statistik global
│   │   │   ├── super_admin_management_screen.dart    # Halaman manajemen (placeholder/router)
│   │   │   ├── super_admin_manage_admins_screen.dart # CRUD admin
│   │   │   ├── super_admin_manage_users_screen.dart  # Lihat & kelola user
│   │   │   ├── super_admin_manage_deposits_screen.dart  # Approve/reject setoran
│   │   │   ├── super_admin_manage_rewards_screen.dart   # Kelola katalog reward
│   │   │   ├── super_admin_create_reward_screen.dart    # Form buat reward baru
│   │   │   ├── super_admin_reward_claims_screen.dart    # Approve/reject klaim reward
│   │   │   ├── super_admin_notifications_screen.dart    # Pusat notifikasi super admin
│   │   │   ├── super_admin_profile_screen.dart          # Profil super admin & logout
│   │   │   └── widgets/
│   │   │       ├── super_admin_header.dart       # AppBar super admin
│   │   │       └── super_admin_bottom_nav.dart   # Bottom navigation super admin
│   │   └── user/
│   │       ├── user_main_screen.dart          # Scaffold utama user (IndexedStack)
│   │       ├── user_dashboard.dart             # Dashboard poin & quick action
│   │       ├── user_deposit_screen.dart        # Form setor sampah + upload foto
│   │       ├── user_deposit_history_screen.dart # Riwayat setoran
│   │       ├── user_history_screen.dart         # Histori lengkap (setoran & klaim)
│   │       ├── user_rewards_screen.dart         # Katalog reward
│   │       ├── user_redeem_screen.dart          # Form tukar poin (klaim reward)
│   │       ├── user_notifications_screen.dart   # Notifikasi personal user
│   │       ├── user_profile_screen.dart         # Profil & edit data user
│   │       └── widgets/
│   │           ├── user_header.dart             # AppBar user dengan badge notifikasi
│   │           └── user_bottom_nav.dart          # Bottom navigation user
│   ├── widgets/                    # Reusable widgets (lintas role)
│   │   ├── cards/
│   │   │   ├── sensor_card.dart        # Card monitoring sensor (suhu/lembab/pH/gas)
│   │   │   ├── deposit_card.dart       # Card item riwayat setoran
│   │   │   ├── reward_card.dart        # Card item reward di katalog
│   │   │   ├── alert_card.dart         # Card notifikasi/alert sensor
│   │   │   ├── stats_card.dart         # Card statistik angka
│   │   │   └── custom_card.dart        # Base card dengan shadow default
│   │   ├── buttons/
│   │   │   └── custom_button.dart      # Tombol utama dengan style konsisten
│   │   ├── common/
│   │   │   ├── loading_shimmer.dart        # Skeleton loading placeholder
│   │   │   ├── custom_loading_indicator.dart # CircularProgressIndicator berbranding
│   │   │   ├── custom_empty_state.dart      # UI state kosong (no data)
│   │   │   └── log_item_widget.dart         # Item list untuk log aktuator
│   │   └── inputs/
│   │       └── custom_text_field.dart   # TextField dengan style konsisten
│   └── utils/
│       ├── helpers/
│       │   ├── date_formatter.dart     # Format tanggal, waktu, relative time
│       │   ├── screen_utils.dart       # Responsive helper (mobile/tablet/desktop)
│       │   ├── validators.dart         # Validasi form (email, password, berat, dll)
│       │   └── csv_export_helper.dart  # Export data ke CSV via SharePlus
│       └── styles/
│           ├── app_elevation.dart      # Konstanta elevation (shadow depth)
│           └── app_radius.dart         # Konstanta & objek BorderRadius
├── pubspec.yaml                    # Dependensi & konfigurasi Flutter
├── pubspec.lock                    # Lock file dependensi (jangan edit manual)
├── analysis_options.yaml           # Konfigurasi Dart Analyzer (linter)
├── firebase.json                   # Konfigurasi Firebase CLI
├── flutter_launcher_icons.yaml     # Konfigurasi ikon launcher
├── devtools_options.yaml           # Konfigurasi Flutter DevTools
├── .gitignore
└── PROJECT_DOCS.md                 # ← File ini
```

---

## Arsitektur & Alur Data

### Diagram Alur Utama

```
ESP32 (Hardware)
    │ kirim data tiap ~5 detik
    ▼
Firebase Realtime Database ('komposter' node)
    │ stream onValue
    ▼
AdminNotificationService (singleton, init di admin_main_screen)
    ├─► ValueNotifier<bool> deviceOfflineNotifier   → UI admin bereaksi
    ├─► ValueNotifier<List<LocalAlert>> alertsNotifier → badge notifikasi
    └─► FlutterLocalNotifications                   → push notification

Cloud Firestore
    ├── /users/{uid}         → profil user, poin, role
    ├── /composts/{id}       → data setoran sampah
    ├── /rewards/{id}        → katalog reward
    ├── /reward_claims/{id}  → klaim reward user
    └── /notifications/{id}  → notifikasi per user
```

### Pola State Management

Aplikasi ini **tidak menggunakan** package state management eksternal (Bloc/Provider/Riverpod). Sebagai gantinya:

| Pola | Digunakan untuk |
|------|-----------------|
| `ValueNotifier` + `ValueListenableBuilder` | State real-time sensor & alert (AdminNotificationService) |
| `setState` | State lokal per screen |
| `SessionService` + `SharedPreferences` | Persistensi data login antar sesi |
| `StreamBuilder` | Firestore stream untuk notifikasi user |

### Pola Secondary Firebase App

`AdminService` membuat instance Firebase kedua (`SecondaryApp`) untuk keperluan CRUD akun admin oleh Super Admin, agar Super Admin tidak ikut ter-logout saat membuat akun admin baru:

```dart
// lib/services/admin/admin_service.dart
final app = await Firebase.initializeApp(
  name: 'SecondaryApp',
  options: Firebase.app().options,
);
final tempAuth = FirebaseAuth.instanceFor(app: app);
```

---

## Role & Hak Akses

| Aspek | User | Admin | Super Admin |
|-------|------|-------|-------------|
| **Warna Tema** | Hijau (`#2D5016`) | Kuning/Amber (`#FBC02D`) | Merah (`#D32F2F`) |
| **Entry Screen** | `UserMainScreen` | `AdminMainScreen` | `SuperAdminMainScreen` |
| **Cek di** | `splash_screen.dart` via `SessionService.getRole()` | sama | sama |
| **Verifikasi Email** | **Wajib** (diblokir jika belum) | Tidak dicek | Tidak dicek |
| **Setor Sampah** | ✅ | ❌ | ❌ |
| **Monitoring Sensor** | ❌ | ✅ | ❌ |
| **Approve Setoran** | ❌ | ✅ | ✅ |
| **Kelola Reward** | ❌ | ❌ | ✅ |
| **Kelola Admin** | ❌ | ❌ | ✅ |
| **Broadcast Notifikasi** | ❌ | ❌ | ✅ |

---

## Panduan Screens

### Authentication

| File | Fungsi |
|------|--------|
| `splash_screen.dart` | Cek `SessionService`, routing ke dashboard sesuai role atau ke login |
| `login_screen.dart` | Form login (email+password & Google), validasi email terverifikasi |
| `signup_screen.dart` | Registrasi user baru, otomatis kirim email verifikasi |
| `reset_password_screen.dart` | Kirim link reset password via `password_service.dart` |

### Admin Screens (4 Tab via `IndexedStack`)

| Tab | File | Konten |
|-----|------|--------|
| 0 - Dashboard | `admin_dashboard.dart` | Hero card, grid 4 sensor, histori aktuator horizontal |
| 1 - Status Kompos | `admin_compost_status_screen.dart` | List setoran user, tombol approve/reject |
| 2 - Status Sistem | `admin_system_status_screen.dart` | Health ESP32, QoS, uptime, WiFi strength |
| 3 - Profil | `admin_profile_screen.dart` | Info profil, tombol logout |

**Screen tambahan Admin (navigasi push):**
- `admin_category_*.dart` — Grafik detail per sensor (fl_chart)
- `admin_history_log_screen.dart` — Log ON/OFF aktuator
- `admin_sensor_history_screen.dart` — Rekap QoS 1 menit
- `admin_notifications_screen.dart` — List alert dengan filter & swipe-to-delete

### Super Admin Screens (5 Tab)

| Tab | File | Konten |
|-----|------|--------|
| 0 - Dashboard | `super_admin_dashboard.dart` | Statistik global, recent activity |
| 1 - Manajemen | `super_admin_management_screen.dart` | Router ke sub-manajemen |
| 2 - Klaim | `super_admin_reward_claims_screen.dart` | Approve/reject klaim reward |
| 3 - Notifikasi | `super_admin_notifications_screen.dart` | Pusat notifikasi + broadcast |
| 4 - Profil | `super_admin_profile_screen.dart` | Info profil SA, logout |

**Screen tambahan SA (push):**
- `super_admin_manage_admins_screen.dart` — Buat/hapus akun admin
- `super_admin_manage_users_screen.dart` — Lihat list user
- `super_admin_manage_deposits_screen.dart` — Approve/reject setoran (duplikat fungsi admin)
- `super_admin_manage_rewards_screen.dart` — Edit/hapus reward
- `super_admin_create_reward_screen.dart` — Form buat reward baru

### User Screens (4 Tab)

| Tab | File | Konten |
|-----|------|--------|
| 0 - Dashboard | `user_dashboard.dart` | Hero poin, quick action, reward populer, tips |
| 1 - Histori | `user_history_screen.dart` | Tab setoran & klaim reward |
| 2 - Notifikasi | `user_notifications_screen.dart` | Notifikasi personal (stream Firestore) |
| 3 - Profil | `user_profile_screen.dart` | Edit profil, ganti foto, logout |

**Screen tambahan User (push):**
- `user_deposit_screen.dart` — Form setor: pilih jenis sampah, berat, foto (Cloudinary)
- `user_deposit_history_screen.dart` — Riwayat setoran dengan status pending/approved/rejected
- `user_rewards_screen.dart` — Katalog reward dengan filter kategori
- `user_redeem_screen.dart` — Form klaim reward, cek poin, konfirmasi

---

## Services & Logika Bisnis

### Auth Services

| File | Fungsi Utama |
|------|-------------|
| `login_service.dart` | `loginWithEmail()` — validasi email terverifikasi untuk role 'user' |
| `signup_service.dart` | `registerUser()` — buat akun Firebase Auth + dokumen Firestore |
| `session_service.dart` | `saveSession()` / `getRole()` / `clearSession()` — SharedPreferences |
| `google_sign_in_service.dart` | `signInWithGoogle()` — OAuth, auto-buat profil jika baru |
| `password_service.dart` | `sendPasswordResetEmail()` |
| `auth_service.dart` | `logout()` — Firebase signOut + session clear |

### Notification Services

| File | Tanggung Jawab |
|------|----------------|
| `admin_notification_service.dart` | **Inti:** Stream RTDB, cek ambang batas sensor, local push notification, `ValueNotifier` untuk offline & alert |
| `user_notification_service.dart` | Stream koleksi `/notifications` Firestore, badge counter |
| `super_admin_notification_service.dart` | Stream notifikasi SA dari Firestore, kirim notifikasi |
| `app_notification_service.dart` | Helper untuk simpan notifikasi ke Firestore (`/notifications` collection) |

### Business Logic Services

| File | Fungsi Utama |
|------|-------------|
| `compost_service.dart` | `addCompost()`, `getAllComposts()`, `updateCompostStatus()` |
| `history_service.dart` | `getUserHistory()`, `getAllHistory()`, `getRecentTransactions()` |
| `reward_service.dart` | `getPopularRewards()`, `claimReward()`, `approveClaim()`, `rejectClaim()` |
| `points_service.dart` | `addPoints()`, `deductUserPoints()` — dijalankan setelah admin approve |
| `user_service.dart` | `getUserByEmail()`, `getAllUsers()`, `updateUser()` |
| `admin_service.dart` | `createAdmin()` (pakai Secondary App), `getAllAdmins()`, `deleteAdmin()` |
| `storage_service.dart` | `uploadCompostPhoto()` — multipart upload ke Cloudinary |

---

## Models

| File | Field Utama |
|------|-------------|
| `user_model.dart` | `uid`, `name`, `email`, `role` (user/admin/super_admin), `points`, `photoUrl` |
| `sensor_data_model.dart` | `temperature`, `humidity` (soil), `ph`, `mq4` (gas), status per sensor, helper `isPhHealthy`, `isSoilHealthy` |
| `compost_model.dart` | `id`, `userEmail`, `weight`, `type`, `status` (pending/approved/rejected), `photoUrl`, `createdAt` |
| `reward_model.dart` | `id`, `name`, `category`, `points`, `stock`, `imageUrl`, `claimedCount` |
| `actuator_log_model.dart` | `name`, `status` (ON/OFF), `timestamp`, `triggeredBy` |
| `alert_model.dart` | `id`, `title`, `message`, `severity` (info/warning/danger), `isRead`, `timestamp` |
| `app_notification_model.dart` | `id`, `title`, `body`, `type`, `isRead`, `createdAt` |

---

## Widgets

### Cards (`lib/widgets/cards/`)

| Widget | Dipakai di |
|--------|-----------|
| `SensorCard` | `admin_dashboard.dart` — card monitoring 4 sensor |
| `DepositCard` | Histori setoran user & admin |
| `RewardCard` | Katalog reward user |
| `AlertCard` | Notifikasi admin — dengan swipe-to-delete |
| `StatsCard` | Statistik ringkas (total setoran, poin, dll) |
| `CustomCard` | Base card dengan default shadow & radius |

### Common (`lib/widgets/common/`)

| Widget | Fungsi |
|--------|--------|
| `LoadingShimmer` | Skeleton placeholder saat data loading |
| `SensorCardShimmer` | Shimmer khusus grid sensor |
| `ListItemShimmer` | Shimmer untuk list item |
| `CustomLoadingIndicator` | CircularProgressIndicator berbranding |
| `CustomEmptyState` | UI "tidak ada data" dengan icon & pesan |
| `LogItemWidget` | Item list log aktuator (icon + status + waktu) |

### Buttons & Inputs

| Widget | Fungsi |
|--------|--------|
| `CustomButton` | Tombol utama dengan 3 varian (primary, outline, text) |
| `CustomTextField` | TextField dengan border, label, error state konsisten |

---

## Constants & Utils

### Constants (`lib/constants/`)

```dart
// AppColors — palet warna per role
AppColors.primary          // Hijau tua #2D5016 (user)
AppColors.adminPrimary     // Amber #FBC02D (admin)
AppColors.superAdminPrimary // Merah #D32F2F (super admin)
AppColors.temperature      // Orange #FF6B35
AppColors.humidity         // Biru #2196F3
AppColors.ph               // Ungu #9C27B0
AppColors.gas              // Merah #E53935
AppColors.success / warning / error / info

// AppSpacing — spacing konsisten
AppSpacing.xs = 4   AppSpacing.sm = 8
AppSpacing.md = 16  AppSpacing.lg = 24
AppSpacing.xl = 32  AppSpacing.xxl = 48

// AppTextStyles — tipografi
AppTextStyles.h1 / h2 / h3
AppTextStyles.bodyLarge / bodyMedium / bodySmall
AppTextStyles.button / buttonLarge / buttonMedium / buttonSmall
```

### Utils Helpers (`lib/utils/helpers/`)

```dart
// DateFormatter
DateFormatter.formatDate(dt)            // "24 Mei 2026"
DateFormatter.formatDateTime(dt)        // "24 Mei 2026, 13:30"
DateFormatter.formatRelativeTime(dt)    // "5 menit lalu"
DateFormatter.formatForLog(dt)          // "24 Mei 2026, 13:30:45"

// ScreenUtils
ScreenUtils.isMobile(context)           // < 600px
ScreenUtils.isTablet(context)           // 600-900px
ScreenUtils.getSensorGridCount(context) // 2 (mobile) / 4 (tablet+)
ScreenUtils.horizontalPadding(context)  // 16 / 24 / 32

// Validators (dipakai di form)
Validators.validateEmail(value)
Validators.validatePassword(value)
Validators.validateWeight(value)        // 0.5 - 50 kg
Validators.validatePoints(points, required)

// CsvExportHelper
CsvExportHelper.exportSensorHistory(data)   // Export histori sensor
CsvExportHelper.exportDepositHistory(data)  // Export histori setoran
```

### Utils Styles (`lib/utils/styles/`)

```dart
// AppElevation — shadow depth
AppElevation.sm = 2.0  // Dipakai: DepositCard, AlertCard
AppElevation.md = 4.0  // Dipakai: SensorCard, RewardCard

// AppRadius — border radius
AppRadius.sm = 8    AppRadius.md = 12
AppRadius.lg = 16   AppRadius.xl = 24
AppRadius.borderRadiusMd   // BorderRadius object
AppRadius.shapeMd          // RoundedRectangleBorder object
```

---

## Assets

### Fonts (`assets/fonts/`)
Font **Poppins** — 18 varian (Regular, Bold, SemiBold, Medium, Light, Thin, ExtraBold, Black + masing-masing Italic)

### Images (`assets/images/`)
| File | Fungsi |
|------|--------|
| `logo.png` | Logo aplikasi I-Compost |
| `reward_placeholder.png` | Placeholder gambar reward jika imageUrl kosong |

---

## Firebase & Database Schema

### Cloud Firestore Collections

```
/users/{uid}
  ├── uid: String
  ├── name: String
  ├── email: String
  ├── role: String         // "user" | "admin" | "super_admin"
  ├── points: int          // Poin reward user
  ├── photoUrl: String     // URL foto profil
  └── createdAt: Timestamp

/composts/{id}
  ├── id: String
  ├── userEmail: String
  ├── weight: double       // Berat sampah (kg)
  ├── type: String         // Jenis sampah (organik, dll)
  ├── status: String       // "pending" | "approved" | "rejected"
  ├── photoUrl: String     // URL foto (Cloudinary)
  ├── adminNote: String    // Catatan admin saat approve/reject
  └── createdAt: Timestamp

/rewards/{id}
  ├── id: String
  ├── name: String
  ├── category: String     // "voucher" | "produk" | "merchandise"
  ├── points: int          // Poin yang dibutuhkan
  ├── stock: int
  ├── imageUrl: String
  └── claimedCount: int    // Untuk menentukan "reward populer"

/reward_claims/{id}
  ├── id: String
  ├── userEmail: String
  ├── rewardId: String
  ├── rewardName: String
  ├── status: String       // "pending" | "approved" | "rejected"
  └── createdAt: Timestamp

/notifications/{id}
  ├── id: String
  ├── userEmail: String    // Target penerima
  ├── title: String
  ├── body: String
  ├── type: String         // Jenis notifikasi
  ├── isRead: bool
  └── createdAt: Timestamp
```

### Firebase Realtime Database Schema

```
/komposter
  ├── temperature: double    // Suhu (°C)
  ├── soil: double           // Kelembaban tanah (%)
  ├── ph: double             // Tingkat keasaman
  ├── gas: int               // Konsentrasi gas MQ4 (ppm)
  ├── time: String           // Waktu ESP32 (HH:mm:ss)
  ├── unix_time: int         // Unix timestamp ESP32 (sumber kebenaran offline detection)
  ├── actuators/
  │   ├── fan: bool          // Exhaust Fan
  │   ├── heater: bool       // Heater
  │   ├── motor: bool        // Motor Pengaduk
  │   ├── em4_pump: bool     // Pompa EM4
  │   └── water_pump: bool   // Pompa Air
  └── qos/
      ├── uptime_ms: int     // Uptime ESP32 dalam milidetik
      ├── wifi_strength: int // Kekuatan sinyal WiFi (%)
      ├── free_heap: int     // Free heap memory (bytes)
      └── packet_id: int     // ID paket untuk kalkulasi packet loss
```

> **Catatan Optimasi ESP32:** Firmware ESP32 terbaru telah dioptimalkan untuk menggunakan `Firebase.RTDB.getJSON` (batch reading) pada node `controls` dan `thresholds`. Hal ini dilakukan untuk meminimalisir lag/delay saat membaca data aktuator dari Firebase secara berurutan dalam loop.

---

## Environment & Konfigurasi

### File Konfigurasi Penting

| File | Fungsi | Boleh di-commit? |
|------|--------|-----------------|
| `firebase_options.dart` | API key Firebase (auto-generate via FlutterFire CLI) | ⚠️ Hindari (ada di .gitignore) |
| `pubspec.yaml` | Dependensi & asset declaration | ✅ Ya |
| `analysis_options.yaml` | Linter rules | ✅ Ya |
| `flutter_launcher_icons.yaml` | Konfigurasi app icon | ✅ Ya |

### Storage Service (Cloudinary)
```dart
// lib/services/database/storage_service.dart
static const String _cloudName = 'dwnym5d5h';
static const String _uploadPreset = 'wzrtdwsj';
```
> ⚠️ **Catatan:** Upload preset bersifat publik (unsigned preset). Untuk produksi, pertimbangkan menggunakan signed upload dengan Cloud Functions.

### Offline Detection Logic
- ESP32 mengirim `unix_time` setiap update
- Jika selisih `unix_time` ESP32 vs waktu HP > **60 detik** → data dianggap basi (stale)
- Timer di `AdminSystemStatusScreen` cek interval > **20 detik** sejak update terakhir → trigger offline state
- `AdminNotificationService.deviceOfflineNotifier` di-listen oleh `AdminDashboard`

---

## Status Bug & TODO

### ✅ Selesai
- [x] BuildContext digunakan di luar async gap (BUG-01)
- [x] Offline detection false alarm (BUG-06)
- [x] CSV Export menggunakan API lama (BUG-09)
- [x] Runtime crash manage admins (BUG-10)
- [x] Keunikan ID push notification (BUG-11)
- [x] Manajemen notifikasi (filter, hapus, baca semua) (BUG-12)
- [x] Target stream notifikasi SuperAdmin (BUG-13)
- [x] Ganti `print()` → `debugPrint()` (BUG-14)
- [x] Ganti `withOpacity()` → `.withValues(alpha:)` massal (BUG-15)

### ✅ Optimasi & Perbaikan Terbaru
- [x] **Optimasi ESP32 (Latency):** Pembacaan aktuator dan ambang batas di ESP32 menggunakan `getJSON` (batching) untuk menghilangkan delay respons aktuator.
- [x] **Logic Exhaust Fan:** Fan pada ESP32 otomatis menyala jika suhu **atau** gas melebihi batas maksimal, disertai log Firebase alasan pemicu spesifik (Suhu/Gas/Keduanya).
- [x] **Notifikasi Aktuator:** Admin mendapatkan Push Notification lokal saat aktuator (Motor, Pompa Air, Pompa EM4, Heater, Fan) menyala otomatis atau dikendalikan.
- [x] **Optimistic UI Aktuator:** Menghilangkan delay visual pada tombol aktuator (P1/P2/dll) dengan update state langsung dari *countdown timer* sebelum sinkronisasi Firebase.
- [x] **Format Uptime:** Penambahan format menit pada tampilan Uptime ESP32 di Dashboard Admin.

### 🔄 Dalam Pengerjaan
- [ ] **[BUG-16]** `prefer_const_constructors` — masih ~20 warning tersisa (perlu diperbaiki manual per file)

### 🔴 Belum Dikerjakan (Fase Release)
- [ ] Daftarkan SHA-1 & SHA-256 Google Play Console ke Firebase (Google Sign-In production)
- [ ] Set `minSdkVersion` Android yang sesuai
- [ ] Upload App Icon final ke Play Console
- [ ] Review `applicationId` di `android/app/build.gradle`

---

## Panduan Pengembangan

### Setup Awal
```bash
# Clone & install dependensi
flutter pub get

# Jalankan di emulator/device
flutter run

# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release
```

### Menambah Screen Baru

1. Buat file dart di folder screen yang sesuai (`screens/user/`, `screens/admin/`, dll)
2. Gunakan `AppColors`, `AppSpacing`, dan font `'Poppins'` untuk konsistensi tema
3. Jika screen perlu data dari Firestore, buat atau gunakan service yang sudah ada di `lib/services/`
4. Tambahkan route ke main screen jika perlu (push navigation atau tambah tab)

### Konvensi Kode

| Hal | Konvensi |
|-----|----------|
| **Nama file** | `snake_case.dart` |
| **Nama class** | `PascalCase` |
| **State** | Gunakan `setState` untuk state lokal, `ValueNotifier` untuk state lintas widget |
| **Debug print** | Gunakan `debugPrint()`, **jangan** `print()` |
| **Warna** | Ambil dari `AppColors`, jangan hardcode hex |
| **Spacing** | Gunakan `AppSpacing.md` dll, jangan hardcode angka |
| **Font** | Selalu set `fontFamily: 'Poppins'` di TextStyle |
| **Opacity** | Gunakan `.withValues(alpha: 0.x)`, **jangan** `.withOpacity()` |
| **Async UI** | Selalu cek `if (!mounted) return;` setelah `await` |

### Menambah Dependensi Baru
1. Tambahkan di `pubspec.yaml` bagian `dependencies:`
2. Jalankan `flutter pub get`
3. Import di file yang membutuhkan

### Testing (Manual)
Karena tidak ada automated test, lakukan pengujian manual untuk setiap fitur baru:
- [ ] Login dengan setiap role (user, admin, super_admin)
- [ ] Simulasikan ESP32 offline (matikan device, tunggu 60 detik)
- [ ] Lakukan setor sampah dari akun user hingga approved admin
- [ ] Tukar poin reward hingga proses selesai

---

*Dokumentasi ini dibuat otomatis berdasarkan analisis kode. Selalu update bagian yang berubah saat ada fitur baru.*
