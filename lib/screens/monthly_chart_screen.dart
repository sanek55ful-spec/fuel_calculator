import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_data.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';
import '../utils/fuel_type.dart';

class MonthlyChartScreen extends StatefulWidget {
  const MonthlyChartScreen({super.key});

  @override
  State<MonthlyChartScreen> createState() => _MonthlyChartScreenState();
}

class _MonthlyChartScreenState extends State<MonthlyChartScreen> {
  final _chartKey = GlobalKey();
  UserData? _user;
  Map<String, double> _petrol = {};
  Map<String, double> _gas = {};
  Map<String, double> _diesel = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await StorageService.load();
    final petrol = <String, double>{};
    final gas = <String, double>{};
    final diesel = <String, double>{};

    for (final t in u.trips) {
      if (t.type == 'refuel') continue;
      final key = getMonthKeyFromTrip(t);
      final v = t.fuel ?? 0;

      if (t.fuelType == FuelType.mixed) {
        petrol[key] = (petrol[key] ?? 0) + v / 2;
        gas[key] = (gas[key] ?? 0) + v / 2;
      } else if (t.fuelType == FuelType.gas) {
        gas[key] = (gas[key] ?? 0) + v;
      } else if (t.fuelType == FuelType.diesel) {
        diesel[key] = (diesel[key] ?? 0) + v;
      } else {
        petrol[key] = (petrol[key] ?? 0) + v;
      }
    }

    setState(() {
      _user = u;
      _petrol = petrol;
      _gas = gas;
      _diesel = diesel;
    });
  }

  List<String> get _months {
    final set = {..._petrol.keys, ..._gas.keys, ..._diesel.keys};
    final list = set.toList()
      ..sort((a, b) {
        final [m1, y1] = a.split('.').map(int.parse).toList();
        final [m2, y2] = b.split('.').map(int.parse).toList();
        if (y1 != y2) return y1.compareTo(y2);
        return m1.compareTo(m2);
      });
    return list;
  }

  Future<Uint8List?> _captureChart() async {
    try {
      final boundary = _chartKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  Future<void> _shareChart() async {
    final bytes = await _captureChart();
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сделать скриншот')),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/fuel_chart.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      subject: 'График расхода топлива',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final months = _months;
    if (months.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('График расхода')),
        body: const Center(child: Text('Нет данных')),
      );
    }

    final petrolSpots = <FlSpot>[];
    final gasSpots = <FlSpot>[];
    final dieselSpots = <FlSpot>[];
    for (var i = 0; i < months.length; i++) {
      petrolSpots.add(FlSpot(i.toDouble(), _petrol[months[i]] ?? 0));
      gasSpots.add(FlSpot(i.toDouble(), _gas[months[i]] ?? 0));
      dieselSpots.add(FlSpot(i.toDouble(), _diesel[months[i]] ?? 0));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расход по месяцам'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Поделиться картинкой',
            onPressed: _shareChart,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legend(Colors.orange, '⛽ Бензин'),
                const SizedBox(width: 12),
                _legend(Colors.green, '💨 Газ'),
                const SizedBox(width: 12),
                _legend(Colors.brown, '🛢️ Дизель'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RepaintBoundary(
                key: _chartKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toStringAsFixed(0)} л',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= months.length) {
                                return const SizedBox.shrink();
                              }
                              final p = months[i].split('.');
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${p[0]}.${p[1].substring(2)}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: petrolSpots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: gasSpots,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: dieselSpots,
                          isCurved: true,
                          color: Colors.brown,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _shareChart,
                icon: const Icon(Icons.share),
                label: const Text('Поделиться графиком (PNG)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 14, height: 4, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
