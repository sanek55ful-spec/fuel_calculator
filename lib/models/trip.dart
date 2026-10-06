class Trip {
  final String date;
  final String iso;
  final String type;
  final String fuelType;
  final double? distance;
  final int? fromOdo;
  final int? toOdo;
  final double? fuel;
  final double? liters;
  final double? rate;
  final double? hours;
  final double? pricePerLiter;

  Trip({
    required this.date,
    required this.iso,
    required this.type,
    required this.fuelType,
    this.distance,
    this.fromOdo,
    this.toOdo,
    this.fuel,
    this.liters,
    this.rate,
    this.hours,
    this.pricePerLiter,
  });

  double? get cost {
    if (pricePerLiter == null) return null;
    final volume = liters ?? fuel;
    if (volume == null) return null;
    return volume * pricePerLiter!;
  }

  Map<String, dynamic> toJson() => {
    'date': date, 'iso': iso, 'type': type, 'fuelType': fuelType,
    'distance': distance, 'fromOdo': fromOdo, 'toOdo': toOdo,
    'fuel': fuel, 'liters': liters, 'rate': rate, 'hours': hours,
    'pricePerLiter': pricePerLiter,
  };

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    date: j['date'],
    iso: j['iso'],
    type: j['type'],
    fuelType: j['fuelType'] ?? 'petrol',
    distance: j['distance']?.toDouble(),
    fromOdo: j['fromOdo'],
    toOdo: j['toOdo'],
    fuel: j['fuel']?.toDouble(),
    liters: j['liters']?.toDouble(),
    rate: j['rate']?.toDouble(),
    hours: j['hours']?.toDouble(),
    pricePerLiter: j['pricePerLiter']?.toDouble(),
  );
}
