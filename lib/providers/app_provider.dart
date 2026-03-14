import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

class AppProvider extends ChangeNotifier {
  double? currentLat, currentLng;
  double? homeLat, homeLng;
  double distanceKm = 0.0;
  double selectedRadius = 2.0; // km
  bool alarmEnabled = true;
  bool alarmTriggered = false;
  bool isTracking = false;
  Timer? _timer;

  AppProvider() {
    _loadPreferences();
  }

  // ─── Load saved data ───────────────────────────────────────
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    homeLat = prefs.getDouble('homeLat');
    homeLng = prefs.getDouble('homeLng');
    selectedRadius = prefs.getDouble('radius') ?? 2.0;
    alarmEnabled = prefs.getBool('alarmEnabled') ?? true;
    notifyListeners();
  }

  // ─── Save home location ────────────────────────────────────
  Future<bool> setHomeLocation() async {
    if (currentLat == null) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('homeLat', currentLat!);
    await prefs.setDouble('homeLng', currentLng!);
    homeLat = currentLat;
    homeLng = currentLng;
    alarmTriggered = false;
    notifyListeners();
    return true;
  }

  // ─── Start GPS tracking ────────────────────────────────────
  Future<void> startTracking(Function(double) onAlarm) async {
    isTracking = true;
    notifyListeners();
    await _checkLocation(onAlarm);
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkLocation(onAlarm),
    );
  }

  void stopTracking() {
    _timer?.cancel();
    isTracking = false;
    notifyListeners();
  }

  // ─── GPS check ────────────────────────────────────────────
  Future<void> _checkLocation(Function(double) onAlarm) async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      currentLat = pos.latitude;
      currentLng = pos.longitude;

      if (homeLat != null && homeLng != null) {
        distanceKm = _calculateDistance(
          currentLat!, currentLng!, homeLat!, homeLng!,
        );

        // Trigger alarm
        if (alarmEnabled && distanceKm <= selectedRadius && !alarmTriggered) {
          alarmTriggered = true;
          onAlarm(distanceKm);
        }

        // Reset trigger if moved far away
        if (distanceKm > selectedRadius + 0.5) {
          alarmTriggered = false;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  // ─── Haversine formula ─────────────────────────────────────
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    double dLat = _toRad(lat2 - lat1);
    double dLon = _toRad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  // ─── Settings ──────────────────────────────────────────────
  Future<void> setRadius(double r) async {
    selectedRadius = r;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('radius', r);
    notifyListeners();
  }

  Future<void> toggleAlarm(bool val) async {
    alarmEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarmEnabled', val);
    notifyListeners();
  }

  // Progress for distance bar (0.0 → 1.0)
  double get distanceProgress {
    if (homeLat == null) return 0.0;
    return (1 - (distanceKm / (selectedRadius * 5))).clamp(0.0, 1.0);
  }

  // Color based on distance
  Color get distanceColor {
    if (homeLat == null) return Colors.grey;
    if (distanceKm <= selectedRadius) return const Color(0xFF10B981);
    if (distanceKm <= selectedRadius * 2) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}