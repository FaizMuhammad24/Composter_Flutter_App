/*
 * =============================================================
 *  I-COMPOST — Firmware ESP32 30-PIN (DevKit V1 / classic)
 *  Versi  : 2.6.0-ESP32
 *  Tanggal: Agustus 2026
 * =============================================================
 *
 *  PERUBAHAN DARI VERSI 2.5.1:
 *  - WiFi Dual SSID: 4G-UFI-F6F (3 menit), fallback Samsung
 *  - Firebase: icompost-db, tanpa api_key (Legacy Token only)
 *  - Firebase failure recovery (reinit setelah 5x gagal)
 *  - SSL buffer optimasi (rx=4096, tx=512)
 *  - MQ-135: R0=375 kΩ (kalibrasi diagnostik), VCC=5V, formula standar
 *  - Soil: DRY=3300, WET=1000 (kalibrasi diagnostik)
 *  - LCD 6 screen dengan custom character, motor punya screen sendiri
 *  - Warning buzzer terintegrasi ke rotasi LCD
 *  - WiFi reconnect dengan SSID bergantian
 */

#include <DallasTemperature.h>
#include <Firebase_ESP_Client.h>
#include <LiquidCrystal_I2C.h>
#include <OneWire.h>
#include <RTClib.h>
#include <WiFi.h>
#include <Wire.h>
#include <addons/RTDBHelper.h>
#include <addons/TokenHelper.h>
#include <time.h>

// ============================================================
//  KONFIGURASI WIFI — DUAL SSID (Fallback)
//  Urutan: SSID1 (3 menit) → SSID2 (1 menit)
// ============================================================
#define WIFI_SSID1     "4G-UFI-F6F"
#define WIFI_PASSWORD1 "telkomb23"
#define WIFI_SSID2     "Samsung"
#define WIFI_PASSWORD2 "dodolipet2505"

// ============================================================
//  KONFIGURASI FIREBASE — icompost-db
//  PENTING: Jangan set api_key saat menggunakan Legacy Token.
//  Kombinasi keduanya menyebabkan konflik autentikasi.
// ============================================================
#define DATABASE_URL    "https://icompost-db-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define DATABASE_SECRET "0elSe0OFDDQ1ypcthT7wOrqkjq252Kv5uOKUSIgm"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ============================================================
//  PIN DEFINITIONS — ESP32 30-PIN (classic)
// ============================================================
#define SOIL_PIN        34
#define MQ135_AOUT_PIN  35
#define ONE_WIRE_BUS    4
#define SDA_PIN         21
#define SCL_PIN         22

#define HEATER_PIN      27
#define FAN_PIN         26
#define P1_PIN          25
#define P2_PIN          33
#define MOTOR_PIN       32
#define BUZZER_PIN      19

// Relay logic (active LOW — sesuai modul relay)
#define RELAY4_ON  LOW
#define RELAY4_OFF HIGH
#define RELAY2_ON  HIGH
#define RELAY2_OFF LOW

// ============================================================
//  OBJEK SENSOR
// ============================================================
LiquidCrystal_I2C lcd(0x27, 16, 2);
RTC_DS3231 rtc;
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// ============================================================
//  QoS TIPHON VARIABLES
// ============================================================
float qosLastDelayMs = 0.0f;
float qosLastThroughputBps = 0.0f;
float qosLastJitterMs = 0.0f;
unsigned long qosTotalSent = 0;
unsigned long qosTotalFailed = 0;

// ── Firebase failure recovery ──────────────────────────────
int fbFailCount = 0;          // consecutive upload failures
const int FB_FAIL_REINIT = 5; // reinit Firebase after N failures

// ============================================================
//  KALIBRASI SENSOR — DATA TERBARU (dari Diagnostic Tool)
// ============================================================
#define MQ135_RL_VALUE  10.0f
#define MQ135_R0        375.0f   // hasil kalibrasi R0 udara bersih (kΩ) — diagnostik: 350-400
#define MQ135_VCC       5.0f     // Tegangan VCC sensor MQ-135 (5.0V)
#define ESP32_VREF      3.3f     // Referensi ADC ESP32 (3.3V)
#define MQ135_ADC_MAX   4095.0f
#define MQ135_SAMPLES   10

#define TEMP_OFFSET     0.0f
#define TEMP_RESOLUTION 12

#define SOIL_SAMPLES    20
#define SOIL_DRY_ADC    3300     // Nilai ADC saat kering (di udara) — kalibrasi diagnostik
#define SOIL_WET_ADC    1000     // Nilai ADC saat basah (di air) — kalibrasi diagnostik

// ============================================================
//  THRESHOLDS (default — akan di-override dari Firebase)
// ============================================================
float tempThresholdMin = 28.0f;
float tempThresholdMax = 33.0f;
float gasThresholdMax  = 200.0f;  // disesuaikan: clean air ~117 ppm dengan R0=375
float soilThresholdMin = 25.0f;
float soilThresholdMax = 85.0f;

// ============================================================
//  STATUS AKTUATOR & KONTROL
// ============================================================
bool heaterStatus = false;
bool fanStatus    = false;
bool p1Status     = false;
bool p2Status     = false;
bool motorStatus  = false;

bool prevHeater = false, prevFan = false;
bool prevP1 = false, prevP2 = false;
bool prevMotor = false;

bool gasHigh  = false;
bool tempHigh = false;

// Pompa P1 & P2
bool pumpP1Active = false;
unsigned long pumpP1StartMs = 0;
unsigned long pumpP1Duration = 30000UL;
bool pump1CmdProcessed = false;

bool pumpP2Active = false;
unsigned long pumpP2StartMs = 0;
unsigned long pumpP2Duration = 20000UL;
bool pump2CmdProcessed = false;

// Motor
bool motorEnabled = false;
String motorScheduleHours = "";
int motorDurationMin = 20;
bool motorSessionActive = false;
unsigned long motorSessionStart = 0;
int motorLastRunHour = -1;
int motorLastRunMinute = -1;
int motorLastRunDay = -1;

// ============================================================
//  LCD & TIMING
// ============================================================
unsigned long lastLCDUpdate = 0;
int lcdScreen = 0;
const unsigned long LCD_INTERVAL = 3500UL; // Rotasi layar tiap 3.5 detik

unsigned long lastFirebaseSync = 0;
unsigned long lastControlRead  = 0;
unsigned long lastDataUpload   = 0;
unsigned long lastHistoryPush  = 0;
unsigned long packetId = 0;

bool motorBuzzActive = false;
int motorBuzzCount = 0;
unsigned long lastBuzzTime = 0;

// ============================================================
//  KARAKTER KUSTOM LCD (5x8 Icons)
// ============================================================
byte blockChar[8] = {B11111, B11111, B11111, B11111,
                     B11111, B11111, B11111, B11111};
byte charTemp[8]  = {B00100, B01010, B01010, B01110,
                     B01110, B11111, B11111, B01110}; // 0: Thermometer
byte charGas[8]   = {B00100, B01010, B00100, B01110,
                     B10001, B10101, B10001, B01110}; // 1: Gas Cloud
byte charSoil[8]  = {B00100, B00100, B01010, B01010,
                     B10001, B10001, B10001, B01110}; // 2: Droplet / Soil
byte charMotor[8] = {B00000, B01010, B01110, B11111,
                     B01110, B01010, B00000, B00000}; // 3: Motor Gear
byte charFan[8]   = {B00000, B11011, B11011, B00100,
                     B11011, B11011, B00000, B00000}; // 4: Fan Wind
byte charPump[8]  = {B01110, B01010, B11111, B10001,
                     B10101, B10001, B11111, B00000}; // 5: Pump Liquid
byte charAlert[8] = {B00100, B01110, B01110, B01110,
                     B00100, B00000, B00100, B00000}; // 6: Alert !
byte charCheck[8] = {B00000, B00001, B00011, B10110,
                     B11100, B01000, B00000, B00000}; // 7: Checkmark OK

// ============================================================
//  HELPER: LCD Print Center
// ============================================================
void lcdPrintCenter(int row, const char *str) {
  int len = strlen(str);
  int spaces = (16 - len) / 2;
  if (spaces < 0) spaces = 0;
  lcd.setCursor(0, row);
  lcd.print("                ");
  lcd.setCursor(spaces, row);
  lcd.print(str);
}

// ============================================================
//  WIFI — DUAL SSID (SSID1 3 menit, SSID2 1 menit)
// ============================================================
void initWiFi() {
  // ── Coba SSID1 dulu (3 menit) ──────────────────────────
  Serial.println("[WiFi] Mencoba " + String(WIFI_SSID1) + " (timeout 3 menit)...");
  WiFi.begin(WIFI_SSID1, WIFI_PASSWORD1);
  unsigned long wifiStartMs = millis();
  const unsigned long WIFI_TIMEOUT1 = 180000UL; // 3 menit
  int attempt = 0;

  while (WiFi.status() != WL_CONNECTED) {
    unsigned long elapsed = millis() - wifiStartMs;
    if (elapsed >= WIFI_TIMEOUT1) break;

    int remaining = (WIFI_TIMEOUT1 - elapsed) / 1000;
    char buf[17];
    snprintf(buf, sizeof(buf), "4G-UFI %3ds", remaining);

    lcd.clear();
    lcdPrintCenter(0, "Koneksi WiFi");
    lcdPrintCenter(1, buf);

    attempt++;
    if (attempt % 3 == 0) {
      digitalWrite(BUZZER_PIN, HIGH);
      delay(50);
      digitalWrite(BUZZER_PIN, LOW);
    }
    delay(5000);

    if (WiFi.status() != WL_CONNECTED) {
      WiFi.disconnect();
      delay(200);
      WiFi.begin(WIFI_SSID1, WIFI_PASSWORD1);
    }
  }

  // ── Jika SSID1 gagal, coba SSID2 (1 menit) ───────────
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[WiFi] " + String(WIFI_SSID1) + " gagal. Mencoba " + String(WIFI_SSID2) + "...");
    WiFi.disconnect();
    delay(200);
    WiFi.begin(WIFI_SSID2, WIFI_PASSWORD2);
    wifiStartMs = millis();
    const unsigned long WIFI_TIMEOUT2 = 60000UL; // 1 menit

    while (WiFi.status() != WL_CONNECTED) {
      unsigned long elapsed = millis() - wifiStartMs;
      if (elapsed >= WIFI_TIMEOUT2) break;

      int remaining = (WIFI_TIMEOUT2 - elapsed) / 1000;
      char buf[17];
      snprintf(buf, sizeof(buf), "Samsung %3ds", remaining);

      lcd.clear();
      lcdPrintCenter(0, "Koneksi WiFi");
      lcdPrintCenter(1, buf);

      delay(5000);

      if (WiFi.status() != WL_CONNECTED) {
        WiFi.disconnect();
        delay(200);
        WiFi.begin(WIFI_SSID2, WIFI_PASSWORD2);
      }
    }
  }

  // ── Hasil ──────────────────────────────────────────────
  if (WiFi.status() == WL_CONNECTED) {
    lcd.clear();
    lcdPrintCenter(0, "WiFi Terhubung!");
    lcdPrintCenter(1, WiFi.localIP().toString().c_str());
    Serial.println("[WiFi] Terhubung! IP: " + WiFi.localIP().toString());
    delay(1500);
  } else {
    lcd.clear();
    lcdPrintCenter(0, "! WIFI GAGAL !");
    lcdPrintCenter(1, "Lanjut offline");
    Serial.println("[WiFi] Semua SSID gagal. Lanjut offline.");
    delay(2000);
  }
}

// ============================================================
//  FIREBASE INIT (Legacy Token, tanpa api_key)
// ============================================================
void initFirebase() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[FB] WiFi tidak tersambung — Firebase dilewati.");
    return;
  }

  // PENTING: Jangan set api_key saat menggunakan Legacy Token.
  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;

  // Batasi buffer SSL agar tidak habiskan heap & tidak hang.
  fbdo.setBSSLBufferSize(4096, 512);
  fbdo.setResponseSize(4096);

  Firebase.reconnectWiFi(true);
  Firebase.begin(&config, &auth);

  lcd.clear();
  lcdPrintCenter(0, "Firebase...");
  Serial.print("[FB] Menunggu Firebase ready");

  unsigned long fbStart = millis();
  while (!Firebase.ready() && (millis() - fbStart < 10000UL)) {
    Serial.print(".");
    delay(300);
    yield();
  }
  Serial.println();

  if (Firebase.ready()) {
    lcdPrintCenter(1, "Terhubung!");
    Serial.println("[FB] Firebase READY — Legacy Token aktif.");
    fbFailCount = 0;
  } else {
    lcdPrintCenter(1, "Gagal!");
    Serial.println("[FB] Firebase GAGAL — cek DATABASE_SECRET dan DATABASE_URL.");
  }
  delay(1000);
}

// ============================================================
//  FIREBASE RE-INIT (dipanggil saat gagal 5x berturut-turut)
// ============================================================
void reinitFirebase() {
  Serial.println("[FB] Reinit Firebase karena gagal " + String(FB_FAIL_REINIT) +
                 "x berturut-turut...");
  lcd.clear();
  lcdPrintCenter(0, "FB Reconnect...");

  Firebase.reset(&config);
  delay(500);
  yield();

  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;
  fbdo.setBSSLBufferSize(4096, 512);
  fbdo.setResponseSize(4096);
  Firebase.reconnectWiFi(true);
  Firebase.begin(&config, &auth);

  unsigned long fbStart = millis();
  while (!Firebase.ready() && (millis() - fbStart < 8000UL)) {
    delay(300);
    yield();
  }

  if (Firebase.ready()) {
    Serial.println("[FB] Reinit OK.");
    fbFailCount = 0;
  } else {
    Serial.println("[FB] Reinit GAGAL — akan coba lagi nanti.");
  }
  lcd.clear();
  lastLCDUpdate = 0;
}

// ============================================================
//  RTC INIT + NTP SYNC (selalu sync dari NTP)
// ============================================================
#define WIB_OFFSET_SEC (7L * 3600L)

void initRTC() {
  if (!rtc.begin()) {
    lcd.clear();
    lcdPrintCenter(0, "! RTC ERROR !");
    lcdPrintCenter(1, "Cek koneksi");
    delay(2000);
    return;
  }

  bool setSuccess = false;

  // Selalu coba sync dari NTP jika WiFi tersambung
  if (WiFi.status() == WL_CONNECTED) {
    configTime(0, 0, "pool.ntp.org", "time.nist.gov");
    time_t now = time(nullptr);
    int ntpAttempts = 0;
    while (now < 24 * 3600 && ntpAttempts < 30) {
      delay(100);
      now = time(nullptr);
      ++ntpAttempts;
    }
    if (now >= 24 * 3600) {
      struct tm ti;
      gmtime_r(&now, &ti);
      rtc.adjust(DateTime(ti.tm_year + 1900, ti.tm_mon + 1, ti.tm_mday,
                          ti.tm_hour, ti.tm_min, ti.tm_sec));
      Serial.println("[RTC] Diset dari NTP (UTC)");
      setSuccess = true;
    } else {
      Serial.println("[RTC] NTP gagal mendapatkan waktu.");
    }
  } else {
    Serial.println("[RTC] WiFi tidak tersambung, tidak bisa sync NTP.");
  }

  // Jika NTP gagal, cek apakah RTC kehilangan daya
  if (!setSuccess) {
    if (rtc.lostPower()) {
      rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
      Serial.println("[RTC] Baterai habis, diset dari waktu compile (asumsi UTC)");
    } else {
      Serial.println("[RTC] NTP gagal, menggunakan waktu yang tersimpan di RTC.");
    }
  }

  // Tampilkan waktu UTC dan WIB
  DateTime now = rtc.now();
  char buf[32];
  snprintf(buf, sizeof(buf), "%04d-%02d-%02d %02d:%02d:%02d",
           now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());
  Serial.print("[RTC] Waktu sekarang (UTC): ");
  Serial.println(buf);

  DateTime wib = now + TimeSpan(WIB_OFFSET_SEC);
  snprintf(buf, sizeof(buf), "%04d-%02d-%02d %02d:%02d:%02d",
           wib.year(), wib.month(), wib.day(), wib.hour(), wib.minute(), wib.second());
  Serial.print("[RTC] Waktu sekarang (WIB): ");
  Serial.println(buf);
}

// ============================================================
//  BACA THRESHOLDS DARI FIREBASE (handle int & double)
// ============================================================
void readFirebaseThresholds() {
  if (!Firebase.ready()) return;
  if (Firebase.RTDB.getJSON(&fbdo, "/komposter/thresholds")) {
    FirebaseJson &json = fbdo.jsonObject();
    FirebaseJsonData jsonData;

    json.get(jsonData, "temperature/min");
    if (jsonData.success)
      tempThresholdMin = (jsonData.typeNum == FirebaseJson::JSON_INT)
                             ? (float)jsonData.intValue
                             : (float)jsonData.doubleValue;

    json.get(jsonData, "temperature/max");
    if (jsonData.success)
      tempThresholdMax = (jsonData.typeNum == FirebaseJson::JSON_INT)
                             ? (float)jsonData.intValue
                             : (float)jsonData.doubleValue;

    json.get(jsonData, "gas/max");
    if (jsonData.success)
      gasThresholdMax = (jsonData.typeNum == FirebaseJson::JSON_INT)
                            ? (float)jsonData.intValue
                            : (float)jsonData.doubleValue;

    json.get(jsonData, "soil/min");
    if (jsonData.success)
      soilThresholdMin = (jsonData.typeNum == FirebaseJson::JSON_INT)
                             ? (float)jsonData.intValue
                             : (float)jsonData.doubleValue;

    json.get(jsonData, "soil/max");
    if (jsonData.success)
      soilThresholdMax = (jsonData.typeNum == FirebaseJson::JSON_INT)
                             ? (float)jsonData.intValue
                             : (float)jsonData.doubleValue;

    Serial.print("[SYNC] Thresholds loaded: Temp(");
    Serial.print(tempThresholdMin, 1); Serial.print("-"); Serial.print(tempThresholdMax, 1);
    Serial.print("C) Gas(<"); Serial.print(gasThresholdMax, 0);
    Serial.print("ppm) Soil("); Serial.print(soilThresholdMin, 0);
    Serial.print("-"); Serial.print(soilThresholdMax, 0);
    Serial.println("%)");
  }
}

// ============================================================
//  BACA PERINTAH KONTROL DARI FIREBASE
// ============================================================
void readFirebaseControls() {
  if (!Firebase.ready()) return;
  if (Firebase.RTDB.getJSON(&fbdo, "/komposter/controls")) {
    FirebaseJson &json = fbdo.jsonObject();
    FirebaseJsonData jsonData;

    // Pompa P1
    json.get(jsonData, "p1/command");
    if (jsonData.success) {
      String cmd = jsonData.stringValue;
      if (cmd == "ON" && !pumpP1Active && !pump1CmdProcessed) {
        json.get(jsonData, "p1/duration_sec");
        if (jsonData.success)
          pumpP1Duration = (unsigned long)jsonData.intValue * 1000UL;
        pumpP1Active = true;
        pumpP1StartMs = millis();
        pump1CmdProcessed = true;
        Firebase.RTDB.setString(&fbdo, "/komposter/controls/p1/command", "OFF");
        Serial.println("[CTRL] Pompa P1 ON");
      } else if (cmd == "OFF") {
        pump1CmdProcessed = false;
      }
    }

    // Pompa P2
    json.get(jsonData, "p2/command");
    if (jsonData.success) {
      String cmd = jsonData.stringValue;
      if (cmd == "ON" && !pumpP2Active && !pump2CmdProcessed) {
        json.get(jsonData, "p2/duration_sec");
        if (jsonData.success)
          pumpP2Duration = (unsigned long)jsonData.intValue * 1000UL;
        pumpP2Active = true;
        pumpP2StartMs = millis();
        pump2CmdProcessed = true;
        Firebase.RTDB.setString(&fbdo, "/komposter/controls/p2/command", "OFF");
        Serial.println("[CTRL] Pompa P2 ON");
      } else if (cmd == "OFF") {
        pump2CmdProcessed = false;
      }
    }

    // Motor
    json.get(jsonData, "motor/enabled");
    if (jsonData.success) motorEnabled = jsonData.boolValue;
    json.get(jsonData, "motor/schedule_hours");
    if (jsonData.success) motorScheduleHours = jsonData.stringValue;
    json.get(jsonData, "motor/duration_minutes");
    if (jsonData.success) {
      motorDurationMin = jsonData.intValue;
      if (motorDurationMin < 1) motorDurationMin = 1;
      if (motorDurationMin > 120) motorDurationMin = 120;
    }
  }
}

// ============================================================
//  SENSOR: MQ-135 (VCC=5.0V, R0=375.0 kΩ, formula standar)
// ============================================================
float readMQ135ppm() {
  long sum = 0;
  for (int i = 0; i < MQ135_SAMPLES; i++) {
    sum += analogRead(MQ135_AOUT_PIN);
    delay(3);
  }
  float adcAvg = (float)sum / MQ135_SAMPLES;

  if (adcAvg >= 4090.0f || adcAvg <= 10.0f) return -1.0f;

  // Tegangan yang terbaca pada pin ESP32 ADC (0V s/d 3.3V)
  float vADC = (adcAvg / MQ135_ADC_MAX) * ESP32_VREF;
  if (vADC <= 0.01f || vADC >= 3.28f) return -1.0f;

  // Hitung RS dengan VCC = 5.0V (karena MQ-135 terhubung ke 5V)
  float rs = MQ135_RL_VALUE * (MQ135_VCC - vADC) / vADC;
  if (rs <= 0.0f) return -1.0f;

  float ratio = rs / MQ135_R0;
  if (ratio <= 0.0f) return -1.0f;

  // Formula standar kurva karakteristik MQ-135
  // PPM = 116.602 * ratio^(-2.769)
  float ppm = 116.602f * pow(ratio, -2.769f);
  return constrain(ppm, 1.0f, 2000.0f);
}

// ============================================================
//  SENSOR: DS18B20
// ============================================================
float readTemperature() {
  for (int attempt = 0; attempt < 3; attempt++) {
    sensors.requestTemperatures();
    unsigned long waitMs = sensors.millisToWaitForConversion(TEMP_RESOLUTION);
    delay(waitMs + 20);

    portDISABLE_INTERRUPTS();
    float temp = sensors.getTempCByIndex(0);
    portENABLE_INTERRUPTS();

    if (temp != DEVICE_DISCONNECTED_C && temp != -127.0f) {
      return temp + TEMP_OFFSET;
    }
    delay(50);
  }
  return -999.0f;
}

// ============================================================
//  SENSOR: Soil Moisture (DRY=3300, WET=1000)
// ============================================================
float readSoilMoisture() {
  long sum = 0;
  for (int i = 0; i < SOIL_SAMPLES; i++) {
    sum += analogRead(SOIL_PIN);
    delay(5);
  }
  int adcAvg = (int)(sum / SOIL_SAMPLES);

  if (adcAvg >= 4090 || adcAvg <= 100) return -1.0f;

  // Interpolasi linear: DRY (3300) → 0%, WET (1000) → 100%
  // Sensor Kapasitif: Nilai ADC makin KECIL saat media makin BASAH
  float moisture = (float)(SOIL_DRY_ADC - adcAvg) /
                   (float)(SOIL_DRY_ADC - SOIL_WET_ADC) * 100.0f;
  return constrain(moisture, 0.0f, 100.0f);
}

// ============================================================
//  CEK ERROR SENSOR
// ============================================================
bool isTempError(float t) { return (t < -900.0f); }
bool isSoilError(float s) { return (s < 0.0f); }
bool isGasError(float g)  { return (g < 0.0f || g > 5000.0f); }

// ============================================================
//  KONTROL POMPA (NON-BLOCKING)
// ============================================================
void handlePumpTimers() {
  unsigned long now = millis();

  if (pumpP1Active) {
    if (now - pumpP1StartMs >= pumpP1Duration) {
      pumpP1Active = false;
      p1Status = false;
      digitalWrite(P1_PIN, RELAY4_OFF);
      pump1CmdProcessed = false;
      Serial.println("[CTRL] Pompa P1 OFF");
    } else {
      p1Status = true;
      digitalWrite(P1_PIN, RELAY4_ON);
    }
  }

  if (pumpP2Active) {
    if (now - pumpP2StartMs >= pumpP2Duration) {
      pumpP2Active = false;
      p2Status = false;
      digitalWrite(P2_PIN, RELAY4_OFF);
      pump2CmdProcessed = false;
      Serial.println("[CTRL] Pompa P2 OFF");
    } else {
      p2Status = true;
      digitalWrite(P2_PIN, RELAY4_ON);
    }
  }
}

// ============================================================
//  MOTOR JADWAL
// ============================================================
void handleMotorSchedule(int currentHour, int currentMinute, int currentDay) {
  if (!motorEnabled) {
    if (motorStatus) {
      digitalWrite(MOTOR_PIN, RELAY2_OFF);
      motorStatus = false;
    }
    motorSessionActive = false;
    return;
  }

  if (motorSessionActive) {
    unsigned long elapsed = millis() - motorSessionStart;
    if (elapsed >= (unsigned long)motorDurationMin * 60000UL) {
      digitalWrite(MOTOR_PIN, RELAY2_OFF);
      motorStatus = false;
      motorSessionActive = false;
      Serial.println("[MOTOR] Sesi selesai");
    } else {
      digitalWrite(MOTOR_PIN, RELAY2_ON);
      motorStatus = true;
    }
    return;
  }

  if (motorScheduleHours.length() == 0) return;
  if (currentHour == motorLastRunHour &&
      currentMinute == motorLastRunMinute &&
      currentDay == motorLastRunDay) return;

  bool shouldRun = false;
  int startIdx = 0;
  for (int i = 0; i <= (int)motorScheduleHours.length(); i++) {
    if (i == (int)motorScheduleHours.length() ||
        motorScheduleHours.charAt(i) == ',') {
      String timeStr = motorScheduleHours.substring(startIdx, i);
      timeStr.trim();
      int sepIdx = timeStr.indexOf(':');
      int schHour = -1, schMin = -1;
      if (sepIdx != -1) {
        schHour = timeStr.substring(0, sepIdx).toInt();
        schMin  = timeStr.substring(sepIdx + 1).toInt();
      } else {
        schHour = timeStr.toInt();
        schMin  = 0;
      }
      if (schHour == currentHour && schMin == currentMinute) {
        shouldRun = true;
        break;
      }
      startIdx = i + 1;
    }
  }

  if (shouldRun) {
    motorSessionActive = true;
    motorSessionStart  = millis();
    motorLastRunHour   = currentHour;
    motorLastRunMinute = currentMinute;
    motorLastRunDay    = currentDay;
    digitalWrite(MOTOR_PIN, RELAY2_ON);
    motorBuzzCount = 0;
    lastBuzzTime   = millis() - 3000;
    motorBuzzActive = true;
    Serial.println("[MOTOR] Sesi dimulai jam " + String(currentHour) + ":" +
                   String(currentMinute));
  }
}

// ============================================================
//  BUZZER MOTOR (3x beep saat motor mulai)
// ============================================================
void handleMotorBuzzer() {
  if (!motorBuzzActive) return;
  if (motorBuzzCount < 3) {
    if (millis() - lastBuzzTime >= 3000) {
      lastBuzzTime = millis();
      digitalWrite(BUZZER_PIN, HIGH);
      delay(200);
      digitalWrite(BUZZER_PIN, LOW);
      motorBuzzCount++;
    }
  } else {
    motorBuzzActive = false;
  }
}

// ============================================================
//  LCD: ROTATING DISPLAY (6 SCREEN — Motor punya screen sendiri)
//
//  Screen 0: Suhu Kompos
//  Screen 1: Kadar Gas MQ-135
//  Screen 2: Kelembaban Tanah
//  Screen 3: Motor Pengaduk    ← screen terpisah
//  Screen 4: Fan & Heater
//  Screen 5: Pompa P1 & P2
// ============================================================
void updateLCDRotating(float temp, float gas, float soil, const char *timeStr) {
  unsigned long now = millis();
  if (now - lastLCDUpdate < LCD_INTERVAL) return;
  lastLCDUpdate = now;
  lcd.clear();
  char buf[17];

  // Evaluasi kondisi peringatan per sensor
  bool tempLow  = (!isTempError(temp) && temp < tempThresholdMin);
  bool tempIsHigh = (!isTempError(temp) && temp > tempThresholdMax);
  bool tempWarn = (tempLow || tempIsHigh);

  bool gasWarn  = (!isGasError(gas) && gas > gasThresholdMax);
  bool soilLow  = (!isSoilError(soil) && soil < soilThresholdMin);
  bool soilHigh = (!isSoilError(soil) && soil > soilThresholdMax);
  bool soilWarn = (soilLow || soilHigh);

  // Buzzer beep saat screen sensor menunjukkan peringatan
  if ((lcdScreen == 0 && tempWarn) ||
      (lcdScreen == 1 && gasWarn)  ||
      (lcdScreen == 2 && soilWarn)) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(120);
    digitalWrite(BUZZER_PIN, LOW);
  }

  switch (lcdScreen) {
  case 0: // ── SCREEN 0: SUHU KOMPOS ──────────────────────
    lcd.setCursor(0, 0);
    lcd.write(0); // Icon Thermometer
    snprintf(buf, sizeof(buf), " SUHU %s", timeStr);
    lcd.print(buf);

    lcd.setCursor(0, 1);
    if (isTempError(temp)) {
      lcd.print("  [ NO SENSOR ] ");
    } else if (tempLow) {
      snprintf(buf, sizeof(buf), " %4.1f%cC [DINGIN]", temp, (char)223);
      lcd.print(buf);
    } else if (tempIsHigh) {
      snprintf(buf, sizeof(buf), " %4.1f%cC [PANAS]", temp, (char)223);
      lcd.print(buf);
    } else {
      snprintf(buf, sizeof(buf), " %4.1f%cC  [ OK ] ", temp, (char)223);
      lcd.print(buf);
    }
    break;

  case 1: // ── SCREEN 1: KADAR GAS (MQ-135) ──────────────
    lcd.setCursor(0, 0);
    lcd.write(1); // Icon Gas
    lcd.print(" GAS MQ-135    ");

    lcd.setCursor(0, 1);
    if (isGasError(gas)) {
      lcd.print("  [ NO SENSOR ] ");
    } else if (gasWarn) {
      snprintf(buf, sizeof(buf), " %4.0f ppm[PEKAT]", gas);
      lcd.print(buf);
    } else {
      snprintf(buf, sizeof(buf), " %4.0f ppm [ OK ]", gas);
      lcd.print(buf);
    }
    break;

  case 2: // ── SCREEN 2: KELEMBABAN TANAH ─────────────────
    lcd.setCursor(0, 0);
    lcd.write(2); // Icon Soil / Droplet
    lcd.print(" KELEMBABAN    ");

    lcd.setCursor(0, 1);
    if (isSoilError(soil)) {
      lcd.print("  [ NO SENSOR ] ");
    } else if (soilLow) {
      snprintf(buf, sizeof(buf), "  %3.0f%% [KERING] ", soil);
      lcd.print(buf);
    } else if (soilHigh) {
      snprintf(buf, sizeof(buf), "  %3.0f%%  [BASAH] ", soil);
      lcd.print(buf);
    } else {
      snprintf(buf, sizeof(buf), "  %3.0f%%   [ OK ] ", soil);
      lcd.print(buf);
    }
    break;

  case 3: // ── SCREEN 3: MOTOR PENGADUK (screen sendiri) ──
    lcd.setCursor(0, 0);
    lcd.write(3); // Icon Motor
    lcd.print(" MOTOR PENGADUK");

    lcd.setCursor(0, 1);
    if (motorStatus) {
      lcd.print("  Status: [ ON ]");
    } else {
      lcd.print("  Status: [OFF] ");
    }
    break;

  case 4: // ── SCREEN 4: FAN & HEATER ─────────────────────
    lcd.setCursor(0, 0);
    lcd.write(4); // Icon Fan
    lcd.print(" FAN & HEATER  ");

    lcd.setCursor(0, 1);
    snprintf(buf, sizeof(buf), "FAN:%-3s  HEAT:%-3s",
             fanStatus ? "ON" : "OFF",
             heaterStatus ? "ON" : "OFF");
    lcd.print(buf);
    break;

  case 5: // ── SCREEN 5: POMPA P1 & P2 ────────────────────
    lcd.setCursor(0, 0);
    lcd.write(5); // Icon Pump
    lcd.print(" POMPA NUTRISI ");

    lcd.setCursor(0, 1);
    snprintf(buf, sizeof(buf), "P1:%-3s   P2:%-3s",
             p1Status ? "ON" : "OFF",
             p2Status ? "ON" : "OFF");
    lcd.print(buf);
    break;
  }

  lcdScreen = (lcdScreen + 1) % 6;
}

// ============================================================
//  SERIAL MONITOR
// ============================================================
void printSerialMonitor(float temp, float gas, float soil,
                        const char *timeStr) {
  Serial.println(F("\n=================================================="));
  Serial.print(F("     I-COMPOST v2.6.0-ESP32 | WIB: "));
  Serial.println(timeStr);
  Serial.println(F("=================================================="));
  Serial.print(F(" Suhu         : "));
  if (isTempError(temp)) Serial.println(F("NO SENSOR"));
  else { Serial.print(temp, 1); Serial.println(F(" C")); }

  Serial.print(F(" Gas          : "));
  if (isGasError(gas)) Serial.println(F("NO SENSOR"));
  else {
    Serial.print(gas, 1);
    Serial.print(F(" ppm (raw ADC: "));
    Serial.print(analogRead(MQ135_AOUT_PIN));
    Serial.println(F(")"));
  }

  Serial.print(F(" Kelembaban   : "));
  if (isSoilError(soil)) Serial.println(F("NO SENSOR"));
  else {
    Serial.print(soil, 1);
    Serial.print(F(" % (raw ADC: "));
    Serial.print(analogRead(SOIL_PIN));
    Serial.println(F(")"));
  }

  Serial.println(F("--------------------------------------------------"));
  Serial.print(F(" Heater       : ")); Serial.println(heaterStatus ? F("ON") : F("OFF"));
  Serial.print(F(" Exhaust Fan  : ")); Serial.println(fanStatus ? F("ON") : F("OFF"));
  Serial.print(F(" Motor Aduk   : ")); Serial.println(motorStatus ? F("ON") : F("OFF"));
  Serial.print(F(" Pompa P1     : ")); Serial.println(p1Status ? F("ON") : F("OFF"));
  Serial.print(F(" Pompa P2     : ")); Serial.println(p2Status ? F("ON") : F("OFF"));

  // DEBUG: status motor jadwal
  Serial.print(F(" [DEBUG] motorEnabled="));  Serial.print(motorEnabled);
  Serial.print(F(", sessionActive="));         Serial.print(motorSessionActive);
  Serial.print(F(", pinState="));              Serial.println(digitalRead(MOTOR_PIN));

  Serial.println(F("=================================================="));
  Serial.print(F(" Heap     : ")); Serial.print(ESP.getFreeHeap()); Serial.println(F(" bytes"));
  Serial.print(F(" WiFi RSSI: ")); Serial.print(WiFi.RSSI()); Serial.println(F(" dBm"));
  Serial.print(F(" FB Ready : ")); Serial.println(Firebase.ready() ? F("YES") : F("NO"));
  if (!Firebase.ready()) {
    Serial.print(F(" FB Error : ")); Serial.println(fbdo.errorReason().c_str());
  }
  Serial.println();
}

// ============================================================
//  ANIMATED OPENING
// ============================================================
void animatedOpening() {
  lcd.clear();
  lcd.createChar(0, blockChar);
  lcd.createChar(1, charCheck);
  lcd.setCursor(3, 0);
  const char *brand = "I-COMPOST";
  for (int i = 0; brand[i]; ++i) {
    lcd.print(brand[i]);
    delay(150);
  }
  delay(1000);
  lcd.setCursor(5, 1);
  const char *tag = "by PNJ";
  for (int i = 0; tag[i]; ++i) {
    lcd.print(tag[i]);
    delay(80);
  }
  delay(1000);
  lcd.clear();
  lcdPrintCenter(0, "Initializing..");
  for (int i = 0; i <= 14; ++i) {
    lcd.setCursor(0, 1);
    lcd.print("[");
    for (int j = 0; j < i; ++j) lcd.write((uint8_t)0);
    for (int j = i; j < 14; ++j) lcd.print(" ");
    lcd.print("]");
    delay(120);
  }
  initWiFi();
  initFirebase();
  initRTC();
  readFirebaseThresholds();
  readFirebaseControls();
  lastFirebaseSync = millis();
  lcd.clear();
  lcdPrintCenter(0, "** SYSTEM **");
  lcdPrintCenter(1, "** READY!  **");
  for (int i = 0; i < 3; ++i) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(100);
    digitalWrite(BUZZER_PIN, LOW);
    delay(100);
  }
  delay(1000);
  lcd.clear();
  lcdPrintCenter(0, "I-COMPOST");
  lcdPrintCenter(1, "v2.6.0");
  delay(1500);
  lcd.clear();

  // Load custom 5x8 characters ke LCD
  lcd.createChar(0, charTemp);
  lcd.createChar(1, charGas);
  lcd.createChar(2, charSoil);
  lcd.createChar(3, charMotor);
  lcd.createChar(4, charFan);
  lcd.createChar(5, charPump);
  lcd.createChar(6, charAlert);
  lcd.createChar(7, charCheck);
}

// ============================================================
//  SETUP
// ============================================================
void setup() {
  Serial.begin(115200);
  delay(300);

  WiFi.setSleep(WIFI_PS_MIN_MODEM);

  pinMode(HEATER_PIN, OUTPUT);
  pinMode(FAN_PIN, OUTPUT);
  pinMode(P1_PIN, OUTPUT);
  pinMode(P2_PIN, OUTPUT);
  pinMode(MOTOR_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // Pastikan semua relay mati saat boot
  digitalWrite(MOTOR_PIN,  RELAY2_OFF);
  digitalWrite(HEATER_PIN, RELAY4_OFF);
  digitalWrite(FAN_PIN,    RELAY4_OFF);
  digitalWrite(P1_PIN,     RELAY4_OFF);
  digitalWrite(P2_PIN,     RELAY4_OFF);
  digitalWrite(BUZZER_PIN, LOW);

  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setTimeOut(1000);
  lcd.init();
  lcd.backlight();

  animatedOpening();

  sensors.begin();
  sensors.setResolution(TEMP_RESOLUTION);
  analogReadResolution(12);

  analogSetPinAttenuation(MQ135_AOUT_PIN, ADC_11db);
  analogSetPinAttenuation(SOIL_PIN, ADC_11db);

  Serial.println("\n[INFO] Kalibrasi v2.6.0:");
  Serial.println("  Soil   : DRY=" + String(SOIL_DRY_ADC) + " WET=" +
                 String(SOIL_WET_ADC) + " (linear, turun saat basah)");
  Serial.println("  MQ-135 : R0=" + String(MQ135_R0, 1) +
                 " kOhm, VCC=5.0V (formula standar)");
  Serial.println("  DS18B20: retry 3x + kunci interrupt");
  Serial.println("  RTC    : selalu sync dari NTP jika WiFi tersambung");
  Serial.println("  Motor  : otomatis via jadwal Firebase (active HIGH)");
  Serial.println("  WiFi   : Dual SSID (4G-UFI-F6F / Samsung)");
  Serial.println("  Chip   : ESP32 30-pin classic");
}

// ============================================================
//  LOOP UTAMA
// ============================================================
void loop() {
  unsigned long currentMs = millis();

  // Sync thresholds dari Firebase setiap 5 detik
  if (currentMs - lastFirebaseSync >= 5000UL) {
    lastFirebaseSync = currentMs;
    readFirebaseThresholds();
  }

  // Baca kontrol dari Firebase setiap 3 detik
  if (currentMs - lastControlRead >= 3000UL) {
    lastControlRead = currentMs;
    readFirebaseControls();
  }

  handlePumpTimers();
  handleMotorBuzzer();

  // Baca sensor
  float temperature = readTemperature();
  float gasPPM      = readMQ135ppm();
  float soilPercent = readSoilMoisture();

  // Waktu RTC → WIB
  DateTime nowUTC = rtc.now();
  DateTime nowWIB = nowUTC + TimeSpan(WIB_OFFSET_SEC);
  char timeString[9];
  sprintf(timeString, "%02d:%02d:%02d",
          nowWIB.hour(), nowWIB.minute(), nowWIB.second());
  int currentHour   = nowWIB.hour();
  int currentMinute = nowWIB.minute();
  int currentDay    = nowWIB.day();

  handleMotorSchedule(currentHour, currentMinute, currentDay);

  // Heater & Fan (otomatis berdasarkan threshold)
  heaterStatus = (!isTempError(temperature) && temperature < tempThresholdMin);
  gasHigh  = (!isGasError(gasPPM) && gasPPM > gasThresholdMax);
  tempHigh = (!isTempError(temperature) && temperature > tempThresholdMax);
  fanStatus = (gasHigh || tempHigh);

  digitalWrite(HEATER_PIN, heaterStatus ? RELAY4_ON : RELAY4_OFF);
  digitalWrite(FAN_PIN,    fanStatus    ? RELAY4_ON : RELAY4_OFF);

  // Log actuator ke Firebase saat berubah
  if (Firebase.ready()) {
    auto pushActuatorLog = [&](String name, bool status, String reason,
                               float val) {
      FirebaseJson log;
      log.set("actuator", name);
      log.set("status", status ? "ON" : "OFF");
      log.set("reason", reason);
      log.set("value", val);
      log.set("time", timeString);
      log.set("unix_time", (double)nowUTC.unixtime());
      Firebase.RTDB.pushJSON(&fbdo, "/logs/actuators", &log);
    };
    if (heaterStatus != prevHeater) {
      pushActuatorLog("Heater", heaterStatus,
                      heaterStatus ? "Suhu Terlalu Rendah"
                                   : "Suhu Sudah Normal",
                      temperature);
      prevHeater = heaterStatus;
    }
    if (fanStatus != prevFan) {
      String reason =
          fanStatus
              ? ((gasHigh && tempHigh)
                     ? "Bau & Suhu Tinggi"
                     : (gasHigh ? "Kadar Bau Tinggi" : "Suhu Terlalu Tinggi"))
              : "Bau & Suhu Normal";
      pushActuatorLog("Exhaust Fan", fanStatus, reason,
                      (gasHigh ? gasPPM : temperature));
      prevFan = fanStatus;
    }
    if (p1Status != prevP1) {
      pushActuatorLog("Pompa P1", p1Status,
                      p1Status ? "Dinyalakan dari App" : "Selesai / Dimatikan",
                      soilPercent);
      prevP1 = p1Status;
    }
    if (p2Status != prevP2) {
      pushActuatorLog("Pompa P2", p2Status,
                      p2Status ? "Dinyalakan dari App" : "Selesai / Dimatikan",
                      0.0f);
      prevP2 = p2Status;
    }
    if (motorStatus != prevMotor) {
      pushActuatorLog("Motor Aduk", motorStatus,
                      motorStatus ? "Jadwal ON" : "Selesai / OFF", 0.0f);
      prevMotor = motorStatus;
    }
  }

  // Update rotasi layar LCD (6 Screen)
  updateLCDRotating(temperature, gasPPM, soilPercent, timeString);

  // Upload data ke Firebase (interval 5 detik — kurangi tekanan SSL)
  if (currentMs - lastDataUpload >= 5000UL) {
    lastDataUpload = currentMs;
    printSerialMonitor(temperature, gasPPM, soilPercent, timeString);

    ++packetId;

    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("[FB] WiFi terputus — skip upload");
    } else if (!Firebase.ready()) {
      Serial.println("[FB] Firebase belum ready — skip upload");
      fbFailCount++;
      if (fbFailCount >= FB_FAIL_REINIT) reinitFirebase();
    } else {
      FirebaseJson json;
      json.set("temperature", isTempError(temperature) ? -1.0f : temperature);
      json.set("gas",  isGasError(gasPPM)       ? -1.0f : gasPPM);
      json.set("soil", isSoilError(soilPercent)  ? -1.0f : soilPercent);
      json.set("time", timeString);
      json.set("unix_time", (double)nowUTC.unixtime());
      json.set("actuators/heater", heaterStatus);
      json.set("actuators/fan",    fanStatus);
      json.set("actuators/motor",  motorStatus);
      json.set("actuators/p1",     p1Status);
      json.set("actuators/p2",     p2Status);

      float packetLossPct = 0.0f;
      if (qosTotalSent > 0)
        packetLossPct = ((float)qosTotalFailed / (float)qosTotalSent) * 100.0f;

      json.set("qos/delay_ms",        qosLastDelayMs);
      json.set("qos/throughput_bps",   qosLastThroughputBps);
      json.set("qos/jitter_ms",       qosLastJitterMs);
      json.set("qos/packet_loss_pct", packetLossPct);
      json.set("qos/free_heap",       (uint32_t)ESP.getFreeHeap());
      json.set("qos/uptime_ms",       (uint32_t)millis());
      json.set("qos/packet_id",       packetId);

      String jsonStr;
      json.toString(jsonStr, false);
      size_t payloadSize = jsonStr.length() + 300;

      yield(); // beri kesempatan WiFi stack sebelum SSL
      unsigned long startSend = millis();
      bool ok = Firebase.RTDB.updateNode(&fbdo, "/komposter", &json);
      unsigned long endSend = millis();
      yield();

      qosTotalSent++;

      if (ok) {
        fbFailCount = 0; // reset counter saat berhasil
        float currentDelayMs = (float)(endSend - startSend);
        if (qosLastDelayMs > 0)
          qosLastJitterMs = fabs(currentDelayMs - qosLastDelayMs);
        else
          qosLastJitterMs = 0;
        float delaySeconds = currentDelayMs / 1000.0f;
        if (delaySeconds > 0)
          qosLastThroughputBps = ((float)payloadSize / delaySeconds);
        qosLastDelayMs = currentDelayMs;
        Serial.println("[FB] Upload OK. Delay: " + String(currentDelayMs, 0) +
                       "ms | Jitter: " + String(qosLastJitterMs, 0) +
                       "ms | Throughput: " + String(qosLastThroughputBps, 1) +
                       " Bps");
      } else {
        qosTotalFailed++;
        fbFailCount++;
        Serial.println("[FB] !! Upload GAGAL !! (" + String(fbFailCount) + "/" +
                       String(FB_FAIL_REINIT) + ")");
        Serial.println("[FB]    Reason  : " + fbdo.errorReason());
        Serial.println("[FB]    HTTP    : " + String(fbdo.httpCode()));
        Serial.println("[FB]    Path    : /komposter");
        if (fbFailCount >= FB_FAIL_REINIT) reinitFirebase();
      }

      // Push ke history log setiap 1 menit
      if (currentMs - lastHistoryPush >= 60000UL) {
        lastHistoryPush = currentMs;
        yield();
        Firebase.RTDB.pushJSON(&fbdo, "/komposter_logs", &json);
        yield();
      }
    }
  }

  // ── WiFi reconnect — bergantian SSID1 / SSID2 ─────────
  static unsigned long lastWifiCheck = 0;
  static bool wifiWasDisconnected = false;
  static int reconnectSSID = 1; // mulai dari SSID1

  if (WiFi.status() != WL_CONNECTED) {
    if (!wifiWasDisconnected) {
      wifiWasDisconnected = true;
      lcd.clear();
      lcdPrintCenter(0, "! WiFi Putus !");
      lcdPrintCenter(1, "Menghubungkan..");
    }
    if (currentMs - lastWifiCheck >= 30000UL) {
      lastWifiCheck = currentMs;
      WiFi.disconnect();
      delay(200);
      if (reconnectSSID == 1) {
        Serial.println("[WiFi] Reconnect: mencoba " + String(WIFI_SSID1));
        WiFi.begin(WIFI_SSID1, WIFI_PASSWORD1);
        reconnectSSID = 2; // next time try SSID2
      } else {
        Serial.println("[WiFi] Reconnect: mencoba " + String(WIFI_SSID2));
        WiFi.begin(WIFI_SSID2, WIFI_PASSWORD2);
        reconnectSSID = 1; // next time try SSID1
      }
    }
  } else {
    if (wifiWasDisconnected) {
      wifiWasDisconnected = false;
      reconnectSSID = 1; // reset ke SSID1
      lcd.clear();
      lcdPrintCenter(0, "WiFi Terhubung!");
      lcdPrintCenter(1, WiFi.localIP().toString().c_str());
      delay(1500);
      lcd.clear();
      lastLCDUpdate = 0;
    }
  }

  delay(50);
}