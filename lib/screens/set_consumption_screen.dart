import 'package:flutter/material.dart';
import '../services/fuel_service.dart';
import '../services/storage_service.dart';
import '../utils/fuel_type.dart';

class SetConsumptionScreen extends StatefulWidget {
  const SetConsumptionScreen({super.key});

  @override
  State<SetConsumptionScreen> createState() => _SetConsumptionScreenState();
}

class _SetConsumptionScreenState extends State<SetConsumptionScreen> {
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
    if (user.petrolConsumption != null) {
      _petrolCtrl.text = user.petrolConsumption.toString();
    }
    if (user.gasConsumption != null) {
      _gasCtrl.text = user.gasConsumption.toString();
    }
    if (user.dieselConsumption != null) {
      _dieselCtrl.text = user.dieselConsumption.toString();
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
        FuelService.setConsumption(user, e.key, e.value!);
      }
    }

    await StorageService.save(user);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Расходы сохранены')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Установить расход')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_petrolCtrl, '⛽ Бензин (л/100 км)'),
          const SizedBox(height: 16),
          _field(_gasCtrl, '💨 Газ (л/100 км)'),
          const SizedBox(height: 16),
          _field(_dieselCtrl, '🛢️ Дизель (л/100 км)'),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить'),
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
