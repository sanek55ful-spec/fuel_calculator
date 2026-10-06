import '../models/trip.dart';

const _months = {
  1: 'Январь', 2: 'Февраль', 3: 'Март', 4: 'Апрель',
  5: 'Май', 6: 'Июнь', 7: 'Июль', 8: 'Август',
  9: 'Сентябрь', 10: 'Октябрь', 11: 'Ноябрь', 12: 'Декабрь',
};

String nowDisplay() {
  final n = DateTime.now();
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(n.day)}.${p(n.month)}.${n.year}, '
         '${p(n.hour)}:${p(n.minute)}:${p(n.second)}';
}

String getMonthKeyFromTrip(Trip t) {
  final d = DateTime.parse(t.iso).toLocal();
  return '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

String getMonthName(String key) {
  final parts = key.split('.');
  return '${_months[int.parse(parts[0])]} ${parts[1]}';
}

String shortDate(Trip t) {
  final d = DateTime.parse(t.iso).toLocal();
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(d.day)}.${p(d.month)}.${d.year.toString().substring(2)}';
}
