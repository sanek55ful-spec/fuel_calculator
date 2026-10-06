import 'package:flutter/material.dart';
import '../services/fuel_service.dart';
import '../services/storage_service.dart';
import '../utils/fuel_type.dart';

class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  final _ctrl = TextEditingController();
  String _fuelType = FuelType.petrol;
  String? _error;

  Future<void> _save() async {
    final value = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      setState(() => _error = 'Введи положительное число');
      return;
    }

    final user = await StorageService.load();
    final msg = FuelService.recordManual(user, value, _fuelType);
    await StorageService.save(user);

    if (!mounted) return;
    if (msg.startsWith('❗')) {
      setState(() => _error = msg);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Посчитать вручную')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
            onSelectionChanged: (s) =>
                setState(() => _fuelType = s.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Сколько км проехал',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
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
