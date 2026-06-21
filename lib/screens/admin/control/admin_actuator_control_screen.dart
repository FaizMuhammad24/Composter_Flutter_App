import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';

class AdminActuatorControlScreen extends StatefulWidget {
  const AdminActuatorControlScreen({Key? key}) : super(key: key);
  @override
  State<AdminActuatorControlScreen> createState() => _AdminActuatorControlScreenState();
}

class _AdminActuatorControlScreenState extends State<AdminActuatorControlScreen> {
  // Actuator status from Firebase
  bool _heaterOn = false;
  bool _fanOn = false;
  bool _motorOn = false;
  bool _pumpP1On = false;
  bool _pumpP2On = false;
  bool _isOffline = true;

  // Pump countdown timers — cumulative
  int _p1Countdown = 0;
  int _p2Countdown = 0;
  Timer? _p1Timer;
  Timer? _p2Timer;

  // Motor schedule
  bool _motorEnabled = false;
  int _motorDuration = 5;
  TimeOfDay? _selectedTime;
  List<TimeOfDay> _motorScheduleTimes = [];

  StreamSubscription? _actuatorSub;

  @override
  void initState() {
    super.initState();
    _listenActuators();
    _loadMotorSchedule();
  }

  void _listenActuators() {
    _actuatorSub = FirebaseDatabase.instance.ref('komposter').onValue.listen((event) {
      if (!mounted || event.snapshot.value == null) return;
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      bool stale = true;
      if (data.containsKey('unix_time')) {
        final int espUnix = (data['unix_time'] as num).toInt();
        final int phoneUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        stale = (phoneUnix - espUnix).abs() > 60;
      }

      final actuators = data['actuators'] is Map ? Map<String, dynamic>.from(data['actuators']) : {};

      setState(() {
        _isOffline = stale;
        _heaterOn = actuators['heater'] == true;
        _fanOn = actuators['fan'] == true;
        _motorOn = actuators['motor'] == true;
        _pumpP1On = actuators['water_pump'] == true;
        _pumpP2On = actuators['em4_pump'] == true;
      });
    });
  }

  void _loadMotorSchedule() async {
    try {
      final snap = await FirebaseDatabase.instance.ref('komposter/controls/motor').get();
      if (snap.value != null && mounted) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        setState(() {
          _motorEnabled = data['enabled'] == true;
          _motorDuration = (data['duration_minutes'] as num?)?.toInt() ?? 5;
          final hoursStr = data['schedule_hours']?.toString() ?? '';
          if (hoursStr.isNotEmpty) {
            _motorScheduleTimes = hoursStr.split(',').map((h) {
              final hour = int.tryParse(h.trim()) ?? 0;
              return TimeOfDay(hour: hour, minute: 0);
            }).toList()
              ..sort((a, b) => a.hour.compareTo(b.hour));
          }
        });
      }
    } catch (_) {}
  }

  /// Cumulative pump trigger — each press adds 30s (P1) or 20s (P2) to remaining countdown
  Future<void> _triggerPump(String pumpPath, int addSec, bool isP1) async {
    try {
      // Add to current countdown
      setState(() {
        if (isP1) {
          _p1Countdown += addSec;
        } else {
          _p2Countdown += addSec;
        }
      });

      // Send command to Firebase
      await FirebaseDatabase.instance.ref('komposter/controls/$pumpPath').update({
        'command': 'ON',
        'duration_sec': isP1 ? _p1Countdown : _p2Countdown,
        'timestamp': ServerValue.timestamp,
      });

      // Start or continue countdown timer
      if (isP1 && _p1Timer == null) {
        _p1Timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            _p1Countdown--;
          });
          if (_p1Countdown <= 0) {
            t.cancel();
            _p1Timer = null;
          }
        });
      }

      if (!isP1 && _p2Timer == null) {
        _p2Timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            _p2Countdown--;
          });
          if (_p2Countdown <= 0) {
            t.cancel();
            _p2Timer = null;
          }
        });
      }

      if (mounted) {
        final vol = isP1
            ? '${((_p1Countdown / 30) * 100).round()}ml'
            : '${((_p2Countdown / 20) * 50).round()}ml';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${isP1 ? "Molase" : "EM4"} +${addSec}s (total: ~$vol)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _addMotorTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        // Remove duplicate hour
        _motorScheduleTimes.removeWhere((t) => t.hour == picked.hour);
        _motorScheduleTimes.add(picked);
        _motorScheduleTimes.sort((a, b) => a.hour * 60 + a.minute - b.hour * 60 - b.minute);
        _selectedTime = picked;
      });
    }
  }

  void _removeMotorTime(int index) {
    setState(() {
      _motorScheduleTimes.removeAt(index);
    });
  }

  Future<void> _saveMotorSchedule() async {
    try {
      final hoursStr = _motorScheduleTimes.map((t) => t.hour.toString()).join(',');
      await FirebaseDatabase.instance.ref('komposter/controls/motor').update({
        'enabled': _motorEnabled,
        'duration_minutes': _motorDuration,
        'schedule_hours': hoursStr,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal motor tersimpan!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() {
    _actuatorSub?.cancel();
    _p1Timer?.cancel();
    _p2Timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _loadMotorSchedule(),
      color: AppColors.adminPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Status Aktuator', Icons.sensors),
            const SizedBox(height: AppSpacing.sm),
            _buildActuatorStatusRow(),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle('Kontrol Pompa Manual', Icons.water),
            const SizedBox(height: 4),
            Text('Tekan berulang untuk menambah durasi', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Poppins')),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _buildPumpCard(
                  title: 'Pompa Molase',
                  subtitle: 'Setiap tekan +30s (~100ml)',
                  icon: Icons.water_drop,
                  color: Colors.blue,
                  isActive: _pumpP1On,
                  countdown: _p1Countdown,
                  onTap: () => _triggerPump('water_pump', 30, true),
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildPumpCard(
                  title: 'Pompa EM4',
                  subtitle: 'Setiap tekan +20s (~50ml)',
                  icon: Icons.science,
                  color: Colors.purple,
                  isActive: _pumpP2On,
                  countdown: _p2Countdown,
                  onTap: () => _triggerPump('em4_pump', 20, false),
                )),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle('Jadwal Motor Pengaduk', Icons.settings),
            const SizedBox(height: AppSpacing.sm),
            _buildMotorScheduleCard(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.adminPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.adminPrimary, size: 20),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
      ],
    );
  }

  Widget _buildActuatorStatusRow() {
    final items = [
      _ActuatorItem('Heater', Icons.local_fire_department, Colors.deepOrange, _heaterOn, 'Otomatis'),
      _ActuatorItem('Fan', Icons.air, Colors.blue, _fanOn, 'Otomatis'),
      _ActuatorItem('Motor', Icons.settings, Colors.teal, _motorOn, 'Jadwal'),
      _ActuatorItem('P1', Icons.water_drop, Colors.indigo, _pumpP1On || _p1Countdown > 0, 'Manual'),
      _ActuatorItem('P2', Icons.science, Colors.purple, _pumpP2On || _p2Countdown > 0, 'Manual'),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          final isOn = !_isOffline && item.isOn;
          return Container(
            width: 90,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOn ? item.color.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isOn ? item.color.withValues(alpha: 0.3) : Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOn ? item.color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: isOn ? item.color : Colors.grey, size: 22),
                    ),
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: _isOffline ? Colors.grey : (isOn ? Colors.green : Colors.red.shade300),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis),
                Text(
                  _isOffline ? 'Offline' : (isOn ? 'Aktif' : 'Mati'),
                  style: TextStyle(fontSize: 9, color: _isOffline ? Colors.grey : (isOn ? item.color : Colors.grey), fontFamily: 'Poppins'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPumpCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required int countdown,
    required VoidCallback onTap,
  }) {
    final isRunning = countdown > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isRunning ? color.withValues(alpha: 0.4) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 9, color: Colors.grey[500], fontFamily: 'Poppins'), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          if (isRunning) ...[
            Text('${countdown}s', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            // Plus button to add more time while running
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isOffline ? null : onTap,
                icon: const Icon(Icons.add, size: 16),
                label: Text('+${title.contains("Molase") ? "30" : "20"}s', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isOffline ? null : onTap,
                icon: const Icon(Icons.power_settings_new, size: 16),
                label: Text(_isOffline ? 'Offline' : 'Nyalakan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Poppins')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMotorScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.schedule, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Jadwal Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 15)),
                ],
              ),
              Switch(
                value: _motorEnabled,
                onChanged: (v) => setState(() => _motorEnabled = v),
                activeTrackColor: Colors.teal,
              ),
            ],
          ),
          if (_motorEnabled) ...[
            const Divider(height: 24),

            // Duration slider
            const Text('Durasi per Sesi', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.teal,
                      thumbColor: Colors.teal,
                      inactiveTrackColor: Colors.teal.withValues(alpha: 0.15),
                      overlayColor: Colors.teal.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: _motorDuration.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      onChanged: (v) => setState(() => _motorDuration = v.round()),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$_motorDuration min', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Schedule times - list with add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jam Operasional', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13)),
                TextButton.icon(
                  onPressed: _addMotorTime,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Tambah', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_motorScheduleTimes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text('Belum ada jadwal. Tekan "Tambah" untuk menambah jam.', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_motorScheduleTimes.length, (i) {
                  final t = _motorScheduleTimes[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14, color: Colors.teal)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeMotorTime(i),
                          child: Icon(Icons.close, size: 16, color: Colors.red[300]),
                        ),
                      ],
                    ),
                  );
                }),
              ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Motor akan menyala otomatis pada jam yang dipilih selama $_motorDuration menit. Data dikirim ke ESP32 via Firebase.',
                      style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: Colors.blue[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isOffline ? null : _saveMotorSchedule,
              icon: const Icon(Icons.save, size: 18, color: Colors.white),
              label: const Text('Simpan Jadwal', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActuatorItem {
  final String name;
  final IconData icon;
  final Color color;
  final bool isOn;
  final String type;
  _ActuatorItem(this.name, this.icon, this.color, this.isOn, this.type);
}
