import 'package:flutter/material.dart';
import '../services/fuel_service.dart';
import '../services/storage_service.dart';
import '../utils/fuel_type.dart';

class RefuelScreen extends StatefulWidget {
  const RefuelScreen({super.key});

  @override
  State<RefuelScreen> createState() => _RefuelScreenState();
}

class _RefuelScreenState extends State<RefuelScreen> {
  final _litersCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _fuelType = FuelType.petrol;
  bool _customPrice = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDefaultPrice();
  }

  Future<void> _loadDefaultPrice() async {
    final user = await StorageService.load();
    final p = user.priceFor(_fuelType);
    if (p > 0) {
      _priceCtrl.text = p.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _litersCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final liters = double.tryParse(_litersCtrl.text.replaceAll(',', '.'));
    if (liters == null || liters <= 0) {
      setState(() => _error = 'Введи положительное число литров');
      return;
    }

    double? customPrice;
    if (_customPrice) {
      customPrice = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
      if (customPrice == null || customPrice <= 0) {
        setState(() => _error = 'Введи цену или отключи ручной ввод');
        return;
      }
    }

    final user = await StorageService.load();
    final msg = FuelService.recordRefuel(
      user,
      _fuelType,
      liters,
      customPrice: customPrice,
    );
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
      appBar: AppBar(title: const Text('Заправка')),
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
            onSelectionChanged: (s) async {
              setState(() => _fuelType = s.first);
              await _loadDefaultPrice();
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _litersCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Литров',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_gas_station),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Указать цену вручную'),
            subtitle: const Text(
                'Пригодится, если цена на АЗС отличается от сохранённой'),
            value: _customPrice,
            onChanged: (v) => setState(() => _customPrice = v),
          ),
          if (_customPrice)
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Цена (₽/л)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Заправить'),
            ),
          ),
        ],
      ),
    );
  }
}
