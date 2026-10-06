import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/user_data.dart';
import '../models/trip.dart';
import '../utils/fuel_type.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  UserData? _user;
  String? _filter;

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

    var trips = [..._user!.trips].reversed.toList();
    if (_filter != null) {
      trips = trips.where((t) => t.fuelType == _filter).toList();
    }
    trips = trips.take(200).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('История')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _chip('Все', null),
                const SizedBox(width: 6),
                _chip('⛽', FuelType.petrol),
                const SizedBox(width: 6),
                _chip('💨', FuelType.gas),
                const SizedBox(width: 6),
                _chip('🛢️', FuelType.diesel),
              ],
            ),
          ),
          Expanded(
            child: trips.isEmpty
                ? const Center(child: Text('История пуста'))
                : ListView.builder(
                    itemCount: trips.length,
                    itemBuilder: (_, i) => _tripTile(trips[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? type) {
    final selected = _filter == type;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = type),
    );
  }

  Widget _tripTile(Trip t) {
    final color = FuelType.color(t.fuelType);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Text(FuelType.emoji(t.fuelType),
            style: const TextStyle(fontSize: 20)),
      ),
      title: Text(_title(t)),
      subtitle: Text(t.date),
      trailing: (t.cost != null)
          ? Text('${t.cost!.toStringAsFixed(0)} ₽',
              style: const TextStyle(fontWeight: FontWeight.bold))
          : null,
    );
  }

  String _title(Trip t) {
    switch (t.type) {
      case 'refuel':
        return 'Заправка +${t.liters} л';
      case 'inverter':
        return 'Инвертор ${t.hours} ч → ${t.fuel} л';
      case 'odometer':
        if (t.fromOdo != null) {
          return '${t.fromOdo} → ${t.toOdo} (${t.distance} км) → ${t.fuel} л';
        }
        return 'Одометр: ${t.toOdo} км';
      case 'manual':
        return '${t.distance} км → ${t.fuel} л';
      default:
        return t.type;
    }
  }
}
