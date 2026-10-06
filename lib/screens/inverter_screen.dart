import 'package:flutter/material.dart';
import '../services/fuel_service.dart';
import '../services/storage_service.dart';
import '../utils/fuel_type.dart';

class InverterScreen extends StatefulWidget {
  const InverterScreen({super.key});

  @override
  State<InverterScreen> createState() => _InverterScreenState();
}

class _InverterScreenState extends State<InverterScreen> {
  final _rateCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  String _fuelType = FuelType.petrol;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await StorageService.load();
    if (user.inverterRate != null) {
      _rateCtrl.text = user.inverterRate.toString();
    }
    setState(() {});
  }

  Future<void> _save() async {
    final rate = double.tryParse(_rateCtrl.text.replaceAll(',', '.'));
    final hours = double.tryParse(_hoursCtrl.text.replaceAll(',', '.'));
    if (rate == null || rate <= 0 || hours == null || hours <= 0) {
      setState(() => _error = 'Введи положительные числа');
      return;
    }

    final user = await StorageService.load();
    final msg = FuelService.recordInverter(user, rate, hours, _fuelType);
    await StorageService.save(user);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Инвертор')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('На каком топливе работал инвертор:',
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
            onSelectionChanged: (s) =>
                setState(() => _fuelType = s.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _rateCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Расход (л/час)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hoursCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Часов работы',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
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
