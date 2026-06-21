/*
 * ====================================================================
 *  I-COMPOST — Program Pengujian Relay 4-Channel
 *  Target Board: ESP32-S3 N16R8
 *  Deskripsi   : Menguji 4 relay (aktif LOW) secara berurutan dan bersamaan.
 * ====================================================================
 */

// Definisi Pin Aktuator (Berdasarkan esp32_icompost.ino)
#define HEATER_PIN      15  // Relay Channel 1 - Heater
#define FAN_PIN         6   // Relay Channel 2 - Exhaust Fan
#define WATER_PUMP_PIN  7   // Relay Channel 3 - Pompa Molase (P1)
#define EM4_PUMP_PIN    16  // Relay Channel 4 - Pompa EM4 (P2)

// Konfigurasi Logic Relay 4-Channel (Aktif LOW)
#define RELAY_ON   LOW
#define RELAY_OFF  HIGH

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=========================================");
  Serial.println("  PENGUJIAN RELAY 4-CHANNEL (AKTIF LOW)  ");
  Serial.println("=========================================");
  Serial.println("Pin yang diuji:");
  Serial.println("- CH1 (Heater)   : GPIO 15");
  Serial.println("- CH2 (Fan)      : GPIO 6");
  Serial.println("- CH3 (Pompa P1) : GPIO 7");
  Serial.println("- CH4 (Pompa P2) : GPIO 16");
  Serial.println("-----------------------------------------");

  // Inisialisasi awal ke keadaan OFF (HIGH) untuk menghindari lonjakan
  digitalWrite(HEATER_PIN,     RELAY_OFF);
  digitalWrite(FAN_PIN,        RELAY_OFF);
  digitalWrite(WATER_PUMP_PIN, RELAY_OFF);
  digitalWrite(EM4_PUMP_PIN,   RELAY_OFF);

  // Set pin sebagai OUTPUT
  pinMode(HEATER_PIN,     OUTPUT);
  pinMode(FAN_PIN,        OUTPUT);
  pinMode(WATER_PUMP_PIN, OUTPUT);
  pinMode(EM4_PUMP_PIN,   OUTPUT);

  Serial.println("Setup Selesai. Pengujian dimulai...\n");
  delay(2000);
}

void loop() {
  // --- Uji Channel 1 (Heater) ---
  Serial.println("[TEST] Channel 1: Heater (GPIO 15) -> ON");
  digitalWrite(HEATER_PIN, RELAY_ON);
  delay(2000);
  Serial.println("[TEST] Channel 1: Heater (GPIO 15) -> OFF");
  digitalWrite(HEATER_PIN, RELAY_OFF);
  delay(1000);

  // --- Uji Channel 2 (Exhaust Fan) ---
  Serial.println("[TEST] Channel 2: Fan (GPIO 6) -> ON");
  digitalWrite(FAN_PIN, RELAY_ON);
  delay(2000);
  Serial.println("[TEST] Channel 2: Fan (GPIO 6) -> OFF");
  digitalWrite(FAN_PIN, RELAY_OFF);
  delay(1000);

  // --- Uji Channel 3 (Pompa Molase) ---
  Serial.println("[TEST] Channel 3: Pompa P1 (GPIO 7) -> ON");
  digitalWrite(WATER_PUMP_PIN, RELAY_ON);
  delay(2000);
  Serial.println("[TEST] Channel 3: Pompa P1 (GPIO 7) -> OFF");
  digitalWrite(WATER_PUMP_PIN, RELAY_OFF);
  delay(1000);

  // --- Uji Channel 4 (Pompa EM4) ---
  Serial.println("[TEST] Channel 4: Pompa P2 (GPIO 16) -> ON");
  digitalWrite(EM4_PUMP_PIN, RELAY_ON);
  delay(2000);
  Serial.println("[TEST] Channel 4: Pompa P2 (GPIO 16) -> OFF");
  digitalWrite(EM4_PUMP_PIN, RELAY_OFF);
  delay(1000);

  // --- Uji Semua Channel Bersamaan ---
  Serial.println("[TEST] Semua Channel -> ON");
  digitalWrite(HEATER_PIN,     RELAY_ON);
  digitalWrite(FAN_PIN,        RELAY_ON);
  digitalWrite(WATER_PUMP_PIN, RELAY_ON);
  digitalWrite(EM4_PUMP_PIN,   RELAY_ON);
  delay(3000);

  Serial.println("[TEST] Semua Channel -> OFF");
  digitalWrite(HEATER_PIN,     RELAY_OFF);
  digitalWrite(FAN_PIN,        RELAY_OFF);
  digitalWrite(WATER_PUMP_PIN, RELAY_OFF);
  digitalWrite(EM4_PUMP_PIN,   RELAY_OFF);
  Serial.println("-----------------------------------------\n");
  delay(3000);
}
