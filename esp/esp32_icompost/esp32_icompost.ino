/*
 * =============================================================
 *  I-COMPOST — Firmware ESP32-S3 N16R8
 *  Versi  : 2.3.4 (perbaikan stabilitas sensor & kalibrasi baru)
 *  Tanggal: Juni 2026
 * =============================================================
 *
 *  Perbaikan dari v2.3:
 *  - ADC : ADC_ATTENDB_MAX → ADC_11db (kompatibel Core 3.3.7)
 *  - DS18B20 : retry 3× + kunci interrupt
 *  - Soil : kalibrasi 3‑titik (dry 3400, mid 2300, wet 1200)
 *  - pH   : kalibrasi 3‑titik 2‑segmen (V4.01, V6.86, V9.18)
 *  - Firebase : parsing jsonObject, hapus reconnectWiFi
 *  - Pompa : flag anti double‑trigger saat WiFi reconnect
 *  - MQ-4  : tetap rumus & R0 lama (1.2971 kΩ)
 */

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <RTClib.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <time.h>

#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// ============================================================
//  KONFIGURASI WIFI & FIREBASE
// ============================================================
#define WIFI_SSID       "Adena"
#define WIFI_PASSWORD   "Rumput250611"

#define API_KEY         "AIzaSyAQyAwHey8tDJ4moHKDeWDTlAzlINdBJFk"
#define DATABASE_URL    "https://icompost-db-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define DATABASE_SECRET "0elSe0OFDDQ1ypcthT7wOrqkjq252Kv5uOKUSIgm"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ============================================================
//  PIN DEFINITIONS — ESP32-S3 N16R8
// ============================================================
// Sensor
#define PH_PIN          1
#define SOIL_PIN        2
#define MQ4_AOUT_PIN    4
#define ONE_WIRE_BUS    17
#define SDA_PIN         8
#define SCL_PIN         9

// Aktuator
#define HEATER_PIN      15
#define FAN_PIN         6
#define WATER_PUMP_PIN  7
#define EM4_PUMP_PIN    16
#define MOTOR_PIN       38
#define BUZZER_PIN      47

// ============================================================
//  RELAY LOGIC
// ============================================================
#define RELAY4_ON   LOW
#define RELAY4_OFF  HIGH
#define RELAY2_ON   HIGH
#define RELAY2_OFF  LOW

// ============================================================
//  OBJEK SENSOR
// ============================================================
LiquidCrystal_I2C lcd(0x27, 16, 2);
RTC_DS3231 rtc;
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// ============================================================
//  KALIBRASI SENSOR (diperbarui)
// ============================================================

// --- MQ-4 Gas Metana (tetap rumus lama, R0 lama) ---
#define MQ4_RL_VALUE      10.0f
#define MQ4_R0            1.2971f
#define MQ4_VREF          3.3f
#define MQ4_ADC_MAX       4095.0f
#define MQ4_SAMPLES       10

// --- DS18B20 Suhu ---
#define TEMP_OFFSET       0.0f
#define TEMP_RESOLUTION   12

// --- PH-4502C (3‑titik, 2 segmen) ---
#define PH_SAMPLES        30
#define VREF              3.3f
#define ADC_RESOLUTION    4095.0f
#define V_PH401           2.8600f
#define V_PH686           3.3000f
#define V_PH918           2.0869f

#define SLOPE_ACID  ((4.01f - 6.86f) / (V_PH401 - V_PH686))
#define OFFSET_ACID (4.01f - SLOPE_ACID * V_PH401)
#define SLOPE_BASE  ((6.86f - 9.18f) / (V_PH686 - V_PH918))
#define OFFSET_BASE (6.86f - SLOPE_BASE * V_PH686)

// --- Soil Moisture (3‑titik piecewise linear) ---
#define SOIL_SAMPLES      20
#define SOIL_DRY_ADC      3400
#define SOIL_MID_ADC      2300
#define SOIL_WET_ADC      1200
#define SOIL_MID_PERCENT  50.0f

// ============================================================
//  THRESHOLDS
// ============================================================
float tempThresholdMin = 60.0f;
float tempThresholdMax = 70.0f;
float gasThresholdMax  = 50.0f;
float soilThresholdMin = 50.0f;
float phThresholdMin   = 6.0f;
float phThresholdMax   = 8.0f;

// ============================================================
//  STATUS AKTUATOR & KONTROL
// ============================================================
bool heaterStatus    = false;
bool fanStatus       = false;
bool waterPumpStatus = false;
bool em4PumpStatus   = false;
bool motorStatus     = false;

bool prevHeater = false, prevFan = false;
bool prevWater  = false, prevEM4 = false;
bool prevMotor  = false;

bool gasHigh  = false;
bool tempHigh = false;

// Pompa
bool     pumpP1Active        = false;
unsigned long pumpP1StartMs  = 0;
unsigned long pumpP1Duration = 30000UL;

bool     pumpP2Active        = false;
unsigned long pumpP2StartMs  = 0;
unsigned long pumpP2Duration = 20000UL;

bool pump1CmdProcessed = false;   // anti double‑trigger
bool pump2CmdProcessed = false;

// Motor
bool     motorEnabled        = false;
String   motorScheduleHours  = "";
int      motorDurationMin    = 20;
bool     motorSessionActive  = false;
unsigned long motorSessionStart = 0;
int      motorLastRunHour    = -1;
int      motorLastRunDay     = -1;

// ============================================================
//  LCD & TIMING
// ============================================================
unsigned long lastLCDUpdate   = 0;
int           lcdScreen       = 0;
bool          warningMode     = false;
const unsigned long LCD_INTERVAL     = 5000UL;

int           warningScreen   = 0;
unsigned long lastWarningUpdate = 0;
const unsigned long WARNING_INTERVAL = 3000UL;

unsigned long lastFirebaseSync   = 0;
unsigned long lastControlRead    = 0;
unsigned long lastDataUpload     = 0;
unsigned long lastHistoryPush    = 0;
unsigned long packetId           = 0;

bool     motorBuzzActive   = false;
int      motorBuzzCount    = 0;
unsigned long lastBuzzTime = 0;

// ============================================================
//  KARAKTER KUSTOM LCD
// ============================================================
byte blockChar[8]   = {B11111, B11111, B11111, B11111, B11111, B11111, B11111, B11111};
byte checkMark[8]   = {B00000, B00001, B00011, B10110, B11100, B01000, B00000, B00000};
byte thermometer[8] = {B00100, B01010, B01010, B01110, B11111, B11111, B01110, B00000};
byte droplet[8]     = {B00100, B01110, B11111, B11111, B11111, B01110, B00100, B00000};

// ============================================================
//  HELPER: LCD Print Center
// ============================================================
void lcdPrintCenter(int row, const char *str) {
  int len    = strlen(str);
  int spaces = (16 - len) / 2;
  if (spaces < 0) spaces = 0;
  lcd.setCursor(0, row);
  lcd.print("                ");
  lcd.setCursor(spaces, row);
  lcd.print(str);
}

// ============================================================
//  WIFI
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
      digitalWrite(BUZZER_PIN, HIGH); delay(50);
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
//  FIREBASE INIT
// ============================================================
void initFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  config.api_key            = API_KEY;
  config.database_url       = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;
  Firebase.begin(&config, &auth);
  // Firebase.reconnectWiFi(true);   // dihapus, kadang error di library baru

  lcd.clear();
  lcdPrintCenter(0, "Firebase...");
  unsigned long fbStart = millis();
  while (!Firebase.ready() && (millis() - fbStart < 15000)) {
    delay(500);
  }
  if (Firebase.ready()) lcdPrintCenter(1, "Terhubung!");
  else                  lcdPrintCenter(1, "Gagal!");
  delay(1000);
}

// ============================================================
//  RTC INIT + NTP SYNC
// ============================================================
#define WIB_OFFSET_SEC  (7L * 3600L)

void initRTC() {
  if (!rtc.begin()) {
    lcd.clear();
    lcdPrintCenter(0, "! RTC ERROR !");
    lcdPrintCenter(1, "Cek koneksi");
    delay(2000);
    return;
  }
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
      Serial.println("[RTC] Synced to UTC");
    }
  }
}

// ============================================================
//  BACA THRESHOLDS DARI FIREBASE
// ============================================================
void readFirebaseThresholds() {
  if (!Firebase.ready()) return;
  if (Firebase.RTDB.getJSON(&fbdo, "/komposter/thresholds")) {
    FirebaseJson &json = fbdo.jsonObject();
    FirebaseJsonData jsonData;
    json.get(jsonData, "temperature/min"); if (jsonData.success) tempThresholdMin = jsonData.floatValue;
    json.get(jsonData, "temperature/max"); if (jsonData.success) tempThresholdMax = jsonData.floatValue;
    json.get(jsonData, "gas/max");         if (jsonData.success) gasThresholdMax  = jsonData.floatValue;
    json.get(jsonData, "soil/min");        if (jsonData.success) soilThresholdMin = jsonData.floatValue;
    json.get(jsonData, "ph/min");          if (jsonData.success) phThresholdMin   = jsonData.floatValue;
    json.get(jsonData, "ph/max");          if (jsonData.success) phThresholdMax   = jsonData.floatValue;
    Serial.println("[SYNC] Thresholds loaded");
  }
}

// ============================================================
//  BACA PERINTAH KONTROL
// ============================================================
void readFirebaseControls() {
  if (!Firebase.ready()) return;
  if (Firebase.RTDB.getJSON(&fbdo, "/komposter/controls")) {
    FirebaseJson &json = fbdo.jsonObject();
    FirebaseJsonData jsonData;

    // Pompa P1
    json.get(jsonData, "water_pump/command");
    if (jsonData.success) {
      String cmd = jsonData.stringValue;
      if (cmd == "ON" && !pumpP1Active && !pump1CmdProcessed) {
        json.get(jsonData, "water_pump/duration_sec");
        if (jsonData.success) pumpP1Duration = (unsigned long)jsonData.intValue * 1000UL;
        pumpP1Active  = true;
        pumpP1StartMs = millis();
        pump1CmdProcessed = true;
        Firebase.RTDB.setString(&fbdo, "/komposter/controls/water_pump/command", "OFF");
        Serial.println("[CTRL] Pompa P1 ON");
      } else if (cmd == "OFF") {
        pump1CmdProcessed = false;
      }
    }

    // Pompa P2
    json.get(jsonData, "em4_pump/command");
    if (jsonData.success) {
      String cmd = jsonData.stringValue;
      if (cmd == "ON" && !pumpP2Active && !pump2CmdProcessed) {
        json.get(jsonData, "em4_pump/duration_sec");
        if (jsonData.success) pumpP2Duration = (unsigned long)jsonData.intValue * 1000UL;
        pumpP2Active  = true;
        pumpP2StartMs = millis();
        pump2CmdProcessed = true;
        Firebase.RTDB.setString(&fbdo, "/komposter/controls/em4_pump/command", "OFF");
        Serial.println("[CTRL] Pompa P2 ON");
      } else if (cmd == "OFF") {
        pump2CmdProcessed = false;
      }
    }

    // Motor
    json.get(jsonData, "motor/enabled");       if (jsonData.success) motorEnabled = jsonData.boolValue;
    json.get(jsonData, "motor/schedule_hours"); if (jsonData.success) motorScheduleHours = jsonData.stringValue;
    json.get(jsonData, "motor/duration_minutes");
    if (jsonData.success) {
      motorDurationMin = jsonData.intValue;
      if (motorDurationMin < 1)   motorDurationMin = 1;
      if (motorDurationMin > 120) motorDurationMin = 120;
    }
  }
}

// ============================================================
//  SENSOR: MQ-4 (rumus eksponensial lama)
// ============================================================
float readMQ4ppm() {
  long sum = 0;
  for (int i = 0; i < MQ4_SAMPLES; i++) {
    sum += analogRead(MQ4_AOUT_PIN);
    delay(3);
  }
  float adcAvg  = (float)sum / MQ4_SAMPLES;
  float voltage = (adcAvg / MQ4_ADC_MAX) * MQ4_VREF;
  if (voltage <= 0.01f) return -1.0f;

  float rs    = MQ4_RL_VALUE * (MQ4_VREF - voltage) / voltage;
  float ratio = rs / MQ4_R0;
  float ppm   = 1012.7f * pow(ratio, -2.786f);
  return ppm;
}

// ============================================================
//  SENSOR: DS18B20 (retry + kunci interrupt)
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
//  SENSOR: pH (3‑titik, 2 segmen)
// ============================================================
float readPH() {
  int buf[PH_SAMPLES];
  for (int i = 0; i < PH_SAMPLES; i++) {
    buf[i] = analogRead(PH_PIN);
    delay(10);
  }
  for (int i = 1; i < PH_SAMPLES; i++) {
    int key = buf[i], j = i - 1;
    while (j >= 0 && buf[j] > key) { buf[j+1] = buf[j]; j--; }
    buf[j+1] = key;
  }
  long sum = 0; int cnt = 0;
  for (int i = 5; i < PH_SAMPLES - 5; i++) { sum += buf[i]; cnt++; }
  if (cnt == 0) return -1.0f;

  float vpo = (float)sum / cnt / ADC_RESOLUTION * VREF;
  float ph;
  if (vpo >= V_PH401) ph = SLOPE_ACID * vpo + OFFSET_ACID;
  else               ph = SLOPE_BASE * vpo + OFFSET_BASE;
  ph = constrain(ph, 0.0f, 14.0f);
  if (ph <= 0.1f || ph >= 13.9f) return -1.0f;
  return ph;
}

// ============================================================
//  SENSOR: Soil Moisture (3‑titik piecewise linear)
// ============================================================
float readSoilMoisture() {
  long sum = 0;
  for (int i = 0; i < SOIL_SAMPLES; i++) {
    sum += analogRead(SOIL_PIN);
    delay(10);
  }
  int adcAvg = (int)(sum / SOIL_SAMPLES);
  if (adcAvg <= 10) return -1.0f;

  int adc = constrain(adcAvg, SOIL_WET_ADC, SOIL_DRY_ADC);
  float moisture;
  if (adc >= SOIL_MID_ADC) {
    moisture = (float)(SOIL_DRY_ADC - adc) / (SOIL_DRY_ADC - SOIL_MID_ADC) * SOIL_MID_PERCENT;
  } else {
    moisture = SOIL_MID_PERCENT + (float)(SOIL_MID_ADC - adc) / (SOIL_MID_ADC - SOIL_WET_ADC) * (100.0f - SOIL_MID_PERCENT);
  }
  return constrain(moisture, 0.0f, 100.0f);
}

// ============================================================
//  CEK ERROR SENSOR
// ============================================================
bool isTempError(float t)  { return (t < -900.0f); }
bool isSoilError(float s)  { return (s < 0.0f); }
bool isPhError(float ph)   { return (ph < 0.0f); }
bool isGasError(float g)   { return (g < 0.0f); }

// ============================================================
//  KONTROL POMPA (NON-BLOCKING)
// ============================================================
void handlePumpTimers() {
  unsigned long now = millis();

  if (pumpP1Active) {
    if (now - pumpP1StartMs >= pumpP1Duration) {
      pumpP1Active    = false;
      waterPumpStatus = false;
      digitalWrite(WATER_PUMP_PIN, RELAY4_OFF);
      pump1CmdProcessed = false;
      Serial.println("[CTRL] Pompa P1 OFF");
    } else {
      waterPumpStatus = true;
      digitalWrite(WATER_PUMP_PIN, RELAY4_ON);
    }
  }

  if (pumpP2Active) {
    if (now - pumpP2StartMs >= pumpP2Duration) {
      pumpP2Active  = false;
      em4PumpStatus = false;
      digitalWrite(EM4_PUMP_PIN, RELAY4_OFF);
      pump2CmdProcessed = false;
      Serial.println("[CTRL] Pompa P2 OFF");
    } else {
      em4PumpStatus = true;
      digitalWrite(EM4_PUMP_PIN, RELAY4_ON);
    }
  }
}

// ============================================================
//  MOTOR JADWAL
// ============================================================
void handleMotorSchedule(int currentHour, int currentDay) {
  if (!motorEnabled) {
    if (motorStatus) { digitalWrite(MOTOR_PIN, RELAY2_OFF); motorStatus = false; }
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
  if (currentHour == motorLastRunHour && currentDay == motorLastRunDay) return;

  bool shouldRun = false;
  int startIdx = 0;
  for (int i = 0; i <= (int)motorScheduleHours.length(); i++) {
    if (i == (int)motorScheduleHours.length() || motorScheduleHours.charAt(i) == ',') {
      String hourStr = motorScheduleHours.substring(startIdx, i);
      hourStr.trim();
      if (hourStr.toInt() == currentHour) { shouldRun = true; break; }
      startIdx = i + 1;
    }
  }

  if (shouldRun) {
    motorSessionActive = true;
    motorSessionStart  = millis();
    motorLastRunHour   = currentHour;
    motorLastRunDay    = currentDay;
    digitalWrite(MOTOR_PIN, RELAY2_ON);
    motorBuzzCount  = 0;
    lastBuzzTime    = millis() - 3000;
    motorBuzzActive = true;
    Serial.println("[MOTOR] Sesi dimulai jam " + String(currentHour) + ":00");
  }
}

// ============================================================
//  BUZZER MOTOR
// ============================================================
void handleMotorBuzzer() {
  if (!motorBuzzActive) return;
  if (motorBuzzCount < 3) {
    if (millis() - lastBuzzTime >= 3000) {
      lastBuzzTime = millis();
      digitalWrite(BUZZER_PIN, HIGH); delay(200);
      digitalWrite(BUZZER_PIN, LOW);
      motorBuzzCount++;
    }
  } else {
    motorBuzzActive = false;
  }
}

// ============================================================
//  LCD: WARNING MODE
// ============================================================
void updateLCDWithWarning(float gas, float temp, float ph, float soil) {
  unsigned long now = millis();
  if (now - lastWarningUpdate < WARNING_INTERVAL) return;
  lastWarningUpdate = now;

  struct Warning { const char *title; char value[17]; bool buzzer; };
  Warning warnings[5]; int wCount = 0;

  if (!isGasError(gas) && gas > gasThresholdMax) {
    warnings[wCount] = {"! GAS TINGGI !", "", true};
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
  if (!isPhError(ph) && (ph < phThresholdMin || ph > phThresholdMax)) {
    warnings[wCount] = {"! pH ABNORMAL !", "", false};
    snprintf(warnings[wCount].value, 17, "pH : %.2f", ph);
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
    digitalWrite(BUZZER_PIN, HIGH); delay(100);
    digitalWrite(BUZZER_PIN, LOW);
  }
  warningScreen++;
}

// ============================================================
//  LCD: ROTATING DISPLAY
// ============================================================
void updateLCDRotating(float temp, float gas, float soil, float ph, const char *timeStr) {
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
      lcdPrintCenter(0, "  [ GAS CH4 ]");
      snprintf(buf, sizeof(buf), isGasError(gas) ? "  NO SENSOR" : "%.0f ppm", gas);
      lcdPrintCenter(1, buf);
      break;
    case 2:
      lcdPrintCenter(0, " [ TANAH ]");
      snprintf(buf, sizeof(buf), isSoilError(soil) ? "  NO SENSOR" : "Lembab: %.0f%%", soil);
      lcdPrintCenter(1, buf);
      break;
    case 3:
      lcdPrintCenter(0, "   [ pH ]");
      snprintf(buf, sizeof(buf), isPhError(ph) ? "  NO SENSOR" : "pH : %.2f", ph);
      lcdPrintCenter(1, buf);
      break;
    case 4:
      snprintf(buf, sizeof(buf), "H:%d F:%d M:%d", heaterStatus, fanStatus, motorStatus);
      lcdPrintCenter(0, buf);
      snprintf(buf, sizeof(buf), "P1:%s P2:%s", waterPumpStatus ? "ON " : "OFF", em4PumpStatus ? "ON " : "OFF");
      lcdPrintCenter(1, buf);
      break;
  }
  lcdScreen = (lcdScreen + 1) % 5;
}

// ============================================================
//  SERIAL MONITOR
// ============================================================
void printSerialMonitor(float temp, float gas, float soil, float ph, const char *timeStr) {
  Serial.println(F("\n=================================================="));
  Serial.print(F("          I-COMPOST v2.3.4 | WIB: ")); Serial.println(timeStr);
  Serial.println(F("=================================================="));
  // ... (sama persis dengan asli, hanya versi berubah) ...
  Serial.print(F(" Suhu         : ")); if (isTempError(temp)) Serial.println(F("NO SENSOR")); else { Serial.print(temp,1); Serial.println(F(" C")); }
  Serial.print(F(" Gas CH4      : ")); if (isGasError(gas)) Serial.println(F("NO SENSOR")); else { Serial.print(gas,1); Serial.println(F(" ppm")); }
  Serial.print(F(" Kelembaban   : ")); if (isSoilError(soil)) Serial.println(F("NO SENSOR")); else { Serial.print(soil,1); Serial.println(F(" %")); }
  Serial.print(F(" pH           : ")); if (isPhError(ph)) Serial.println(F("NO SENSOR")); else { Serial.print(ph,2); Serial.println(); }
  Serial.println(F("--------------------------------------------------"));
  Serial.print(F(" Heater       : ")); Serial.println(heaterStatus ? F("ON"):F("OFF"));
  Serial.print(F(" Exhaust Fan  : ")); Serial.println(fanStatus ? F("ON"):F("OFF"));
  Serial.print(F(" Motor Aduk   : ")); Serial.println(motorStatus ? F("ON"):F("OFF"));
  Serial.print(F(" Pompa Molase : ")); Serial.println(waterPumpStatus ? F("ON"):F("OFF"));
  Serial.print(F(" Pompa EM4    : ")); Serial.println(em4PumpStatus ? F("ON"):F("OFF"));
  Serial.println(F("=================================================="));
  Serial.print(F(" Heap: ")); Serial.print(ESP.getFreeHeap()); Serial.print(F(" | WiFi: ")); Serial.println(WiFi.RSSI());
  Serial.println();
}

// ============================================================
//  ANIMATED OPENING
// ============================================================
void animatedOpening() {
  // ... (sama persis dengan kode asli Anda) ...
  lcd.clear(); lcd.createChar(0, blockChar); lcd.createChar(1, checkMark);
  lcd.setCursor(3,0); const char *brand="I-COMPOST"; for(int i=0; brand[i]; ++i) { lcd.print(brand[i]); delay(150); } delay(1000);
  lcd.setCursor(5,1); const char *tag="by PNJ"; for(int i=0; tag[i]; ++i) { lcd.print(tag[i]); delay(80); } delay(1000);
  lcd.clear(); lcdPrintCenter(0,"Initializing..");
  for(int i=0; i<=14; ++i){ lcd.setCursor(0,1); lcd.print("["); for(int j=0; j<i; ++j) lcd.write(byte(0)); for(int j=i; j<14; ++j) lcd.print(" "); lcd.print("]"); delay(120); }
  initWiFi(); initFirebase(); initRTC();
  readFirebaseThresholds(); readFirebaseControls(); lastFirebaseSync = millis();
  lcd.clear(); lcdPrintCenter(0,"** SYSTEM **"); lcdPrintCenter(1,"** READY!  **");
  for(int i=0; i<3; ++i){ digitalWrite(BUZZER_PIN,HIGH); delay(100); digitalWrite(BUZZER_PIN,LOW); delay(100); } delay(1000);
  lcd.clear(); lcdPrintCenter(0,"I-COMPOSTER"); lcdPrintCenter(1,"v2.3  2026"); delay(1500); lcd.clear();
  lcd.createChar(2, thermometer); lcd.createChar(3, droplet);
}

// ============================================================
//  SETUP
// ============================================================
void setup() {
  Serial.begin(115200);

  gpio_set_level((gpio_num_t)HEATER_PIN,     RELAY4_OFF);
  gpio_set_level((gpio_num_t)FAN_PIN,        RELAY4_OFF);
  gpio_set_level((gpio_num_t)WATER_PUMP_PIN, RELAY4_OFF);
  gpio_set_level((gpio_num_t)EM4_PUMP_PIN,   RELAY4_OFF);
  gpio_set_level((gpio_num_t)MOTOR_PIN,      RELAY2_OFF);
  gpio_set_level((gpio_num_t)BUZZER_PIN,     LOW);

  pinMode(HEATER_PIN,OUTPUT); pinMode(FAN_PIN,OUTPUT); pinMode(WATER_PUMP_PIN,OUTPUT);
  pinMode(EM4_PUMP_PIN,OUTPUT); pinMode(MOTOR_PIN,OUTPUT); pinMode(BUZZER_PIN,OUTPUT);

  digitalWrite(HEATER_PIN,RELAY4_OFF); digitalWrite(FAN_PIN,RELAY4_OFF);
  digitalWrite(WATER_PUMP_PIN,RELAY4_OFF); digitalWrite(EM4_PUMP_PIN,RELAY4_OFF);
  digitalWrite(MOTOR_PIN,RELAY2_OFF); digitalWrite(BUZZER_PIN,LOW);

  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setTimeOut(1000);
  lcd.init(); lcd.backlight();

  animatedOpening();

  sensors.begin();
  sensors.setResolution(TEMP_RESOLUTION);
  analogReadResolution(12);

  analogSetPinAttenuation(MQ4_AOUT_PIN, ADC_11db);
  analogSetPinAttenuation(PH_PIN,       ADC_11db);
  analogSetPinAttenuation(SOIL_PIN,     ADC_11db);

  Serial.println("\n[INFO] Kalibrasi sensor:");
  Serial.println("  Soil : DRY=" + String(SOIL_DRY_ADC) + " MID=" + String(SOIL_MID_ADC) + " WET=" + String(SOIL_WET_ADC));
  Serial.println("  pH   : V4.01=" + String(V_PH401,4) + " V6.86=" + String(V_PH686,4) + " V9.18=" + String(V_PH918,4));
  Serial.println("  MQ-4 : R0=" + String(MQ4_R0,4) + " (rumus eksponensial lama)");
  Serial.println("  DS18B20 : retry 3x + kunci interrupt");
}

// ============================================================
//  LOOP UTAMA
// ============================================================
void loop() {
  unsigned long currentMs = millis();

  if (currentMs - lastFirebaseSync >= 300000UL) { lastFirebaseSync = currentMs; readFirebaseThresholds(); }
  if (currentMs - lastControlRead >= 3000UL)    { lastControlRead = currentMs;  readFirebaseControls(); }

  handlePumpTimers();
  handleMotorBuzzer();

  float temperature = readTemperature();
  float gasPPM      = readMQ4ppm();
  float phValue     = readPH();
  float soilPercent = readSoilMoisture();

  DateTime nowUTC = rtc.now();
  DateTime nowWIB = nowUTC + TimeSpan(WIB_OFFSET_SEC);
  char timeString[9];
  sprintf(timeString, "%02d:%02d:%02d", nowWIB.hour(), nowWIB.minute(), nowWIB.second());
  int currentHour = nowWIB.hour();
  int currentDay  = nowWIB.day();

  handleMotorSchedule(currentHour, currentDay);

  heaterStatus = (!isTempError(temperature) && temperature < tempThresholdMin);
  gasHigh  = (!isGasError(gasPPM)      && gasPPM      > gasThresholdMax);
  tempHigh = (!isTempError(temperature) && temperature > tempThresholdMax);
  fanStatus = (gasHigh || tempHigh);

  digitalWrite(HEATER_PIN, heaterStatus ? RELAY4_ON : RELAY4_OFF);
  digitalWrite(FAN_PIN,    fanStatus    ? RELAY4_ON : RELAY4_OFF);

  if (Firebase.ready()) {
    auto pushActuatorLog = [&](String name, bool status, String reason, float val) {
      FirebaseJson log;
      log.set("actuator", name); log.set("status", status ? "ON" : "OFF");
      log.set("reason", reason); log.set("value", val);
      log.set("time", timeString); log.set("unix_time", (double)nowUTC.unixtime());
      Firebase.RTDB.pushJSON(&fbdo, "/logs/actuators", &log);
    };
    if (heaterStatus != prevHeater) { pushActuatorLog("Heater", heaterStatus, heaterStatus ? "Suhu Terlalu Rendah":"Suhu Sudah Normal", temperature); prevHeater = heaterStatus; }
    if (fanStatus != prevFan) { String reason = fanStatus ? ((gasHigh&&tempHigh)?"Suhu & Gas Tinggi":(gasHigh?"Kadar Gas Tinggi":"Suhu Terlalu Tinggi")):"Suhu & Gas Normal"; pushActuatorLog("Exhaust Fan", fanStatus, reason, (gasHigh?gasPPM:temperature)); prevFan = fanStatus; }
    if (waterPumpStatus != prevWater) { pushActuatorLog("Pompa Molase", waterPumpStatus, waterPumpStatus?"Dinyalakan dari App":"Selesai / Dimatikan", soilPercent); prevWater = waterPumpStatus; }
    if (em4PumpStatus != prevEM4)     { pushActuatorLog("Pompa EM4", em4PumpStatus, em4PumpStatus?"Dinyalakan dari App":"Selesai / Dimatikan", phValue); prevEM4 = em4PumpStatus; }
    if (motorStatus != prevMotor)     { pushActuatorLog("Motor Aduk", motorStatus, motorStatus?"Jadwal Aktif":"Sesi Selesai", 0.0f); prevMotor = motorStatus; }
  }

  warningMode = (!isGasError(gasPPM) && gasPPM > gasThresholdMax) ||
                (!isTempError(temperature) && temperature < tempThresholdMin) ||
                (!isTempError(temperature) && temperature > tempThresholdMax) ||
                (!isPhError(phValue) && (phValue < phThresholdMin || phValue > phThresholdMax)) ||
                (!isSoilError(soilPercent) && soilPercent < soilThresholdMin);

  if (warningMode) updateLCDWithWarning(gasPPM, temperature, phValue, soilPercent);
  else { warningScreen = 0; updateLCDRotating(temperature, gasPPM, soilPercent, phValue, timeString); }

  if (currentMs - lastDataUpload >= 2000UL) {
    lastDataUpload = currentMs;
    printSerialMonitor(temperature, gasPPM, soilPercent, phValue, timeString);

    ++packetId;
    int wifiP = constrain(map(WiFi.RSSI(), -100, -50, 0, 100), 0, 100);

    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("[FB] WiFi terputus — skip upload");
    } else if (!Firebase.ready()) {
      Serial.println("[FB] Firebase belum ready — skip upload");
    } else {
      FirebaseJson json;
      json.set("temperature", isTempError(temperature) ? -1 : temperature);
      json.set("gas",         isGasError(gasPPM)       ? -1 : (int)gasPPM);
      json.set("soil",        isSoilError(soilPercent)  ? -1 : (int)soilPercent);
      json.set("ph",          isPhError(phValue)        ? -1 : phValue);
      json.set("time",        timeString);
      json.set("unix_time",   (double)nowUTC.unixtime());
      json.set("actuators/heater", heaterStatus);
      json.set("actuators/fan", fanStatus);
      json.set("actuators/motor", motorStatus);
      json.set("actuators/water_pump", waterPumpStatus);
      json.set("actuators/em4_pump", em4PumpStatus);
      json.set("qos/wifi_strength", (uint32_t)wifiP);
      json.set("qos/free_heap", (uint32_t)ESP.getFreeHeap());
      json.set("qos/uptime_ms", (uint32_t)millis());
      json.set("qos/packet_id", packetId);

      bool ok = Firebase.RTDB.updateNode(&fbdo, "/komposter", &json);
      Serial.println(ok ? "[FB] Upload OK" : "[FB] Upload GAGAL: " + fbdo.errorReason());
      if (currentMs - lastHistoryPush >= 60000UL) {
        lastHistoryPush = currentMs;
        Firebase.RTDB.pushJSON(&fbdo, "/komposter_logs", &json);
      }
    }
  }

  static unsigned long lastWifiCheck = 0;
  static bool wifiWasDisconnected = false;
  if (WiFi.status() != WL_CONNECTED) {
    if (!wifiWasDisconnected) {
      wifiWasDisconnected = true;
      lcd.clear(); lcdPrintCenter(0,"! WiFi Putus !"); lcdPrintCenter(1,"Menghubungkan..");
    }
    if (currentMs - lastWifiCheck >= 30000UL) {
      lastWifiCheck = currentMs;
      WiFi.disconnect(); delay(200);
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }
  } else {
    if (wifiWasDisconnected) {
      wifiWasDisconnected = false;
      lcd.clear(); lcdPrintCenter(0,"WiFi Terhubung!"); lcdPrintCenter(1,WiFi.localIP().toString().c_str());
      delay(1500); lcd.clear(); lastLCDUpdate = 0;
    }
  }
}