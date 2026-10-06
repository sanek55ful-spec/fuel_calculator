import 'package:flutter/material.dart';
import '../services/fuel_service.dart';
import '../services/storage_service.dart';
import '../utils/fuel_type.dart';

class OdometerScreen extends StatefulWidget {
  const OdometerScreen({super.key});

  @override
  State<OdometerScreen> createState() => _OdometerScreenState();
}

class _OdometerScreenState extends State<OdometerScreen> {
  final _ctrl = TextEditingController();
  String _fuelType = FuelType.petrol;
  bool _mixed = false;
  double _petrolRatio = 0.5;
  String? _error;

  Future<void> _save() async {
    final value = int.tryParse(
        _ctrl.text.replaceAll(RegExp(r'[\s.,]'), ''));
    if (value == null || value <= 0) {
      setState(() => _error = 'Введи целое число');
      return;
    }

    final user = await StorageService.load();
    final msg = _mixed
        ? FuelService.recordOdometerMixed(user, value, _petrolRatio)
        : FuelService.recordOdometer(user, value, _fuelType);
    await StorageService.save(user);

    if (!mounted) return;
    if (msg.startsWith('❌') || msg.startsWith('❗')) {
      setState(() => _error = msg);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Записать одометр')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Текущий пробег, км',
              border: const OutlineInputBorder(),
              errorText: _error,
              prefixIcon: const Icon(Icons.speed),
            ),
          ),
          const SizedBox(height: 20),
          const Text('На каком топливе:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: FuelType.petrol,
                  label: Text('⛽'), icon: Icon(Icons.local_gas_station)),
              ButtonSegment(value: FuelType.gas,
                  label: Text('💨'), icon: Icon(Icons.propane_tank)),
              ButtonSegment(value: FuelType.diesel,
                  label: Text('🛢️'), icon: Icon(Icons.local_shipping)),
            ],
            selected: {_fuelType},
            onSelectionChanged: _mixed
                ? null
                : (s) => setState(() => _fuelType = s.first),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Смешанная поездка (бензин + газ)'),
            value: _mixed,
            onChanged: (v) => setState(() => _mixed = v ?? false),
          ),
          if (_mixed) ...[
            Slider(
              value: _petrolRatio,
              min: 0, max: 1, divisions: 10,
              label: '${(_petrolRatio * 100).round()}% бензин',
              onChanged: (v) => setState(() => _petrolRatio = v),
            ),
            Text(
              '${(_petrolRatio * 100).round()}% на бензине, '
              '${((1 - _petrolRatio) * 100).round()}% на газе',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }
}
