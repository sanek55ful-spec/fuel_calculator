import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_data.dart';
import '../models/trip.dart';
import '../utils/date_utils.dart';
import '../utils/fuel_type.dart';

class ExportService {

  // ================== TXT ==================

  static String buildMonthDump(UserData user, String monthKey) {
    final trips = user.trips
        .where((t) => getMonthKeyFromTrip(t) == monthKey)
        .toList()
      ..sort((a, b) =>
          DateTime.parse(a.iso).compareTo(DateTime.parse(b.iso)));

    final buf = StringBuffer();
    buf.writeln('ВЫГРУЗКА ЗА ${getMonthName(monthKey).toUpperCase()}');
    buf.writeln('═' * 36);
    buf.writeln();

    for (final t in trips) {
      buf.writeln(_formatTripLine(t));
    }

    buf.writeln();
    buf.writeln('СВОДКА ПО ТОПЛИВУ');
    buf.writeln('─' * 36);
    for (final type in FuelType.all) {
      final typed = trips.where((t) => t.fuelType == type).toList();
      if (typed.isEmpty) continue;
      final liters = typed.fold<double>(0,
          (s, t) => s + (t.liters ?? t.fuel ?? 0));
      final cost = typed.fold<double>(0, (s, t) => s + (t.cost ?? 0));
      buf.writeln('${FuelType.emoji(type)} ${FuelType.label(type)}: '
          '${liters.toStringAsFixed(1)} л'
          '${cost > 0 ? " → ${cost.toStringAsFixed(0)} ₽" : ""}');
    }

    buf.writeln();
    buf.writeln('Сформировано: ${nowDisplay()}');
    return buf.toString();
  }

  static String buildFullDump(UserData user) {
    final buf = StringBuffer();
    buf.writeln('ПОЛНАЯ ВЫГРУЗКА');
    buf.writeln('═' * 36);
    buf.writeln();

    final trips = [...user.trips]
      ..sort((a, b) =>
          DateTime.parse(a.iso).compareTo(DateTime.parse(b.iso)));

    String? lastMonth;
    for (final t in trips) {
      final mk = getMonthKeyFromTrip(t);
      if (mk != lastMonth) {
        buf.writeln();
        buf.writeln('— ${getMonthName(mk)} —');
        lastMonth = mk;
      }
      buf.writeln(_formatTripLine(t));
    }

    buf.writeln();
    buf.writeln('Сформировано: ${nowDisplay()}');
    return buf.toString();
  }

  static String buildFullReport(UserData user) {
    final buf = StringBuffer();
    buf.writeln('ОТЧЁТ ПО РАСХОДУ ТОПЛИВА');
    buf.writeln('═' * 36);
    buf.writeln();

    for (final type in FuelType.all) {
      final cons = user.consumptionFor(type);
      final actual = user.actualConsumptionFor(type);
      final price = user.priceFor(type);
      final fuel = user.fuelFor(type);

      buf.writeln('${FuelType.emoji(type)} ${FuelType.label(type)}');
      buf.writeln('• Расход (норма): '
          '${cons?.toStringAsFixed(1) ?? "—"} л/100 км');
      buf.writeln('• Расход (факт): '
          '${actual?.toStringAsFixed(2) ?? "—"} л/100 км');
      buf.writeln('• Цена: '
          '${price > 0 ? "${price.toStringAsFixed(2)} ₽/л" : "—"}');
      buf.writeln('• Остаток: ${fuel.toStringAsFixed(2)} л');
      buf.writeln();
    }

    if (user.inverterRate != null) {
      buf.writeln('Инвертор: ${user.inverterRate} л/час');
      buf.writeln();
    }

    buf.writeln('ИСТОРИЯ');
    buf.writeln('─' * 36);
    for (final t in user.trips) {
      buf.writeln(_formatTripLine(t));
    }
    buf.writeln();
    buf.writeln('Сформировано: ${nowDisplay()}');
    return buf.toString();
  }

  static String _formatTripLine(Trip t) {
    final fe = FuelType.emoji(t.fuelType);
    switch (t.type) {
      case 'refuel':
        final cost = t.cost != null
            ? ' = ${t.cost!.toStringAsFixed(0)} ₽'
            : '';
        final price = t.pricePerLiter != null
            ? ' (${t.pricePerLiter!.toStringAsFixed(2)} ₽/л)'
            : '';
        return '${t.date} | $fe Заправка +${t.liters} л$price$cost';
      case 'inverter':
        return '${t.date} | $fe Инвертор ${t.hours} ч × '
               '${t.rate} л/ч → ${t.fuel} л';
      case 'odometer':
        if (t.fromOdo != null) {
          return '${t.date} | $fe ${t.fromOdo} → ${t.toOdo} '
                 '(${t.distance} км) → ${t.fuel} л';
        }
        return '${t.date} | $fe Одометр: ${t.toOdo} км';
      case 'manual':
        return '${t.date} | $fe ${t.distance} км → ${t.fuel} л';
      default:
        return '${t.date} | $fe ${t.type}';
    }
  }
  // ================== CSV ==================

  static String buildCsv(UserData user, {String? monthKey}) {
    final trips = monthKey != null
        ? user.trips.where((t) => getMonthKeyFromTrip(t) == monthKey).toList()
        : [...user.trips];

    trips.sort((a, b) =>
        DateTime.parse(a.iso).compareTo(DateTime.parse(b.iso)));

    final rows = <List<dynamic>>[
      ['Дата', 'Тип', 'Топливо', 'Одометр', 'Пробег (км)',
       'Литры', 'Цена (₽/л)', 'Стоимость (₽)'],
    ];

    for (final t in trips) {
      rows.add([
        t.date,
        t.type,
        FuelType.label(t.fuelType),
        t.toOdo ?? '',
        t.distance ?? '',
        t.fuel ?? t.liters ?? '',
        t.pricePerLiter?.toStringAsFixed(2) ?? '',
        t.cost?.toStringAsFixed(2) ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  // ================== Excel ==================

  static Future<void> shareExcel(
      UserData user, String? monthKey, String filename) async {
    final excel = Excel.createExcel();
    final sheet = excel['Отчёт'];

    sheet.appendRow([
      TextCellValue('Дата'),
      TextCellValue('Тип'),
      TextCellValue('Топливо'),
      TextCellValue('Одометр'),
      TextCellValue('Пробег (км)'),
      TextCellValue('Литры'),
      TextCellValue('Цена (₽/л)'),
      TextCellValue('Стоимость (₽)'),
    ]);

    final trips = monthKey != null
        ? user.trips.where((t) => getMonthKeyFromTrip(t) == monthKey).toList()
        : [...user.trips];

    trips.sort((a, b) =>
        DateTime.parse(a.iso).compareTo(DateTime.parse(b.iso)));

    for (final t in trips) {
      sheet.appendRow([
        TextCellValue(t.date),
        TextCellValue(t.type),
        TextCellValue(FuelType.label(t.fuelType)),
        IntCellValue(t.toOdo ?? 0),
        DoubleCellValue(t.distance ?? 0),
        DoubleCellValue(t.fuel ?? t.liters ?? 0),
        DoubleCellValue(t.pricePerLiter ?? 0),
        DoubleCellValue(t.cost ?? 0),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Excel отчёт',
    );
  }

  // ================== PDF ==================

  static Future<void> sharePdf(
      UserData user, String? monthKey, String filename) async {
    final pdf = pw.Document();

    final trips = monthKey != null
        ? user.trips.where((t) => getMonthKeyFromTrip(t) == monthKey).toList()
        : [...user.trips];

    trips.sort((a, b) =>
        DateTime.parse(a.iso).compareTo(DateTime.parse(b.iso)));

    final title = monthKey != null
        ? 'Отчёт за ${getMonthName(monthKey)}'
        : 'Полный отчёт';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 16),
          ...FuelType.all.where((type) {
            return user.consumptionFor(type) != null ||
                user.priceFor(type) > 0;
          }).map((type) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              '${FuelType.label(type)}: '
              '${user.consumptionFor(type)?.toStringAsFixed(1) ?? "—"} л/100 км, '
              '${user.priceFor(type) > 0 ? "${user.priceFor(type).toStringAsFixed(2)} ₽/л" : "цена не задана"}, '
              'остаток ${user.fuelFor(type).toStringAsFixed(1)} л',
              style: const pw.TextStyle(fontSize: 11),
            ),
          )),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Дата', 'Тип', 'Топливо', 'Одометр',
                      'Пробег', 'Литры', 'Цена', 'Стоим.'],
            data: trips
                .map((t) => [
                      t.date,
                      t.type,
                      FuelType.label(t.fuelType),
                      t.toOdo?.toString() ?? '—',
                      t.distance?.toStringAsFixed(1) ?? '—',
                      (t.fuel ?? t.liters)?.toStringAsFixed(2) ?? '—',
                      t.pricePerLiter?.toStringAsFixed(2) ?? '—',
                      t.cost?.toStringAsFixed(0) ?? '—',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // ================== Универсальный share ==================

  static Future<void> shareTextAsFile(
      String content, String filename, String subject) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      subject: subject,
    );
  }
}
