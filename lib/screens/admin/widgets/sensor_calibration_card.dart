import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

/// Shared widget for sensor calibration (offset + tutorial) and threshold management.
class SensorCalibrationCard extends StatefulWidget {
  final String sensorKey; // e.g. 'ph', 'temperature', 'soil', 'gas'
  final String sensorLabel; // e.g. 'pH', 'Suhu', 'Kelembaban', 'Gas'
  final String unit; // e.g. '', '°C', '%', 'ppm'
  final Color color;
  final double defaultMin;
  final double defaultMax;

  const SensorCalibrationCard({
    Key? key,
    required this.sensorKey,
    required this.sensorLabel,
    required this.unit,
    required this.color,
    required this.defaultMin,
    required this.defaultMax,
  }) : super(key: key);

  @override
  State<SensorCalibrationCard> createState() => _SensorCalibrationCardState();
}

class _SensorCalibrationCardState extends State<SensorCalibrationCard> {
  DateTime? _lastCalibration;
  double _minThreshold = 0;
  double _maxThreshold = 0;
  double _calibrationOffset = 0;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _offsetController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _minThreshold = widget.defaultMin;
    _maxThreshold = widget.defaultMax;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load calibration date
      final calSnap = await FirebaseDatabase.instance.ref('komposter/calibration/${widget.sensorKey}').get();
      if (calSnap.value != null) {
        final int ts = (calSnap.value as num).toInt();
        if (mounted) setState(() => _lastCalibration = DateTime.fromMillisecondsSinceEpoch(ts * 1000));
      }

      // Load offset
      final offSnap = await FirebaseDatabase.instance.ref('komposter/calibration/${widget.sensorKey}_offset').get();
      if (offSnap.value != null && mounted) {
        setState(() => _calibrationOffset = (offSnap.value as num).toDouble());
      }

      // Load thresholds
      final thSnap = await FirebaseDatabase.instance.ref('komposter/thresholds/${widget.sensorKey}').get();
      if (thSnap.value != null && mounted) {
        final data = Map<String, dynamic>.from(thSnap.value as Map);
        setState(() {
          _minThreshold = (data['min'] as num?)?.toDouble() ?? widget.defaultMin;
          _maxThreshold = (data['max'] as num?)?.toDouble() ?? widget.defaultMax;
        });
      }
    } catch (e) {
      debugPrint('Error loading calibration data: $e');
    }
  }

  Future<void> _calibrateWithOffset() async {
    _offsetController.text = _calibrationOffset.toString();

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kalibrasi ${widget.sensorLabel}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan nilai offset kalibrasi. Nilai ini akan ditambahkan ke pembacaan sensor mentah.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _offsetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: 'Offset ${widget.unit}',
                hintText: 'Misal: 0.5 atau -1.2',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.tune, color: widget.color),
                suffixText: widget.unit,
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Gunakan + jika sensor membaca terlalu rendah\nGunakan - jika sensor membaca terlalu tinggi',
                    style: TextStyle(fontSize: 11, fontFamily: 'Poppins', color: Colors.blue[700]),
                  )),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(_offsetController.text);
              if (val != null) Navigator.pop(ctx, val);
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.color),
            child: const Text('Simpan & Kalibrasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await FirebaseDatabase.instance.ref('komposter/calibration/${widget.sensorKey}').set(now);
      await FirebaseDatabase.instance.ref('komposter/calibration/${widget.sensorKey}_offset').set(result);
      if (mounted) {
        setState(() {
          _lastCalibration = DateTime.now();
          _calibrationOffset = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.sensorLabel} berhasil dikalibrasi (offset: ${result > 0 ? "+" : ""}$result${widget.unit})'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _showCalibrationTutorial() {
    final tutorials = <String, List<Map<String, String>>>{
      'ph': [
        {'step': '1', 'title': 'Siapkan Larutan Buffer', 'desc': 'Siapkan larutan buffer pH 4.0, 7.0, dan 10.0'},
        {'step': '2', 'title': 'Celupkan Sensor', 'desc': 'Celupkan sensor pH ke larutan buffer pH 7.0 (netral). Tunggu 2 menit hingga stabil.'},
        {'step': '3', 'title': 'Catat Selisih', 'desc': 'Lihat pembacaan di layar. Jika tertulis 6.5 padahal seharusnya 7.0, maka offset = +0.5'},
        {'step': '4', 'title': 'Input Offset', 'desc': 'Masukkan nilai offset di atas. ESP32 akan otomatis menambahkan nilai ini ke pembacaan.'},
        {'step': '5', 'title': 'Verifikasi', 'desc': 'Celupkan lagi ke buffer pH 7.0. Pastikan pembacaan sekarang mendekati 7.0.'},
      ],
      'temperature': [
        {'step': '1', 'title': 'Siapkan Termometer Referensi', 'desc': 'Gunakan termometer merkuri atau digital yang sudah terkalibrasi.'},
        {'step': '2', 'title': 'Ukur Bersamaan', 'desc': 'Letakkan sensor DS18B20 dan termometer referensi di tempat yang sama selama 5 menit.'},
        {'step': '3', 'title': 'Catat Selisih', 'desc': 'Jika referensi = 30°C, sensor = 28.5°C, maka offset = +1.5'},
        {'step': '4', 'title': 'Input Offset', 'desc': 'Masukkan offset. ESP32 akan otomatis menambahkan nilai ini.'},
      ],
      'soil': [
        {'step': '1', 'title': 'Persiapan Tanah', 'desc': 'Siapkan tanah kering (0%) dan tanah basah jenuh (100%) sebagai referensi.'},
        {'step': '2', 'title': 'Uji di Tanah Kering', 'desc': 'Tusukkan sensor ke tanah kering. Catat pembacaan.'},
        {'step': '3', 'title': 'Uji di Tanah Basah', 'desc': 'Tusukkan sensor ke tanah yang sangat basah. Catat pembacaan.'},
        {'step': '4', 'title': 'Hitung Offset', 'desc': 'Bandingkan dengan nilai sebenarnya. Jika tanah basah seharusnya 80% tapi terbaca 75%, maka offset = +5'},
      ],
      'gas': [
        {'step': '1', 'title': 'Baseline di Udara Bersih', 'desc': 'Letakkan sensor MQ-4 di ruangan terbuka dengan udara bersih selama 10 menit.'},
        {'step': '2', 'title': 'Pemanasan Sensor', 'desc': 'Sensor MQ-4 butuh pemanasan (burn-in) minimal 24 jam saat pertama kali digunakan.'},
        {'step': '3', 'title': 'Catat Baseline', 'desc': 'Pembacaan di udara bersih seharusnya mendekati 0 ppm. Jika terbaca 50, maka offset = -50'},
        {'step': '4', 'title': 'Input Offset', 'desc': 'Masukkan offset agar pembacaan di udara bersih mendekati 0.'},
      ],
    };

    final steps = tutorials[widget.sensorKey] ?? tutorials['ph']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.school, color: widget.color, size: 24),
                  const SizedBox(width: 10),
                  Text('Panduan Kalibrasi ${widget.sensorLabel}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ],
              ),
              const SizedBox(height: 20),
              ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: widget.color.withOpacity(0.1), shape: BoxShape.circle),
                      child: Center(child: Text(step['step']!, style: TextStyle(fontWeight: FontWeight.bold, color: widget.color, fontFamily: 'Poppins'))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(step['desc']!, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber[200]!)),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 18, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Disarankan kalibrasi ulang setiap 30 hari untuk menjaga akurasi sensor.',
                      style: TextStyle(fontSize: 11, fontFamily: 'Poppins', color: Colors.amber[900]),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveThresholds() async {
    final min = double.tryParse(_minController.text);
    final max = double.tryParse(_maxController.text);
    if (min == null || max == null || min >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nilai tidak valid. Batas bawah harus < batas atas.'), backgroundColor: Colors.red),
      );
      return;
    }

    await FirebaseDatabase.instance.ref('komposter/thresholds/${widget.sensorKey}').set({'min': min, 'max': max});
    if (mounted) {
      setState(() { _minThreshold = min; _maxThreshold = max; _isEditing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Threshold ${widget.sensorLabel} berhasil disimpan!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  int get _daysSinceCalibration {
    if (_lastCalibration == null) return -1;
    return DateTime.now().difference(_lastCalibration!).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calibration Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.build_circle, color: widget.color, size: 20),
                    const SizedBox(width: 8),
                    const Text('Kalibrasi Sensor', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Terakhir Kalibrasi', _lastCalibration != null ? DateFormat('dd MMM yyyy').format(_lastCalibration!) : 'Belum pernah'),
                if (_calibrationOffset != 0) ...[
                  const Divider(),
                  _buildInfoRow('Offset Aktif', '${_calibrationOffset > 0 ? "+" : ""}${_calibrationOffset.toStringAsFixed(2)} ${widget.unit}'),
                ],
                if (_daysSinceCalibration >= 0) ...[
                  const Divider(),
                  _buildInfoRow(
                    'Status',
                    _daysSinceCalibration >= 30 ? 'Perlu kalibrasi ulang' : 'OK ($_daysSinceCalibration hari lalu)',
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: _calibrateWithOffset,
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text('Kalibrasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.color,
                            side: BorderSide(color: widget.color),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: _showCalibrationTutorial,
                          icon: const Icon(Icons.menu_book, size: 16),
                          label: const Text('Panduan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(color: Colors.blue[300]!),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Threshold Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: widget.color, size: 20),
                        const SizedBox(width: 8),
                        const Text('Threshold Sensor', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      ],
                    ),
                    IconButton(
                      icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 20, color: widget.color),
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                          if (_isEditing) {
                            _minController.text = _minThreshold.toString();
                            _maxController.text = _maxThreshold.toString();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_isEditing) ...[
                  _buildInfoRow('Batas Bawah', '${_minThreshold.toStringAsFixed(1)} ${widget.unit}'),
                  const Divider(),
                  _buildInfoRow('Batas Atas', '${_maxThreshold.toStringAsFixed(1)} ${widget.unit}'),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Min ${widget.unit}',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Max ${widget.unit}',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveThresholds,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Simpan Threshold'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontFamily: 'Poppins', fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
