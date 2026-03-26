import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class CsvExportHelper {
  /// Export logs from 'komposter_logs' to CSV
  static Future<void> exportKomposterLogs(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mempersiapkan CSV...'), duration: Duration(seconds: 1)));
    }

    try {
      final DatabaseReference logsRef = FirebaseDatabase.instance.ref('komposter_logs');
      final snapshot = await logsRef.orderByKey().limitToLast(500).get();
      
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        List<List<dynamic>> rows = [
          ["Waktu", "Suhu (°C)", "Gas (ppm)", "Kelebaban Tanah (%)", "pH", "WiFi (%)", "Free Heap (Bytes)", "Uptime (ms)"]
        ];

        final List<String> sortedKeys = data.keys.toList()..sort();
        for (var key in sortedKeys) {
          final log = Map<String, dynamic>.from(data[key] as Map);
          rows.add([
            log['time']?.toString() ?? '-',
            log['temperature']?.toString() ?? '-',
            log['gas']?.toString() ?? '-',
            log['soil']?.toString() ?? '-',
            log['ph']?.toString() ?? '-',
            log['wifi']?.toString() ?? '-',
            log['heap']?.toString() ?? '-',
            log['uptime']?.toString() ?? '-'
          ]);
        }

        String csvData = _convertToCsv(rows);
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/Riwayat_Sensor_Komposter.csv';
        final file = File(path);
        
        await file.writeAsString(csvData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        
        await Share.shareXFiles([XFile(path)], text: 'Data Historis Sensor Komposter (500 Log Terakhir)');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk diexport.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    }
  }

  /// Export logs from 'logs/actuators' to CSV
  static Future<void> exportActuatorLogs(BuildContext context, String actuatorType) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mempersiapkan CSV $actuatorType...'), duration: const Duration(seconds: 1)));
    }

    try {
      final DatabaseReference logsRef = FirebaseDatabase.instance.ref('logs/actuators');
      final snapshot = await logsRef.orderByChild('actuator').equalTo(actuatorType).limitToLast(500).get();
      
      if (snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        
        List<List<dynamic>> rows = [
          ["ID", "Waktu", "Status", "Alasan", "Nilai Deteksi"]
        ];

        final List<Map<String, dynamic>> logs = [];
        data.forEach((key, val) {
          logs.add({
            'id': key,
            ...Map<String, dynamic>.from(val as Map),
          });
        });
        
        // Sort by time descending
        logs.sort((a, b) => (b['unix_time'] as num).compareTo(a['unix_time'] as num));

        for (var log in logs) {
          final time = DateTime.fromMillisecondsSinceEpoch((log['unix_time'] as num).toInt() * 1000);
          final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(time);
          
          rows.add([
            log['id'],
            timeStr,
            log['status'] ?? '-',
            log['reason'] ?? '-',
            log['value']?.toString() ?? '-'
          ]);
        }

        String csvData = _convertToCsv(rows);
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/Log_${actuatorType.replaceAll(' ', '_')}.csv';
        final file = File(path);
        
        await file.writeAsString(csvData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        
        await Share.shareXFiles([XFile(path)], text: 'Data Historis $actuatorType (500 Log Terakhir)');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk diexport.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    }
  }

  /// Export single sensor data from komposter_logs
  static Future<void> exportSingleSensorLogs(BuildContext context, String sensorKey, String sensorLabel) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mempersiapkan CSV $sensorLabel...'), duration: const Duration(seconds: 1)));
    }

    try {
      final snapshot = await FirebaseDatabase.instance.ref('komposter_logs').orderByKey().limitToLast(500).get();
      
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        // Map sensor keys to unit labels
        final Map<String, String> unitMap = {
          'temperature': '°C',
          'ph': '',
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

        String csvData = _convertToCsv(rows);
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/Riwayat_${sensorLabel.replaceAll(' ', '_')}.csv';
        final file = File(path);
        
        await file.writeAsString(csvData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        
        await Share.shareXFiles([XFile(path)], text: 'Data Historis $sensorLabel (500 Log Terakhir)');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk diexport.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    }
  }

  /// Manual CSV Conversion to avoid package dependency issues
  static String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) => row.map((cell) {
      String cellStr = cell?.toString() ?? '-';
      // Handle commas, quotes, and newlines by quoting the cell
      if (cellStr.contains(',') || cellStr.contains('"') || cellStr.contains('\n')) {
        return '"${cellStr.replaceAll('"', '""')}"';
      }
      return cellStr;
    }).join(',')).join('\n');
  }
}
