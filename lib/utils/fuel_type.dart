import 'package:flutter/material.dart';

class FuelType {
  static const petrol = 'petrol';
  static const gas = 'gas';
  static const diesel = 'diesel';
  static const mixed = 'mixed';

  static const all = [petrol, gas, diesel];

  static String label(String type) {
    switch (type) {
      case gas: return 'Газ';
      case diesel: return 'Дизель';
      case mixed: return 'Смешанно';
      default: return 'Бензин';
    }
  }

  static String emoji(String type) {
    switch (type) {
      case gas: return '💨';
      case diesel: return '🛢️';
      case mixed: return '🔀';
      default: return '⛽';
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case gas: return Icons.propane_tank;
      case diesel: return Icons.local_shipping;
      default: return Icons.local_gas_station;
    }
  }

  static Color color(String type) {
    switch (type) {
      case gas: return Colors.green;
      case diesel: return Colors.brown;
      default: return Colors.orange;
    }
  }
}
