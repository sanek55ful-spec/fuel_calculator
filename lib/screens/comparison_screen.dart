import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/storage_service.dart';
import '../utils/fuel_type.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
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

  double? _costPer100(UserData u, String type) {
    final cons = u.consumptionFor(type);
    final price = u.priceFor(type);
    if (cons == null || price <= 0) return null;
    return cons * price;
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final u = _user!;

    final costs = {
      for (final t in FuelType.all) t: _costPer100(u, t),
    };

    final available = costs.entries
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value!))
        .toList();

    final baseCost = available.isEmpty
        ? null
        : available.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final baseType = available.isEmpty
        ? null
        : available.firstWhere((e) => e.value == baseCost).key;

    return Scaffold(
      appBar: AppBar(title: const Text('Сравнение топлива')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Стоимость 100 км пробега',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Считается как: расход × цена за литр',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          for (final type in FuelType.all)
            _card(
              type: type,
              consumption: u.consumptionFor(type),
              price: u.priceFor(type),
              cost: costs[type],
              baseCost: baseCost,
              isBase: type == baseType,
              actualCons: u.actualConsumptionFor(type),
            ),
          const SizedBox(height: 16),
          if (baseCost != null && baseType != null)
            _savings(u, baseCost, baseType),
          const SizedBox(height: 20),
          if (available.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '⚠️ Чтобы сравнить — установи расход и цену '
                'хотя бы для одного вида топлива.',
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({
    required String type,
    required double? consumption,
    required double price,
    required double? cost,
    required double? baseCost,
    required bool isBase,
    required double? actualCons,
  }) {
    final color = FuelType.color(type);
    final has = cost != null;
    final diff = (has && baseCost != null && !isBase) ? cost - baseCost : null;
    final percent = (diff != null && baseCost! > 0)
        ? (diff / baseCost * 100)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: has ? color : Colors.grey.shade300,
          width: isBase ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FuelType.icon(type), color: color, size: 26),
                const SizedBox(width: 8),
                Text(FuelType.label(type),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (isBase)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ВЫГОДНО',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (has) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${cost.toStringAsFixed(0)} ₽',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text('/ 100 км',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Норма: ${consumption!.toStringAsFixed(1)} л/100 км × '
                '${price.toStringAsFixed(2)} ₽/л',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (actualCons != null)
                Text(
                  'Факт: ${actualCons.toStringAsFixed(2)} л/100 км '
                  '(${(actualCons * price).toStringAsFixed(0)} ₽/100 км)',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.green),
                ),
              if (diff != null) ...[
                const SizedBox(height: 8),
                Text(
                  diff < 0
                      ? '↓ Дешевле на ${diff.abs().toStringAsFixed(0)} ₽ '
                        '(${percent!.abs().toStringAsFixed(0)}%)'
                      : '↑ Дороже на ${diff.toStringAsFixed(0)} ₽ '
                        '(${percent!.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: diff < 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ] else
              const Text('Нет данных о расходе или цене',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _savings(UserData u, double baseCost, String baseType) {
    final alternatives = <MapEntry<String, double>>[];
    for (final type in FuelType.all) {
      if (type == baseType) continue;
      final c = _costPer100(u, type);
      if (c != null) alternatives.add(MapEntry(type, c));
    }
    if (alternatives.isEmpty) {
      return const SizedBox.shrink();
    }
    alternatives.sort((a, b) => a.value.compareTo(b.value));
    final best = alternatives.first;
    final saving = baseCost - best.value;

    if (saving <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events,
                color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${FuelType.label(baseType)} — самое выгодное топливо',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  color: Colors.green, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Самое выгодное: ${FuelType.label(best.key)}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Экономия на 100 км: '
              '${saving.toStringAsFixed(0)} ₽',
              style: const TextStyle(fontSize: 15)),
          Text('На 1000 км: '
              '${(saving * 10).toStringAsFixed(0)} ₽',
              style: const TextStyle(fontSize: 15)),
          Text('На 10 000 км: '
              '${(saving * 100).toStringAsFixed(0)} ₽',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
        ],
      ),
    );
  }
}
