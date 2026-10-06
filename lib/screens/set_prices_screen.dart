import 'package:flutter/material.dart';
import '../services/fuel_service.dart';
import '../services/storage_service.dart';
import '../utils/fuel_type.dart';

class SetPricesScreen extends StatefulWidget {
  const SetPricesScreen({super.key});

  @override
  State<SetPricesScreen> createState() => _SetPricesScreenState();
}

class _SetPricesScreenState extends State<SetPricesScreen> {
  final _petrolCtrl = TextEditingController();
  final _gasCtrl = TextEditingController();
  final _dieselCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await StorageService.load();
    if (user.petrolPrice > 0) {
      _petrolCtrl.text = user.petrolPrice.toStringAsFixed(2);
    }
    if (user.gasPrice > 0) {
      _gasCtrl.text = user.gasPrice.toStringAsFixed(2);
    }
    if (user.dieselPrice > 0) {
      _dieselCtrl.text = user.dieselPrice.toStringAsFixed(2);
    }
    setState(() {});
  }

  Future<void> _save() async {
    final user = await StorageService.load();
    final values = {
      FuelType.petrol: double.tryParse(_petrolCtrl.text.replaceAll(',', '.')),
      FuelType.gas: double.tryParse(_gasCtrl.text.replaceAll(',', '.')),
      FuelType.diesel: double.tryParse(_dieselCtrl.text.replaceAll(',', '.')),
    };
    for (final e in values.entries) {
      if (e.value != null && e.value! > 0) {
        FuelService.setPrice(user, e.key, e.value!);
      }
    }
    await StorageService.save(user);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Цены сохранены')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Цены за литр')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Используются для расчёта стоимости. При заправке можно указать другую цену.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _field(_petrolCtrl, '⛽ Бензин (₽/л)'),
          const SizedBox(height: 16),
          _field(_gasCtrl, '💨 Газ (₽/л)'),
          const SizedBox(height: 16),
          _field(_dieselCtrl, '🛢️ Дизель (₽/л)'),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить цены'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
