import 'trip.dart';
import '../utils/fuel_type.dart';

class UserData {
  double? petrolConsumption;
  double? gasConsumption;
  double? dieselConsumption;

  double petrolPrice;
  double gasPrice;
  double dieselPrice;

  double petrolFuel;
  double gasFuel;
  double dieselFuel;

  double? inverterRate;
  int? lastOdometer;
  List<Trip> trips;

  UserData({
    this.petrolConsumption,
    this.gasConsumption,
    this.dieselConsumption,
    this.petrolPrice = 0,
    this.gasPrice = 0,
    this.dieselPrice = 0,
    this.petrolFuel = 0,
    this.gasFuel = 0,
    this.dieselFuel = 0,
    this.inverterRate,
    this.lastOdometer,
    List<Trip>? trips,
  }) : trips = trips ?? [];

  double? consumptionFor(String t) {
    switch (t) {
      case FuelType.gas: return gasConsumption;
      case FuelType.diesel: return dieselConsumption;
      default: return petrolConsumption;
    }
  }

  double priceFor(String t) {
    switch (t) {
      case FuelType.gas: return gasPrice;
      case FuelType.diesel: return dieselPrice;
      default: return petrolPrice;
    }
  }

  double fuelFor(String t) {
    switch (t) {
      case FuelType.gas: return gasFuel;
      case FuelType.diesel: return dieselFuel;
      default: return petrolFuel;
    }
  }

  void addFuel(String t, double amount) {
    switch (t) {
      case FuelType.gas: gasFuel += amount; break;
      case FuelType.diesel: dieselFuel += amount; break;
      default: petrolFuel += amount;
    }
  }

  double? actualConsumptionFor(String fuelType) {
    final typed = trips
        .where((t) => t.fuelType == fuelType || t.fuelType == FuelType.mixed)
        .toList()
      ..sort((a, b) => DateTime.parse(a.iso).compareTo(DateTime.parse(b.iso)));

    final odoTrips = typed
        .where((t) => t.type == 'odometer' && t.toOdo != null)
        .toList();

    if (odoTrips.length < 2) return null;

    final firstOdo = odoTrips.first.toOdo!;
    final lastOdo = odoTrips.last.toOdo!;
    final totalDistance = lastOdo - firstOdo;

    if (totalDistance <= 0) return null;

    final refuels = typed
        .where((t) => t.type == 'refuel' &&
            (t.fuelType == fuelType || t.fuelType == FuelType.mixed))
        .toList();

    if (refuels.length < 2) return null;

    double totalLiters = 0;
    for (var i = 1; i < refuels.length; i++) {
      totalLiters += refuels[i].liters ?? 0;
    }

    if (totalLiters <= 0) return null;

    return (totalLiters / totalDistance) * 100;
  }

  Map<String, dynamic> toJson() => {
    'petrolConsumption': petrolConsumption,
    'gasConsumption': gasConsumption,
    'dieselConsumption': dieselConsumption,
    'petrolPrice': petrolPrice,
    'gasPrice': gasPrice,
    'dieselPrice': dieselPrice,
    'petrolFuel': petrolFuel,
    'gasFuel': gasFuel,
    'dieselFuel': dieselFuel,
    'inverterRate': inverterRate,
    'lastOdometer': lastOdometer,
    'trips': trips.map((t) => t.toJson()).toList(),
  };

  factory UserData.fromJson(Map<String, dynamic> j) {
    final oldConsumption = j['consumption']?.toDouble();
    final oldFuel = (j['currentFuel'] ?? 0).toDouble();

    return UserData(
      petrolConsumption:
          j['petrolConsumption']?.toDouble() ?? oldConsumption,
      gasConsumption: j['gasConsumption']?.toDouble(),
      dieselConsumption: j['dieselConsumption']?.toDouble(),
      petrolPrice: (j['petrolPrice'] ?? 0).toDouble(),
      gasPrice: (j['gasPrice'] ?? 0).toDouble(),
      dieselPrice: (j['dieselPrice'] ?? 0).toDouble(),
      petrolFuel: (j['petrolFuel'] ?? oldFuel).toDouble(),
      gasFuel: (j['gasFuel'] ?? 0).toDouble(),
      dieselFuel: (j['dieselFuel'] ?? 0).toDouble(),
      inverterRate: j['inverterRate']?.toDouble(),
      lastOdometer: j['lastOdometer'],
      trips: (j['trips'] as List? ?? [])
          .map((t) => Trip.fromJson(t))
          .toList(),
    );
  }
}
