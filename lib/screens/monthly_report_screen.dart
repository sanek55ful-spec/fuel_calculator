import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/user_data.dart';
import '../utils/date_utils.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  UserData? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await StorageService.load();
    setState(() => _user = u);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final months = <String, Map<String, dynamic>>{};
    for (final t in _user!.trips) {
      final key = getMonthKeyFromTrip(t);
      months.putIfAbsent(key, () => {
        'distance': 0.0,
        'used': 0.0,
        'added': 0.0,
        'cost': 0.0,
        'count': 0,
      });
      months[key]!['count'] = (months[key]!['count'] as int) + 1;
      if (t.type == 'refuel') {
        months[key]!['added'] =
            (months[key]!['added'] as double) + (t.liters ?? 0);
      } else {
        months[key]!['used'] =
            (months[key]!['used'] as double) + (t.fuel ?? 0);
        months[key]!['distance'] =
            (months[key]!['distance'] as double) + (t.distance ?? 0);
      }
      months[key]!['cost'] =
          (months[key]!['cost'] as double) + (t.cost ?? 0);
    }

    final keys = months.keys.toList()
      ..sort((a, b) {
        final [m1, y1] = a.split('.').map(int.parse).toList();
        final [m2, y2] = b.split('.').map(int.parse).toList();
        if (y1 != y2) return y2 - y1;
        return m2 - m1;
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Отчёт по месяцам')),
      body: keys.isEmpty
          ? const Center(child: Text('Нет данных'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: keys.map((k) {
                final m = months[k]!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(getMonthName(k),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Записей: ${m['count']}'),
                        if ((m['distance'] as double) > 0)
                          Text('Пробег: '
                              '${(m['distance'] as double).toStringAsFixed(1)} км'),
                        if ((m['used'] as double) > 0)
                          Text('Потрачено: '
                              '${(m['used'] as double).toStringAsFixed(2)} л'),
                        if ((m['added'] as double) > 0)
                          Text('Заправлено: '
                              '${(m['added'] as double).toStringAsFixed(2)} л'),
                        if ((m['cost'] as double) > 0)
                          Text('Стоимость: '
                              '${(m['cost'] as double).toStringAsFixed(0)} ₽',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
