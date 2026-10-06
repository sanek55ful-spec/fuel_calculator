import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/user_data.dart';
import 'set_consumption_screen.dart';
import 'set_prices_screen.dart';
import 'odometer_screen.dart';
import 'inverter_screen.dart';
import 'refuel_screen.dart';
import 'manual_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'monthly_report_screen.dart';
import 'monthly_dump_screen.dart';
import 'monthly_chart_screen.dart';
import 'comparison_screen.dart';
import 'reminder_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserData? _user;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final u = await StorageService.load();
    setState(() => _user = u);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => screen));
    _refresh();
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Сбросить всё?'),
        content: const Text('Все данные будут удалены безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сбросить',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.reset();
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final u = _user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор топлива'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(child: _fuelCard('⛽ Бензин', u.petrolFuel, Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _fuelCard('💨 Газ', u.gasFuel, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _fuelCard('🛢️ Дизель', u.dieselFuel, Colors.brown)),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(10),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.9,
              children: [
                _btn(Icons.speed, 'Одометр',
                    () => _open(const OdometerScreen())),
                _btn(Icons.local_gas_station, 'Заправка',
                    () => _open(const RefuelScreen())),
                _btn(Icons.bolt, 'Инвертор',
                    () => _open(const InverterScreen())),
                _btn(Icons.calculate, 'Вручную',
                    () => _open(const ManualScreen())),
                _btn(Icons.history, 'История',
                    () => _open(const HistoryScreen())),
                _btn(Icons.bar_chart, 'Статистика',
                    () => _open(const StatsScreen())),
                _btn(Icons.calendar_month, 'Отчёт по месяцам',
                    () => _open(const MonthlyReportScreen())),
                _btn(Icons.show_chart, 'График',
                    () => _open(const MonthlyChartScreen())),
                _btn(Icons.download, 'Выгрузка',
                    () => _open(const MonthlyDumpScreen())),
                _btn(Icons.compare_arrows, 'Сравнение',
                    () => _open(const ComparisonScreen()),
                    color: Colors.green.shade50),
                _btn(Icons.attach_money, 'Цены',
                    () => _open(const SetPricesScreen())),
                _btn(Icons.settings, 'Расход',
                    () => _open(const SetConsumptionScreen())),
                _btn(Icons.notifications, 'Напоминания',
                    () => _open(const ReminderSettingsScreen())),
                _btn(Icons.delete, 'Сбросить', _reset,
                    color: Colors.red.shade50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fuelCard(String label, double value, Color color) {
    final neg = value < 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: neg ? Colors.red.shade50 : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: neg ? Colors.red : color,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(1)} л',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: neg ? Colors.red : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return Material(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
