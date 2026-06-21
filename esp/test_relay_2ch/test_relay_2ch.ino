/*
 * ====================================================================
 *  I-COMPOST — Program Pengujian Relay 2-Channel
 *  Target Board: ESP32-S3 N16R8
 *  Deskripsi   : Menguji 2 relay (aktif HIGH) secara berurutan dan bersamaan.
 * ====================================================================
 */

// Definisi Pin Aktuator (Berdasarkan esp32_icompost.ino)
#define MOTOR_PIN       38  // Relay Channel 1 - Motor Pengaduk
#define SPARE_PIN       39  // Relay Channel 2 - Cadangan (Tidak Terpakai di Firmware Utama)

// Konfigurasi Logic Relay 2-Channel (Aktif HIGH)
#define RELAY_ON   HIGH
#define RELAY_OFF  LOW

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=========================================");
  Serial.println("  PENGUJIAN RELAY 2-CHANNEL (AKTIF HIGH) ");
  Serial.println("=========================================");
  Serial.println("Pin yang diuji:");
  Serial.println("- CH1 (Motor)    : GPIO 38");
  Serial.println("- CH2 (Cadangan) : GPIO 39");
  Serial.println("-----------------------------------------");

  // Inisialisasi awal ke keadaan OFF (LOW) untuk menghindari lonjakan
  digitalWrite(MOTOR_PIN, RELAY_OFF);
  digitalWrite(SPARE_PIN, RELAY_OFF);

  // Set pin sebagai OUTPUT
  pinMode(MOTOR_PIN, OUTPUT);
  pinMode(SPARE_PIN, OUTPUT);

  Serial.println("Setup Selesai. Pengujian dimulai...\n");
  delay(2000);
}

void loop() {
  // --- Uji Channel 1 (Motor Pengaduk) ---
  Serial.println("[TEST] Channel 1: Motor (GPIO 38) -> ON");
  digitalWrite(MOTOR_PIN, RELAY_ON);
  delay(2000);
  Serial.println("[TEST] Channel 1: Motor (GPIO 38) -> OFF");
  digitalWrite(MOTOR_PIN, RELAY_OFF);
  delay(1000);

  // --- Uji Channel 2 (Cadangan) ---
  Serial.println("[TEST] Channel 2: Cadangan (GPIO 39) -> ON");
  digitalWrite(SPARE_PIN, RELAY_ON);
  delay(2000);
  Serial.println("[TEST] Channel 2: Cadangan (GPIO 39) -> OFF");
  digitalWrite(SPARE_PIN, RELAY_OFF);
  delay(1000);

  // --- Uji Kedua Channel Bersamaan ---
  Serial.println("[TEST] Kedua Channel -> ON");
  digitalWrite(MOTOR_PIN, RELAY_ON);
  digitalWrite(SPARE_PIN, RELAY_ON);
  delay(3000);

  Serial.println("[TEST] Kedua Channel -> OFF");
  digitalWrite(MOTOR_PIN, RELAY_OFF);
  digitalWrite(SPARE_PIN, RELAY_OFF);
  Serial.println("-----------------------------------------\n");
  delay(3000);
}
