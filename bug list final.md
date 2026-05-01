# 📋 Bug List Final & Rencana Eksekusi — I-Compost v2.0 (Terbaru)

> **Status Saat Ini:** Fase 1 & 2 **SELESAI 100%** ✅ | Fase 3 (Clean Code) belum dikerjakan

Dokumen ini adalah sumber kebenaran tunggal (*single source of truth*) untuk seluruh daftar perbaikan yang harus dilakukan sebelum aplikasi I-Compost v2.0 dirilis ke tahap produksi.

---

## 🟢 FASE 1: KRITIKAL (Potensi Crash & Logic Error) — [SELESAI]
Bug pada kategori ini dapat menyebabkan aplikasi berhenti secara paksa atau mengganggu alur data utama aplikasi. Seluruh poin di bawah ini telah tervalidasi aman.

- [x] **[BUG-01] BuildContext Digunakan di Luar Async Gap**
  - Mengamankan operasi UI lintas jeda asinkron (`await`) dengan `if (!mounted) return;` di `login_screen`, `splash_screen`, riwayat setor, dan layar notifikasi user.
- [x] **[BUG-02] Tanggal Notifikasi Sinkronisasi Ulang Keliru**
  - Mengamankan format *timestamp* saat *device* kembali *online* menggunakan `FieldValue.serverTimestamp()`.
- [x] **[BUG-03] Kesalahan Logika Filter Notifikasi (Missing Braces)**
  - Mengunci logika kondisional tunggal dengan kurung kurawal `{}` pada *super_admin_notifications_screen.dart*.
- [x] **[BUG-10] Runtime Crash pada Layar Manage Admins**
  - Membersihkan *await* yang ilegal pada objek yang bukan bertipe *Future*.
- [x] **[BUG-13] Salah Target Stream Notifikasi SuperAdmin**
  - Memperbaiki `StreamBuilder` agar mengambil stream notifikasi khusus SuperAdmin.

---

## 🟢 FASE 2: UX/Features — [SELESAI]
Bug/Isu pada kategori ini menyangkut pengalaman pengguna (*User Experience*) dan fitur pendukung seperti stabilitas sinkronisasi data eksternal.

- [x] **[BUG-06] Offline Detection Sensitivity**
  - Meningkatkan waktu toleransi status offline alat (ESP32) menjadi **60 detik** demi meredam *false alarm* akibat lag jaringan sementara.
- [x] **[BUG-09] CSV Export Migration**
  - Mengganti fungsi `Share.shareXFiles` (usang) dengan API terbaru `SharePlus.instance.share()` di semua fungsi ekspor data CSV.
- [x] **[BUG-11] Keunikan ID Push Notification**
  - Mengamankan *ID Android Notification* dari potensi saling tiban dengan menggunakan algoritma sisa bagi `microsecondsSinceEpoch.remainder(2147483647)`.
- [x] **[BUG-12] Manajemen Notifikasi SuperAdmin, Admin & User (Hapus, Baca, Filter)**
  - Menambahkan filter (Semua/Belum/Sudah Dibaca), swipe-to-delete per kartu, dan tombol Hapus/Baca Semua di seluruh layar notifikasi User, Admin, dan SuperAdmin.
  - Memperbaiki badge header SuperAdmin agar membaca dari sumber data yang benar (ESP32 + Firestore).

---

## 🔴 FASE 3: CLEAN CODE & SECURITY (Sedang Berjalan)
Pembersihan kode dalam skala besar untuk standar produksi, peningkatan efisiensi render (memori), dan mencegah kebocoran informasi di sistem (Linter menyisakan 166 peringatan yang berpusat di fase ini).

- [ ] **[BUG-14] (BARU) Kebocoran Log di Production (`avoid_print`)**
  - **Detail:** Ada 8 perintah `print()` yang masih tertinggal di `user_dashboard.dart`, `storage_service.dart`, dan `reward_service.dart`.
  - **Tindakan:** Ganti dengan `debugPrint()` agar pesan *debugging* disembunyikan secara otomatis saat aplikasi masuk ke *Google Play Store*.
- [ ] **[BUG-15] Deprecations Massal (`withOpacity`)**
  - **Detail:** Mengganti 130+ peringatan `withOpacity` dengan `withValues(alpha: ...)` untuk mengatasi peringatan kepresisian warna dari Flutter versi terbaru. (Akan dieksekusi instan dengan skrip `fix_lints.py`).
- [ ] **[BUG-16] Pembersihan `const` Constructors**
  - **Detail:** Mengaplikasikan `const` pada *widget* statis yang hilang untuk meningkatkan FPS animasi dan menurunkan beban RAM aplikasi.
- [ ] **[BUG-17] Penyesuaian Material 3 Theme**
  - **Detail:** Menyesuaikan atribut `background` menjadi `surface` di tema utama (`main.dart`).

---

## 🔴 FASE 4: RELEASE
Persiapan *Metadata* & Otentikasi Khusus Produksi (*Google Play Store*).

- [ ] **Konfigurasi Keamanan API Key**
  - Memastikan *SHA-1* dan *SHA-256* milik *App Signing Google Play Console* terdaftar dengan benar di proyek Firebase.
- [ ] **Kepatuhan Metadata Aplikasi**
  - Logo *(App Icon)*, nama *package*, dan batasan versi minimum Android (`minSdkVersion`).
