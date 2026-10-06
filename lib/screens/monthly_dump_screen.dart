import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';
import '../utils/date_utils.dart';

class MonthlyDumpScreen extends StatefulWidget {
  const MonthlyDumpScreen({super.key});

  @override
  State<MonthlyDumpScreen> createState() => _MonthlyDumpScreenState();
}

class _MonthlyDumpScreenState extends State<MonthlyDumpScreen> {
  UserData? _user;
  List<String> _months = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await StorageService.load();
    final set = <String>{};
    for (final t in u.trips) {
      set.add(getMonthKeyFromTrip(t));
    }
    final sorted = set.toList()
      ..sort((a, b) {
        final [m1, y1] = a.split('.').map(int.parse).toList();
        final [m2, y2] = b.split('.').map(int.parse).toList();
        if (y1 != y2) return y2 - y1;
        return m2 - m1;
      });
    setState(() {
      _user = u;
      _months = sorted;
    });
  }

  Future<void> _chooseFormat(String monthKey) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Выбери формат',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('TXT'),
              onTap: () => Navigator.pop(context, 'txt'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: const Text('Excel'),
              onTap: () => Navigator.pop(context, 'excel'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Все форматы'),
              onTap: () => Navigator.pop(context, 'all'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || _user == null) return;

    final safeKey = monthKey.replaceAll('.', '_');
    switch (choice) {
      case 'txt':
        await ExportService.shareTextAsFile(
          ExportService.buildMonthDump(_user!, monthKey),
          'fuel_$safeKey.txt',
          'TXT за ${getMonthName(monthKey)}',
        );
        break;
      case 'csv':
        await ExportService.shareTextAsFile(
          ExportService.buildCsv(_user!, monthKey: monthKey),
          'fuel_$safeKey.csv',
          'CSV за ${getMonthName(monthKey)}',
        );
        break;
      case 'excel':
        await ExportService.shareExcel(
            _user!, monthKey, 'fuel_$safeKey.xlsx');
        break;
      case 'pdf':
        await ExportService.sharePdf(
            _user!, monthKey, 'fuel_$safeKey.pdf');
        break;
      case 'all':
        await ExportService.shareTextAsFile(
          ExportService.buildMonthDump(_user!, monthKey),
          'fuel_$safeKey.txt', 'TXT');
        await ExportService.shareTextAsFile(
          ExportService.buildCsv(_user!, monthKey: monthKey),
          'fuel_$safeKey.csv', 'CSV');
        await ExportService.shareExcel(
            _user!, monthKey, 'fuel_$safeKey.xlsx');
        await ExportService.sharePdf(
            _user!, monthKey, 'fuel_$safeKey.pdf');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Выгрузка')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Выбери месяц:',
                style: TextStyle(fontSize: 15)),
          ),
          ..._months.map((m) => ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(getMonthName(m)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _chooseFormat(m),
              )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('Полная выгрузка (TXT)'),
            onTap: () async {
              await ExportService.shareTextAsFile(
                ExportService.buildFullDump(_user!),
                'fuel_full.txt',
                'Полная выгрузка',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Полный отчёт (TXT)'),
            onTap: () async {
              await ExportService.shareTextAsFile(
                ExportService.buildFullReport(_user!),
                'fuel_report.txt',
                'Полный отчёт',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Вся история (CSV)'),
            onTap: () async {
              await ExportService.shareTextAsFile(
                ExportService.buildCsv(_user!),
                'fuel_all.csv',
                'CSV вся история',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: const Text('Вся история (Excel)'),
            onTap: () async {
              await ExportService.shareExcel(
                  _user!, null, 'fuel_all.xlsx');
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Вся история (PDF)'),
            onTap: () async {
              await ExportService.sharePdf(
                  _user!, null, 'fuel_all.pdf');
            },
          ),
        ],
      ),
    );
  }
}
