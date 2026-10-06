import '../models/user_data.dart';
import '../models/trip.dart';
import '../utils/date_utils.dart';
import '../utils/fuel_type.dart';

class FuelService {

  static String setConsumption(UserData user, String fuelType, double value) {
    switch (fuelType) {
      case FuelType.gas: user.gasConsumption = value; break;
      case FuelType.diesel: user.dieselConsumption = value; break;
      default: user.petrolConsumption = value;
    }
    return '✅ Расход ${FuelType.label(fuelType).toLowerCase()}: '
           '$value л/100 км';
  }

  static String setPrice(UserData user, String fuelType, double price) {
    switch (fuelType) {
      case FuelType.gas: user.gasPrice = price; break;
      case FuelType.diesel: user.dieselPrice = price; break;
      default: user.petrolPrice = price;
    }
    return '✅ Цена ${FuelType.label(fuelType).toLowerCase()}: '
           '$price ₽/л';
  }

  static String recordOdometer(
      UserData user, int currentOdo, String fuelType) {
    final cons = user.consumptionFor(fuelType);
    if (cons == null) {
      return '❗ Сначала установи расход '
             '${FuelType.label(fuelType).toLowerCase()}!';
    }
    if (user.lastOdometer != null && currentOdo <= user.lastOdometer!) {
      return '❌ Пробег должен быть больше ${user.lastOdometer} км';
    }

    int distance = 0;
    int? fromOdo;
    if (user.lastOdometer != null) {
      distance = currentOdo - user.lastOdometer!;
      fromOdo = user.lastOdometer;
    }

    final fuelUsed = (distance / 100) * cons;
    user.addFuel(fuelType, -fuelUsed);

    user.trips.add(Trip(
      date: nowDisplay(),
      iso: DateTime.now().toUtc().toIso8601String(),
      type: 'odometer',
      fuelType: fuelType,
      distance: distance.toDouble(),
      fromOdo: fromOdo,
      toOdo: currentOdo,
      fuel: double.parse(fuelUsed.toStringAsFixed(2)),
    ));
    user.lastOdometer = currentOdo;

    final label = FuelType.label(fuelType).toLowerCase();
    if (distance > 0) {
      return '✅ Одометр записан ($label)!\n\n'
          'Пробег: $currentOdo км\n'
          'Пройдено: $distance км\n'
          '⛽ Потрачено: ${fuelUsed.toStringAsFixed(2)} л\n'
          'Остаток: ${user.fuelFor(fuelType).toStringAsFixed(2)} л';
    }
    return '✅ Первая запись: $currentOdo км';
  }

  static String recordOdometerMixed(
      UserData user, int currentOdo, double petrolRatio) {
    if (user.petrolConsumption == null || user.gasConsumption == null) {
      return '❗ Установи расход и для бензина, и для газа!';
    }
    if (user.lastOdometer != null && currentOdo <= user.lastOdometer!) {
      return '❌ Пробег должен быть больше ${user.lastOdometer} км';
    }

    int distance = 0;
    int? fromOdo;
    if (user.lastOdometer != null) {
      distance = currentOdo - user.lastOdometer!;
      fromOdo = user.lastOdometer;
    }

    final petrolDist = distance * petrolRatio;
    final gasDist = distance * (1 - petrolRatio);

    final petrolUsed = (petrolDist / 100) * user.petrolConsumption!;
    final gasUsed = (gasDist / 100) * user.gasConsumption!;

    user.petrolFuel -= petrolUsed;
    user.gasFuel -= gasUsed;

    user.trips.add(Trip(
      date: nowDisplay(),
      iso: DateTime.now().toUtc().toIso8601String(),
      type: 'odometer',
      fuelType: 'mixed',
      distance: distance.toDouble(),
      fromOdo: fromOdo,
      toOdo: currentOdo,
      fuel: double.parse((petrolUsed + gasUsed).toStringAsFixed(2)),
    ));
    user.lastOdometer = currentOdo;

    return '✅ Смешанная поездка записана!\n\n'
        'Пробег: $currentOdo км (+$distance)\n'
        '⛽ Бензин: ${petrolUsed.toStringAsFixed(2)} л '
        '(остаток ${user.petrolFuel.toStringAsFixed(2)} л)\n'
        '💨 Газ: ${gasUsed.toStringAsFixed(2)} л '
        '(остаток ${user.gasFuel.toStringAsFixed(2)} л)';
  }

  static String recordRefuel(
    UserData user,
    String fuelType,
    double liters, {
    double? customPrice,
  }) {
    user.addFuel(fuelType, liters);
    final price = customPrice ?? user.priceFor(fuelType);

    user.trips.add(Trip(
      date: nowDisplay(),
      iso: DateTime.now().toUtc().toIso8601String(),
      type: 'refuel',
      fuelType: fuelType,
      liters: liters,
      pricePerLiter: price > 0 ? price : null,
    ));

    final label = FuelType.label(fuelType).toLowerCase();
    final total = price > 0
        ? ' = ${(liters * price).toStringAsFixed(0)} ₽'
        : '';
    return '✅ Заправка записана ($label)!\n\n'
        'Залито: +$liters л$total\n'
        'Остаток: ${user.fuelFor(fuelType).toStringAsFixed(2)} л';
  }

  static String recordInverter(UserData user, double rate, double hours,
      String fuelType) {
    user.inverterRate = rate;
    final fuelUsed = rate * hours;
    user.addFuel(fuelType, -fuelUsed);

    user.trips.add(Trip(
      date: nowDisplay(),
      iso: DateTime.now().toUtc().toIso8601String(),
      type: 'inverter',
      fuelType: fuelType,
      rate: rate,
      hours: hours,
      fuel: double.parse(fuelUsed.toStringAsFixed(2)),
    ));

    final label = FuelType.label(fuelType).toLowerCase();
    return '✅ Инвертор записан!\n\n'
        'Расход: $rate л/час\n'
        'Время: $hours ч\n'
        '⛽ Потрачено: ${fuelUsed.toStringAsFixed(2)} л ($label)\n'
        'Остаток: ${user.fuelFor(fuelType).toStringAsFixed(2)} л';
  }

  static String recordManual(
      UserData user, double distance, String fuelType) {
    final cons = user.consumptionFor(fuelType);
    if (cons == null) {
      return '❗ Сначала установи расход '
             '${FuelType.label(fuelType).toLowerCase()}!';
    }

    final fuelUsed = (distance / 100) * cons;
    user.addFuel(fuelType, -fuelUsed);

    user.trips.add(Trip(
      date: nowDisplay(),
      iso: DateTime.now().toUtc().toIso8601String(),
      type: 'manual',
      fuelType: fuelType,
      distance: distance,
      fuel: double.parse(fuelUsed.toStringAsFixed(2)),
    ));

    final label = FuelType.label(fuelType).toLowerCase();
    return '✅ Поездка сохранена ($label)!\n\n'
        'Пройдено: $distance км\n'
        '⛽ Потрачено: ${fuelUsed.toStringAsFixed(2)} л\n'
        'Остаток: ${user.fuelFor(fuelType).toStringAsFixed(2)} л';
  }

  static String getFuelStatus(UserData user) {
    final buf = StringBuffer('🛢️ Остаток топлива:\n\n');
    for (final t in FuelType.all) {
      final f = user.fuelFor(t);
      final mark = f >= 0 ? '' : 'МИНУС ';
      buf.writeln('${FuelType.emoji(t)} ${FuelType.label(t)}: '
          '$mark${f.abs().toStringAsFixed(2)} л');
    }
    return buf.toString().trim();
  }

  static double? costPer100Km(UserData user, String fuelType) {
    final cons = user.consumptionFor(fuelType);
    final price = user.priceFor(fuelType);
    if (cons == null || price <= 0) return null;
    return cons * price;
  }
}
