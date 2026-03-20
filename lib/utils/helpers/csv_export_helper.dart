import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class CsvExportHelper {
  static Future<void> exportKomposterLogs(BuildContext context) async {
    // Tampilkan loading snackbar segera
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

        final sortedKeys = data.keys.toList()..sort();
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

        String csvData = Csv().encode(rows);
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
}
