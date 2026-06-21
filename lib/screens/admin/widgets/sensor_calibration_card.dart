import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

/// Shared widget for sensor threshold management (calibration removed).
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
  double _minThreshold = 0;
  double _maxThreshold = 0;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
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
      final thSnap = await FirebaseDatabase.instance.ref('komposter/thresholds/${widget.sensorKey}').get();
      if (thSnap.value != null && mounted) {
        final data = Map<String, dynamic>.from(thSnap.value as Map);
        setState(() {
          _minThreshold = (data['min'] as num?)?.toDouble() ?? widget.defaultMin;
          _maxThreshold = (data['max'] as num?)?.toDouble() ?? widget.defaultMax;
        });
      }
    } catch (e) {
      debugPrint('Error loading threshold data: $e');
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show Threshold Card (calibration removed)
    return Card(
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
