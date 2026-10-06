import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';

class StorageService {
  static const _key = 'fuel_user_data';
  static const _maxTrips = 2000;

  static Future<UserData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return UserData();
    return UserData.fromJson(jsonDecode(json));
  }

  static Future<void> save(UserData data) async {
    if (data.trips.length > _maxTrips) {
      data.trips = data.trips.sublist(data.trips.length - _maxTrips);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
