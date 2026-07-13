import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class CsvExportHelper {
  // ============================================================
  //  HELPER: Simpan langsung ke folder Download
  // ============================================================
  static Future<bool> _saveToDownloads(
    BuildContext context,
    String fileName,
    List<int> bytes,
  ) async {
    try {
      // Minta izin storage (diperlukan untuk Android < 10)
      if (Platform.isAndroid) {
        // Coba cek versi Android
        final sdkInt = await _getAndroidSdkInt();

        if (sdkInt != null && sdkInt >= 30) {
          // Android 11+ : gunakan manageExternalStorage
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
          }
          if (!status.isGranted) {
            // Fallback: coba langsung tanpa izin khusus (MediaStore)
          }
        } else {
          // Android < 11 : minta storage biasa
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        }
      }

      // Tulis langsung ke folder Download
      const downloadsPath = '/storage/emulated/0/Download';
      final downloadsDir = Directory(downloadsPath);

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final filePath = '$downloadsPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tersimpan di folder Download: $fileName'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green[700],
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal simpan: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      return false;
    }
  }

  static Future<int?> _getAndroidSdkInt() async {
    try {
      // Baca dari system property
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim());
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  //  EXPORT: Sensor Log
  // ============================================================
  static Future<void> exportKomposterLogs(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mempersiapkan CSV...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('komposter_logs')
          .orderByKey()
          .limitToLast(500)
          .get();

      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        List<List<dynamic>> rows = [
          ["Tanggal", "Waktu", "Suhu (°C)", "Gas (ppm)", "Kelembaban Tanah (%)", "Free Heap (Bytes)", "Uptime (ms)"]
        ];

        final sortedKeys = data.keys.toList()..sort();
        for (var key in sortedKeys) {
          final log = Map<String, dynamic>.from(data[key] as Map);

          // Ambil tanggal dari unix_time (bukan dari key Firebase yang berupa ID acak)
          String dateStr = '-';
          String timeStr = log['time']?.toString() ?? '-';
          try {
            final unixTime = log['unix_time'];
            if (unixTime != null) {
              final dt = DateTime.fromMillisecondsSinceEpoch((unixTime as num).toInt() * 1000);
              final wib = dt.add(const Duration(hours: 7));
              dateStr = DateFormat('dd/MM/yyyy').format(wib);
              timeStr = DateFormat('HH:mm:ss').format(wib);
            }
          } catch (_) {}

          rows.add([
            dateStr,
            timeStr,
            log['temperature']?.toString() ?? '-',
            log['gas']?.toString() ?? '-',
            log['soil']?.toString() ?? '-',
            (log['qos'] is Map ? (log['qos'] as Map)['free_heap']?.toString() : log['heap']?.toString()) ?? '-',
            (log['qos'] is Map ? (log['qos'] as Map)['uptime_ms']?.toString() : log['uptime']?.toString()) ?? '-',
          ]);
        }

        final csvData = _convertToCsv(rows);
        final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csvData)]);
        final fileName = 'Riwayat_Sensor_Komposter_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await _saveToDownloads(context, fileName, bytes);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data untuk diexport.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    }
  }

  // ============================================================
  //  EXPORT: QoS Log
  // ============================================================
  static Future<void> exportQosLogs(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mempersiapkan CSV QoS...'), duration: Duration(seconds: 1)),
      );
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('komposter_logs')
          .orderByKey()
          .limitToLast(500)
          .get();

      if (snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

        List<List<dynamic>> rows = [
          ["Waktu", "Delay (ms)", "Jitter (ms)", "Packet Loss (%)", "Throughput (KB/s)"]
        ];

        final sortedKeys = data.keys.map((k) => k.toString()).toList()..sort();
        for (var key in sortedKeys) {
          final log = Map<dynamic, dynamic>.from(data[key] as Map);
          final timeStr = log['time']?.toString() ?? '-';
          final qos = log['qos'] is Map ? Map<dynamic, dynamic>.from(log['qos']) : null;

          final double qosDelay = (qos?['delay_ms'] is num) ? (qos!['delay_ms'] as num).toDouble() : 0.0;
          final double qosJitter = (qos?['jitter_ms'] is num) ? (qos!['jitter_ms'] as num).toDouble() : 0.0;
          final double qosThroughputBps = (qos?['throughput_bps'] is num) ? (qos!['throughput_bps'] as num).toDouble() : 0.0;
          final double qosPacketLoss = (qos?['packet_loss_pct'] is num) ? (qos!['packet_loss_pct'] as num).toDouble() : 0.0;
          final double throughputKbps = qosThroughputBps / 1024.0;

          rows.add([
            timeStr,
            qosDelay > 0 ? qosDelay.toStringAsFixed(0) : '-',
            qosJitter.toStringAsFixed(0),
            qosPacketLoss.toStringAsFixed(1),
            throughputKbps.toStringAsFixed(2),
          ]);
        }

        final csvData = _convertToCsv(rows);
        final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csvData)]);
        final fileName = 'Rekap_QoS_Komposter_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await _saveToDownloads(context, fileName, bytes);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data QoS untuk diexport.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export QoS: $e')));
      }
    }
  }

  // ============================================================
  //  EXPORT: Aktuator Log
  // ============================================================
  static Future<void> exportActuatorLogs(BuildContext context, String actuatorType) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mempersiapkan CSV $actuatorType...'), duration: const Duration(seconds: 1)),
      );
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('logs/actuators')
          .orderByChild('actuator')
          .equalTo(actuatorType)
          .limitToLast(500)
          .get();

      if (snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

        List<List<dynamic>> rows = [
          ["ID", "Waktu", "Status", "Alasan", "Nilai Deteksi"]
        ];

        final List<Map<String, dynamic>> logs = [];
        data.forEach((key, val) {
          logs.add({'id': key, ...Map<String, dynamic>.from(val as Map)});
        });
        logs.sort((a, b) => (b['unix_time'] as num).compareTo(a['unix_time'] as num));

        for (var log in logs) {
          final time = DateTime.fromMillisecondsSinceEpoch((log['unix_time'] as num).toInt() * 1000);
          final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(time);
          rows.add([
            log['id'],
            timeStr,
            log['status'] ?? '-',
            log['reason'] ?? '-',
            log['value']?.toString() ?? '-',
          ]);
        }

        final csvData = _convertToCsv(rows);
        final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csvData)]);
        final fileName = 'Log_${actuatorType.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await _saveToDownloads(context, fileName, bytes);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data untuk diexport.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    }
  }

  // ============================================================
  //  EXPORT: Single Sensor Log
  // ============================================================
  static Future<void> exportSingleSensorLogs(BuildContext context, String sensorKey, String sensorLabel) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mempersiapkan CSV $sensorLabel...'), duration: const Duration(seconds: 1)),
      );
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('komposter_logs')
          .orderByKey()
          .limitToLast(500)
          .get();

      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        final Map<String, String> unitMap = {
          'temperature': '°C',
          'soil': '%',
          'gas': 'ppm',
        };

        List<List<dynamic>> rows = [
          ["Waktu", "$sensorLabel${unitMap[sensorKey] != null && unitMap[sensorKey]!.isNotEmpty ? ' (${unitMap[sensorKey]})' : ''}"]
        ];

        final sortedKeys = data.keys.toList()..sort();
        for (var key in sortedKeys) {
          final log = Map<String, dynamic>.from(data[key] as Map);
          rows.add([
            log['time']?.toString() ?? '-',
            log[sensorKey]?.toString() ?? '-',
          ]);
        }

        final csvData = _convertToCsv(rows);
        final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csvData)]);
        final fileName = 'Riwayat_${sensorLabel.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await _saveToDownloads(context, fileName, bytes);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data untuk diexport.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    }
  }

  // ============================================================
  //  HELPER: CSV Conversion — pakai koma agar kolom terpisah di Excel/Sheets
  // ============================================================
  static String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) => row.map((cell) {
      String cellStr = cell?.toString() ?? '-';
      // Jika ada koma, kutip ganda, atau baris baru — bungkus dengan tanda kutip
      if (cellStr.contains(',') || cellStr.contains('"') || cellStr.contains('\n')) {
        return '"${cellStr.replaceAll('"', '""')}"';
      }
      return cellStr;
    }).join(',')).join('\n');
  }
}
