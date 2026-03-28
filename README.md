# i-Compost
**Smart Composting Monitoring & Automation System**

Sistem monitoring kompos cerdas berbasis IoT (Internet of Things) yang mengintegrasikan perangkat keras (ESP32) dengan aplikasi mobile (Flutter) melalui Firebase Realtime Database untuk proses pengomposan yang efisien dan terukur.

## 🌟 Fitur Utama

### 1. Monitoring Sensor Real-time
Pantau kondisi kompos Anda secara instan dari mana saja:
- **Suhu**: Memastikan suhu dekomposisi tetap dalam rentang optimal.
- **Kelembaban (Soil Moisture)**: Memantau kadar air agar media kompos tidak kering.
- **pH Tanah**: Menjaga tingkat keasaman ideal untuk aktivitas mikroba pengurai.
- **Kadar Gas (MQ-4)**: Deteksi gas metana/biogas untuk keamanan dan indikator kematangan.

### 2. Otomasi Alat (Actuators)
Sistem dilengkapi dengan logika pintar untuk mengontrol 5 komponen secara otomatis:
- **Heater**: Menjaga suhu tetap hangat saat kondisi lingkungan dingin.
- **Exhaust Fan**: Mengatur sirkulasi udara dan membuang gas berlebih.
- **Pompa Air**: Menyiram media secara otomatis jika kelembaban rendah.
- **Pompa EM4**: Injeksi cairan pengurai otomatis saat pH tidak stabil.
- **Motor Aduk**: Pengadukan periodik untuk memastikan aerasi udara merata.

### 3. Logika & Analasis Data
- **Live Actuator Logs**: Catatan real-time setiap kali alat menyala/mati lengkap dengan alasan pemicunya.
- **Histori Sensor (1 Menit)**: Rekap data sensor yang tercatat secara periodik.
- **Export Data CSV**: Memungkinkan Admin mengunduh data riwayat sensor ke format file Excel/CSV.

### 4. Manajemen Pengguna (Role-Based)
- **Super Admin**: Mengelola seluruh akun Admin, User, serta sistem penukaran Reward.
- **Admin**: Fokus pada monitoring sistem, grafik sensor, dan kesehatan perangkat.
- **User**: Berpartisipasi dalam penyetoran sampah untuk mendapatkan poin dan reward.

### 5. Stabilitas & Kesehatan Sistem
- **Offline Detection**: Notifikasi push instan jika perangkat ESP32 terputus atau online kembali.
- **Health System Monitoring**: Memantau sisa memori (Free Heap) dan stabilitas WiFi pada perangkat keras.
- **Monitoring QoS**: Visualisasi latensi (delay), packet loss, dan throughput data secara real-time.

---

### 🎓 Tim Pengembang
- **Muhammad Ilham Ananta**
- **Tubagus Muhammad Rofi Al Faiz**

> **Telkom B 23 — Teknik Elektro**  
> **Politeknik Negeri Jakarta**  
> *Didedikasikan untuk Solusi Monitoring Kompos Berbasis IoT bagi Masyarakat.*

---

### 💖 Ucapan Terima Kasih (Shout Out)
Ucapan terima kasih yang tulus kami sampaikan kepada:
- **Arthur Damara Gultom**: Kuli pangkul favorit kami.
- **Mang Awai**: Mekanik konstruksi alat.
- **Dosen-Dosen Teknik Elektro PNJ**: Atas bimbingan dan seluruh ilmunya.
- **Keluarga Tercinta**: Dukungan dan doa yang tidak pernah putus.
- **Teman-Teman**: Rekan seperjuangan Telkom B 23.

---
**© 2026 i-Composter Project. All rights reserved.**  
*Dari Telkom B untuk Masyarakat.*

