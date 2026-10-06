import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/user_data.dart';
import '../utils/fuel_type.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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
    final u = _user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final type in FuelType.all) _fuelBlock(u, type),
        ],
      ),
    );
  }

  Widget _fuelBlock(UserData u, String type) {
    final typed = u.trips.where((t) => t.fuelType == type).toList();
    final distance = typed.fold<double>(
        0, (s, t) => s + (t.distance ?? 0));
    final used = typed
        .where((t) => t.type != 'refuel')
        .fold<double>(0, (s, t) => s + (t.fuel ?? 0));
    final added = typed
        .where((t) => t.type == 'refuel')
        .fold<double>(0, (s, t) => s + (t.liters ?? 0));
    final cost = typed.fold<double>(0, (s, t) => s + (t.cost ?? 0));

    final normCons = u.consumptionFor(type);
    final actualCons = u.actualConsumptionFor(type);
    final color = FuelType.color(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FuelType.icon(type), color: color),
                const SizedBox(width: 8),
                Text(FuelType.label(type),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _row('Записей', '${typed.length}'),
            _row('Пробег', '${distance.toStringAsFixed(1)} км'),
            _row('Потрачено', '${used.toStringAsFixed(2)} л'),
            _row('Заправлено', '${added.toStringAsFixed(2)} л'),
            if (normCons != null)
              _row('Расход (норма)',
                  '${normCons.toStringAsFixed(1)} л/100 км'),
            if (actualCons != null)
              _row('Расход (факт)',
                  '${actualCons.toStringAsFixed(2)} л/100 км',
                  color: Colors.green),
            if (u.priceFor(type) > 0)
              _row('Стоимость', '${cost.toStringAsFixed(0)} ₽'),
            _row('Остаток', '${u.fuelFor(type).toStringAsFixed(2)} л'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
