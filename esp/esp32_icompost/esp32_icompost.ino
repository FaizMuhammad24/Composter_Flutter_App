/*
 * =============================================================
 *  I-COMPOST — Firmware ESP32 30-PIN (DevKit V1 / classic)
 *  Versi  : 2.5.1-ESP32 (fix relay motor & RTC)
 *  Tanggal: Juli 2026
 * =============================================================
 *
 *  PERBAIKAN DARI VERSI 2.5.0:
 *  - RTC selalu sinkron dari NTP setiap boot (jika WiFi tersambung)
 *  - Debug status motorCommandOn dan pin relay di Serial Monitor
 *  - Inisialisasi ulang relay motor di setup() dipastikan mati
 *  - Penanganan perintah OFF lebih robust
 *  - Pin mapping tetap sama
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
//  KONFIGURASI WIFI & FIREBASE
// ============================================================
#define WIFI_SSID "4G-UFI-F6F"
#define WIFI_PASSWORD "telkomb23"

#define API_KEY "AIzaSyAQyAwHey8tDJ4moHKDeWDTlAzlINdBJFk"
#define DATABASE_URL "https://icompost-db-default-rtdb.asia-southeast1.firebasedatabase.app/"
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

// Relay logic (active LOW — sesuai dengan modul relay Anda)
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

// ============================================================
//  KALIBRASI SENSOR — DATA TERBARU
// ============================================================
#define MQ135_RL_VALUE 10.0f
#define MQ135_R0 60.0f            // hasil kalibrasi udara bersih
#define MQ135_VREF 3.3f
#define MQ135_ADC_MAX 4095.0f
#define MQ135_SAMPLES 10

#define TEMP_OFFSET 0.0f
#define TEMP_RESOLUTION 12

#define SOIL_SAMPLES 20
#define SOIL_DRY_ADC 3400
#define SOIL_WET_ADC 0

// ============================================================
//  THRESHOLDS
// ============================================================
float tempThresholdMin = 60.0f;
float tempThresholdMax = 70.0f;
float gasThresholdMax = 50.0f;
float soilThresholdMin = 50.0f;

// ============================================================
//  STATUS AKTUATOR & KONTROL
// ============================================================
bool heaterStatus = false;
bool fanStatus = false;
bool p1Status = false;
bool p2Status = false;
bool motorStatus = false;

bool prevHeater = false, prevFan = false;
bool prevP1 = false, prevP2 = false;
bool prevMotor = false;

bool gasHigh = false;
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
bool warningMode = false;
const unsigned long LCD_INTERVAL = 5000UL;

int warningScreen = 0;
unsigned long lastWarningUpdate = 0;
const unsigned long WARNING_INTERVAL = 3000UL;

unsigned long lastFirebaseSync = 0;
unsigned long lastControlRead = 0;
unsigned long lastDataUpload = 0;
unsigned long lastHistoryPush = 0;
unsigned long packetId = 0;

bool motorBuzzActive = false;
int motorBuzzCount = 0;
unsigned long lastBuzzTime = 0;

// ============================================================
//  KARAKTER KUSTOM LCD (tidak diubah)
// ============================================================
byte blockChar[8] = {B11111, B11111, B11111, B11111,
                     B11111, B11111, B11111, B11111};
byte checkMark[8] = {B00000, B00001, B00011, B10110,
                     B11100, B01000, B00000, B00000};
byte thermometer[8] = {B00100, B01010, B01010, B01110,
                       B11111, B11111, B01110, B00000};
byte droplet[8] = {B00100, B01110, B11111, B11111,
                   B11111, B01110, B00100, B00000};

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
//  WIFI (tidak diubah)
// ============================================================
void initWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  unsigned long wifiStartMs = millis();
  const unsigned long WIFI_TIMEOUT = 120000UL;
  int attempt = 0;

  while (WiFi.status() != WL_CONNECTED) {
    unsigned long elapsed = millis() - wifiStartMs;
    if (elapsed >= WIFI_TIMEOUT) break;

    int remaining = (WIFI_TIMEOUT - elapsed) / 1000;
    char buf[17];
    snprintf(buf, sizeof(buf), "Tunggu.. %3ds", remaining);

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
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }
  }

  if (WiFi.status() == WL_CONNECTED) {
    lcd.clear();
    lcdPrintCenter(0, "WiFi Terhubung!");
    lcdPrintCenter(1, WiFi.localIP().toString().c_str());
    delay(1500);
  } else {
    lcd.clear();
    lcdPrintCenter(0, "! WIFI GAGAL !");
    lcdPrintCenter(1, "Lanjut offline");
    delay(2000);
  }
}

// ============================================================
//  FIREBASE INIT (tidak diubah)
// ============================================================
void initFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;
  Firebase.begin(&config, &auth);

  lcd.clear();
  lcdPrintCenter(0, "Firebase...");
  unsigned long fbStart = millis();
  while (!Firebase.ready() && (millis() - fbStart < 15000)) {
    delay(500);
  }
  if (Firebase.ready()) lcdPrintCenter(1, "Terhubung!");
  else lcdPrintCenter(1, "Gagal!");
  delay(1000);
}

// ============================================================
//  RTC INIT + NTP SYNC (DIPERBAIKI — selalu sync dari NTP)
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

  // Jika NTP gagal, cek apakah RTC kehilangan daya / belum diset
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
//  BACA THRESHOLDS DARI FIREBASE
// ============================================================
void readFirebaseThresholds() {
  if (!Firebase.ready()) return;
  if (Firebase.RTDB.getJSON(&fbdo, "/komposter/thresholds")) {
    FirebaseJson &json = fbdo.jsonObject();
    FirebaseJsonData jsonData;
    json.get(jsonData, "temperature/min");
    if (jsonData.success) tempThresholdMin = jsonData.doubleValue;
    json.get(jsonData, "temperature/max");
    if (jsonData.success) tempThresholdMax = jsonData.doubleValue;
    json.get(jsonData, "gas/max");
    if (jsonData.success) gasThresholdMax = jsonData.doubleValue;
    json.get(jsonData, "soil/min");
    if (jsonData.success) soilThresholdMin = jsonData.doubleValue;
    Serial.println("[SYNC] Thresholds loaded");
  }
}

// ============================================================
//  BACA PERINTAH KONTROL DARI FIREBASE (dengan motor manual)
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
        if (jsonData.success) pumpP1Duration = (unsigned long)jsonData.intValue * 1000UL;
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
        if (jsonData.success) pumpP2Duration = (unsigned long)jsonData.intValue * 1000UL;
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
//  SENSOR: MQ-135 (R0=60.0 kΩ)
// ============================================================
float readMQ135ppm() {
  long sum = 0;
  for (int i = 0; i < MQ135_SAMPLES; i++) {
    sum += analogRead(MQ135_AOUT_PIN);
    delay(3);
  }
  float adcAvg = (float)sum / MQ135_SAMPLES;

  if (adcAvg >= 4090.0f || adcAvg <= 10.0f) return -1.0f;

  float voltage = (adcAvg / MQ135_ADC_MAX) * MQ135_VREF;
  if (voltage <= 0.01f || voltage >= 3.28f) return -1.0f;

  float rs = MQ135_RL_VALUE * (MQ135_VREF - voltage) / voltage;
  if (rs <= 0.0f) return -1.0f;

  float ratio = rs / MQ135_R0;
  if (ratio <= 0.0f || ratio > 1.5f) return -1.0f;

  // Interpolasi dua titik: ratio=1 → ppm=1, ratio=0.238 → ppm=100
  const float RATIO_GAS = 0.238f;
  float ppm = 1.0f + (100.0f - 1.0f) * (1.0f - ratio) / (1.0f - RATIO_GAS);
  return constrain(ppm, 1.0f, 100.0f);
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
//  SENSOR: Soil Moisture (DRY=3400, WET=0)
// ============================================================
float readSoilMoisture() {
  long sum = 0;
  for (int i = 0; i < SOIL_SAMPLES; i++) {
    sum += analogRead(SOIL_PIN);
    delay(10);
  }
  int adcAvg = (int)(sum / SOIL_SAMPLES);

  if (adcAvg >= 4090 || adcAvg <= 10) return -1.0f;

  // Interpolasi linear: DRY=3400 → 0%, WET=0 → 100%
  float moisture = (float)(SOIL_DRY_ADC - adcAvg) / (SOIL_DRY_ADC - SOIL_WET_ADC) * 100.0f;
  return constrain(moisture, 0.0f, 100.0f);
}

// ============================================================
//  CEK ERROR SENSOR
// ============================================================
bool isTempError(float t) { return (t < -900.0f); }
bool isSoilError(float s) { return (s < 0.0f); }
bool isGasError(float g) { return (g < 0.0f || g > 200.0f); }

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
  if (currentHour == motorLastRunHour && currentMinute == motorLastRunMinute && currentDay == motorLastRunDay) return;

  bool shouldRun = false;
  int startIdx = 0;
  for (int i = 0; i <= (int)motorScheduleHours.length(); i++) {
    if (i == (int)motorScheduleHours.length() || motorScheduleHours.charAt(i) == ',') {
      String timeStr = motorScheduleHours.substring(startIdx, i);
      timeStr.trim();
      int sepIdx = timeStr.indexOf(':');
      int schHour = -1, schMin = -1;
      if (sepIdx != -1) {
        schHour = timeStr.substring(0, sepIdx).toInt();
        schMin = timeStr.substring(sepIdx + 1).toInt();
      } else {
        schHour = timeStr.toInt();
        schMin = 0;
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
    motorSessionStart = millis();
    motorLastRunHour = currentHour;
    motorLastRunMinute = currentMinute;
    motorLastRunDay = currentDay;
    digitalWrite(MOTOR_PIN, RELAY2_ON);
    motorBuzzCount = 0;
    lastBuzzTime = millis() - 3000;
    motorBuzzActive = true;
    Serial.println("[MOTOR] Sesi dimulai jam " + String(currentHour) + ":" + String(currentMinute));
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
//  LCD: WARNING MODE (tidak diubah)
// ============================================================
void updateLCDWithWarning(float gas, float temp, float soil) {
  unsigned long now = millis();
  if (now - lastWarningUpdate < WARNING_INTERVAL) return;
  lastWarningUpdate = now;

  struct Warning {
    const char *title;
    char value[17];
    bool buzzer;
  };
  Warning warnings[5];
  int wCount = 0;

  if (!isGasError(gas) && gas > gasThresholdMax) {
    warnings[wCount] = {"! BAU TINGGI !", "", true};
    snprintf(warnings[wCount].value, 17, "%.0f ppm", gas);
    wCount++;
  }
  if (!isTempError(temp) && temp < tempThresholdMin) {
    warnings[wCount] = {"! SUHU RENDAH !", "", false};
    snprintf(warnings[wCount].value, 17, "%.1f%cC [Heat]", temp, (char)223);
    wCount++;
  }
  if (!isTempError(temp) && temp > tempThresholdMax) {
    warnings[wCount] = {"! SUHU TINGGI !", "", false};
    snprintf(warnings[wCount].value, 17, "%.1f%cC [Cool]", temp, (char)223);
    wCount++;
  }
  if (!isSoilError(soil) && soil < soilThresholdMin) {
    warnings[wCount] = {"!TANAH KERING!", "", false};
    snprintf(warnings[wCount].value, 17, "%.0f%%  [Siram]", soil);
    wCount++;
  }
  if (wCount == 0) return;

  warningScreen %= wCount;
  lcd.clear();
  lcdPrintCenter(0, warnings[warningScreen].title);
  lcdPrintCenter(1, warnings[warningScreen].value);
  if (warnings[warningScreen].buzzer) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(100);
    digitalWrite(BUZZER_PIN, LOW);
  }
  warningScreen++;
}

// ============================================================
//  LCD: ROTATING DISPLAY
// ============================================================
void updateLCDRotating(float temp, float gas, float soil, const char *timeStr) {
  unsigned long now = millis();
  if (now - lastLCDUpdate < LCD_INTERVAL) return;
  lastLCDUpdate = now;
  lcd.clear();
  char buf[17];

  switch (lcdScreen) {
  case 0:
    lcdPrintCenter(0, "  [ SUHU ]");
    snprintf(buf, sizeof(buf), isTempError(temp) ? "  NO SENSOR" : "%.1f%cC | %s", temp, (char)223, timeStr);
    lcdPrintCenter(1, buf);
    break;
  case 1:
    lcdPrintCenter(0, " [ GAS ]");
    snprintf(buf, sizeof(buf), isGasError(gas) ? "  NO SENSOR" : "%.0f ppm", gas);
    lcdPrintCenter(1, buf);
    break;
  case 2:
    lcdPrintCenter(0, " [ TANAH ]");
    snprintf(buf, sizeof(buf), isSoilError(soil) ? "  NO SENSOR" : "Lembab: %.0f%%", soil);
    lcdPrintCenter(1, buf);
    break;
  case 3:
    snprintf(buf, sizeof(buf), "H:%d F:%d M:%d", heaterStatus, fanStatus, motorStatus);
    lcdPrintCenter(0, buf);
    snprintf(buf, sizeof(buf), "P1:%s P2:%s", p1Status ? "ON " : "OFF", p2Status ? "ON " : "OFF");
    lcdPrintCenter(1, buf);
    break;
  }
  lcdScreen = (lcdScreen + 1) % 4;
}

// ============================================================
//  SERIAL MONITOR — ditambah debug motor
// ============================================================
void printSerialMonitor(float temp, float gas, float soil, const char *timeStr) {
  Serial.println(F("\n=================================================="));
  Serial.print(F("     I-COMPOST v2.5.1-ESP32 | WIB: "));
  Serial.println(timeStr);
  Serial.println(F("=================================================="));
  Serial.print(F(" Suhu         : "));
  if (isTempError(temp)) Serial.println(F("NO SENSOR"));
  else { Serial.print(temp, 1); Serial.println(F(" C")); }
  Serial.print(F(" Gas          : "));
  if (isGasError(gas)) Serial.println(F("NO SENSOR"));
  else { Serial.print(gas, 1); Serial.println(F(" ppm")); }
  Serial.print(F(" Kelembaban   : "));
  if (isSoilError(soil)) Serial.println(F("NO SENSOR"));
  else { Serial.print(soil, 1); Serial.println(F(" %")); }

  Serial.println(F("--------------------------------------------------"));
  Serial.print(F(" Heater       : ")); Serial.println(heaterStatus ? F("ON") : F("OFF"));
  Serial.print(F(" Exhaust Fan  : ")); Serial.println(fanStatus ? F("ON") : F("OFF"));
  Serial.print(F(" Motor Aduk   : ")); Serial.println(motorStatus ? F("ON") : F("OFF"));
  Serial.print(F(" Pompa P1     : ")); Serial.println(p1Status ? F("ON") : F("OFF"));
  Serial.print(F(" Pompa P2     : ")); Serial.println(p2Status ? F("ON") : F("OFF"));

  // DEBUG: status motor jadwal
  Serial.print(F(" [DEBUG] motorEnabled=")); Serial.print(motorEnabled);
  Serial.print(F(", sessionActive=")); Serial.print(motorSessionActive);
  Serial.print(F(", pinState=")); Serial.println(digitalRead(MOTOR_PIN));

  Serial.println(F("=================================================="));
  Serial.print(F(" Heap: ")); Serial.print(ESP.getFreeHeap());
  Serial.print(F(" | WiFi: ")); Serial.println(WiFi.RSSI());
  Serial.println();
}

// ============================================================
//  ANIMATED OPENING
// ============================================================
void animatedOpening() {
  lcd.clear();
  lcd.createChar(0, blockChar);
  lcd.createChar(1, checkMark);
  lcd.setCursor(3, 0);
  const char *brand = "I-COMPOST";
  for (int i = 0; brand[i]; ++i) { lcd.print(brand[i]); delay(150); }
  delay(1000);
  lcd.setCursor(5, 1);
  const char *tag = "by PNJ";
  for (int i = 0; tag[i]; ++i) { lcd.print(tag[i]); delay(80); }
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
  lcdPrintCenter(0, "I-COMPOSTER");
  lcdPrintCenter(1, "v2.5.1 ESP32");
  delay(1500);
  lcd.clear();
  lcd.createChar(2, thermometer);
  lcd.createChar(3, droplet);
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

  // === PERBAIKAN: pastikan relay motor mati saat boot ===
  digitalWrite(MOTOR_PIN, RELAY2_OFF);
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

  Serial.println("\n[INFO] Kalibrasi terbaru:");
  Serial.println("  Soil   : DRY=" + String(SOIL_DRY_ADC) + " WET=" + String(SOIL_WET_ADC) + " (linear, turun saat basah)");
  Serial.println("  MQ-135 : R0=" + String(MQ135_R0, 1) + " kΩ (baseline udara bersih)");
  Serial.println("  DS18B20: retry 3x + kunci interrupt");
  Serial.println("  RTC    : selalu sync dari NTP jika WiFi tersambung");
  Serial.println("  Motor  : otomatis via jadwal Firebase (active HIGH)");
  Serial.println("  Chip   : ESP32 30-pin classic");
}

// ============================================================
//  LOOP UTAMA
// ============================================================
void loop() {
  unsigned long currentMs = millis();

  if (currentMs - lastFirebaseSync >= 5000UL) {
    lastFirebaseSync = currentMs;
    readFirebaseThresholds();
  }
  if (currentMs - lastControlRead >= 3000UL) {
    lastControlRead = currentMs;
    readFirebaseControls();
  }

  handlePumpTimers();
  handleMotorBuzzer();

  float temperature = readTemperature();
  float gasPPM = readMQ135ppm();
  float soilPercent = readSoilMoisture();

  DateTime nowUTC = rtc.now();
  DateTime nowWIB = nowUTC + TimeSpan(WIB_OFFSET_SEC);
  char timeString[9];
  sprintf(timeString, "%02d:%02d:%02d", nowWIB.hour(), nowWIB.minute(), nowWIB.second());
  int currentHour = nowWIB.hour();
  int currentMinute = nowWIB.minute();
  int currentDay = nowWIB.day();

  handleMotorSchedule(currentHour, currentMinute, currentDay);

  // Heater & Fan (otomatis berdasarkan threshold)
  heaterStatus = (!isTempError(temperature) && temperature < tempThresholdMin);
  gasHigh = (!isGasError(gasPPM) && gasPPM > gasThresholdMax);
  tempHigh = (!isTempError(temperature) && temperature > tempThresholdMax);
  fanStatus = (gasHigh || tempHigh);

  digitalWrite(HEATER_PIN, heaterStatus ? RELAY4_ON : RELAY4_OFF);
  digitalWrite(FAN_PIN, fanStatus ? RELAY4_ON : RELAY4_OFF);

  // Log actuator ke Firebase
  if (Firebase.ready()) {
    auto pushActuatorLog = [&](String name, bool status, String reason, float val) {
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
      pushActuatorLog("Heater", heaterStatus, heaterStatus ? "Suhu Terlalu Rendah" : "Suhu Sudah Normal", temperature);
      prevHeater = heaterStatus;
    }
    if (fanStatus != prevFan) {
      String reason = fanStatus ? ((gasHigh && tempHigh) ? "Bau & Suhu Tinggi" : (gasHigh ? "Kadar Bau Tinggi" : "Suhu Terlalu Tinggi")) : "Bau & Suhu Normal";
      pushActuatorLog("Exhaust Fan", fanStatus, reason, (gasHigh ? gasPPM : temperature));
      prevFan = fanStatus;
    }
    if (p1Status != prevP1) {
      pushActuatorLog("Pompa P1", p1Status, p1Status ? "Dinyalakan dari App" : "Selesai / Dimatikan", soilPercent);
      prevP1 = p1Status;
    }
    if (p2Status != prevP2) {
      pushActuatorLog("Pompa P2", p2Status, p2Status ? "Dinyalakan dari App" : "Selesai / Dimatikan", 0.0f);
      prevP2 = p2Status;
    }
    if (motorStatus != prevMotor) {
      pushActuatorLog("Motor Aduk", motorStatus, motorStatus ? "Manual ON" : "Manual OFF", 0.0f);
      prevMotor = motorStatus;
    }
  }

  // Warning mode
  warningMode = (!isGasError(gasPPM) && gasPPM > gasThresholdMax) ||
                (!isTempError(temperature) && temperature < tempThresholdMin) ||
                (!isTempError(temperature) && temperature > tempThresholdMax) ||
                (!isSoilError(soilPercent) && soilPercent < soilThresholdMin);

  if (warningMode) updateLCDWithWarning(gasPPM, temperature, soilPercent);
  else {
    warningScreen = 0;
    updateLCDRotating(temperature, gasPPM, soilPercent, timeString);
  }

  // Upload data ke Firebase
  if (currentMs - lastDataUpload >= 2000UL) {
    lastDataUpload = currentMs;
    printSerialMonitor(temperature, gasPPM, soilPercent, timeString);

    ++packetId;

    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("[FB] WiFi terputus — skip upload");
    } else if (!Firebase.ready()) {
      Serial.println("[FB] Firebase belum ready — skip upload");
    } else {
      FirebaseJson json;
      json.set("temperature", isTempError(temperature) ? -1.0f : temperature);
      json.set("gas", isGasError(gasPPM) ? -1.0f : gasPPM);
      json.set("soil", isSoilError(soilPercent) ? -1.0f : soilPercent);
      json.set("time", timeString);
      json.set("unix_time", (double)nowUTC.unixtime());
      json.set("actuators/heater", heaterStatus);
      json.set("actuators/fan", fanStatus);
      json.set("actuators/motor", motorStatus);
      json.set("actuators/p1", p1Status);
      json.set("actuators/p2", p2Status);

      float packetLossPct = 0.0f;
      if (qosTotalSent > 0) packetLossPct = ((float)qosTotalFailed / (float)qosTotalSent) * 100.0f;

      json.set("qos/delay_ms", qosLastDelayMs);
      json.set("qos/throughput_bps", qosLastThroughputBps);
      json.set("qos/jitter_ms", qosLastJitterMs);
      json.set("qos/packet_loss_pct", packetLossPct);
      json.set("qos/free_heap", (uint32_t)ESP.getFreeHeap());
      json.set("qos/uptime_ms", (uint32_t)millis());
      json.set("qos/packet_id", packetId);

      String jsonStr;
      json.toString(jsonStr, false);
      size_t payloadSize = jsonStr.length() + 300;

      unsigned long startSend = millis();
      bool ok = Firebase.RTDB.updateNode(&fbdo, "/komposter", &json);
      unsigned long endSend = millis();

      qosTotalSent++;

      if (ok) {
        float currentDelayMs = (float)(endSend - startSend);
        if (qosLastDelayMs > 0) qosLastJitterMs = fabs(currentDelayMs - qosLastDelayMs);
        else qosLastJitterMs = 0;
        float delaySeconds = currentDelayMs / 1000.0f;
        if (delaySeconds > 0) qosLastThroughputBps = ((float)payloadSize / delaySeconds);
        qosLastDelayMs = currentDelayMs;
        Serial.println("[FB] Upload OK. Delay: " + String(currentDelayMs, 0) + "ms | Jitter: " + String(qosLastJitterMs, 0) + "ms | Throughput: " + String(qosLastThroughputBps, 1) + " Bps");
      } else {
        qosTotalFailed++;
        Serial.println("[FB] Upload GAGAL: " + fbdo.errorReason());
      }

      if (currentMs - lastHistoryPush >= 60000UL) {
        lastHistoryPush = currentMs;
        Firebase.RTDB.pushJSON(&fbdo, "/komposter_logs", &json);
      }
    }
  }

  // WiFi reconnect
  static unsigned long lastWifiCheck = 0;
  static bool wifiWasDisconnected = false;
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
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }
  } else {
    if (wifiWasDisconnected) {
      wifiWasDisconnected = false;
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