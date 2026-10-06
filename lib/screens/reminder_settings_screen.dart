import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await NotificationService.isEnabled();
    final t = await NotificationService.getTime();
    if (!mounted) return;
    setState(() {
      _enabled = e;
      _time = t;
      _loading = false;
    });
  }

  Future<void> _toggle(bool v) async {
    setState(() => _enabled = v);
    if (v) {
      await NotificationService.enable(_time.hour, _time.minute);
    } else {
      await NotificationService.disable();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            v ? '✅ Напоминание включено' : '🔕 Напоминание выключено'),
      ),
    );
  }

  Future<void> _pickTime() async {
    final p = await showTimePicker(context: context, initialTime: _time);
    if (p == null) return;
    setState(() => _time = p);
    await NotificationService.updateTime(p.hour, p.minute);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🕐 ${p.hour.toString().padLeft(2, '0')}:'
          '${p.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final timeStr = '${_time.hour.toString().padLeft(2, '0')}:'
                    '${_time.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Напоминания')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Ежедневное напоминание',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Напомнить записать одометр'),
            secondary: Icon(
              _enabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: _enabled ? Colors.deepOrange : Colors.grey,
            ),
            value: _enabled,
            onChanged: _toggle,
          ),
          if (_enabled)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Время напоминания'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(timeStr,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange)),
              ),
              onTap: _pickTime,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.send),
            title: const Text('Показать уведомление сейчас'),
            onTap: () async {
              await NotificationService.showNow();
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '• Уведомление приходит каждый день в выбранное время\n'
              '• Работает, даже если приложение закрыто\n'
              '• Восстанавливается после перезагрузки телефона',
              style: TextStyle(
                  color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
