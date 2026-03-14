import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/app_provider.dart';
import '../services/alarm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlarmService _alarmService = AlarmService();
  final MapController _mapController = MapController();
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _alarmService.init();
    _requestPermissionsAndStart();
  }

  Future<void> _requestPermissionsAndStart() async {
    final locationStatus = await Permission.location.request();
    if (locationStatus.isGranted) {
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      await provider.startTracking((double dist) {
        _alarmService.triggerAlarm(dist);
        _showAlarmDialog(dist);
      });
    } else {
      _showPermissionDeniedSnack();
    }
  }

  void _showPermissionDeniedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Location permission is required!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showAlarmDialog(double dist) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🏠 Almost Home!', style: TextStyle(fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home, size: 60, color: Color(0xFF7C3AED)),
            const SizedBox(height: 12),
            Text(
              'You are ${dist.toStringAsFixed(2)} km from home!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _alarmService.stopAlarm();
              Navigator.pop(context);
            },
            child: const Text('Dismiss', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildHomeTab(),
          _buildMapTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF7C3AED).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF7C3AED)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF7C3AED)),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF7C3AED)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // ═══ TAB 1 — HOME ═══
  Widget _buildHomeTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('🏠 Home Alarm',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            provider.isTracking
                                ? '🟢 Tracking your location...'
                                : '🔴 Tracking stopped',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _infoCard(
                    bgColor: const Color(0xFFECFDF5),
                    borderColor: const Color(0xFF10B981),
                    icon: '📍',
                    label: 'CURRENT LOCATION',
                    value: provider.currentLat == null
                        ? 'Fetching GPS...'
                        : '${provider.currentLat!.toStringAsFixed(5)}, '
                            '${provider.currentLng!.toStringAsFixed(5)}',
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    bgColor: const Color(0xFFEFF6FF),
                    borderColor: const Color(0xFF3B82F6),
                    icon: '🏠',
                    label: 'HOME LOCATION',
                    value: provider.homeLat == null
                        ? 'Not set — tap button below'
                        : '${provider.homeLat!.toStringAsFixed(5)}, '
                            '${provider.homeLng!.toStringAsFixed(5)}',
                  ),
                  const SizedBox(height: 12),
                  _distanceCard(provider),
                  const SizedBox(height: 20),
                  _gradientButton(
                    label: '📌  SET CURRENT AS HOME',
                    onTap: () async {
                      final ok = await provider.setHomeLocation();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? '✅ Home location saved!'
                              : '❌ GPS not ready yet'),
                          backgroundColor:
                              ok ? const Color(0xFF7C3AED) : Colors.red,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _alarmToggleCard(provider),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══ TAB 2 — MAP (OpenStreetMap) ═══
  Widget _buildMapTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final hasLocation = provider.currentLat != null;
        final center = hasLocation
            ? LatLng(provider.currentLat!, provider.currentLng!)
            : const LatLng(17.3850, 78.4867);

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.myapp',
                ),
                if (provider.homeLat != null) ...[
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(provider.homeLat!, provider.homeLng!),
                        radius: provider.selectedRadius * 1000,
                        useRadiusInMeter: true,
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        borderColor: const Color(0xFF7C3AED),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(provider.homeLat!, provider.homeLng!),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.home,
                            color: Color(0xFF7C3AED), size: 40),
                      ),
                    ],
                  ),
                ],
                if (hasLocation)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin,
                            color: Colors.red, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8)
                  ],
                ),
                child: Text(
                  provider.homeLat == null
                      ? '📍 Go to Home tab and set your home location'
                      : '🟣 Purple circle = ${provider.selectedRadius.toInt()} km alarm zone',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF7C3AED),
                onPressed: () {
                  if (hasLocation) {
                    _mapController.move(center, 13);
                  }
                },
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══ TAB 3 — SETTINGS ═══
  Widget _buildSettingsTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Settings',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF7C3AED),
              pinned: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _settingsCard(
                    title: '⚙️ Alarm Radius',
                    child: Column(
                      children: [2.0, 3.0].map((r) {
                        return RadioListTile<double>(
                          title: Text('${r.toInt()} km'),
                          subtitle: Text(r == 2.0
                              ? 'Trigger when 2km from home'
                              : 'Trigger when 3km from home'),
                          value: r,
                          groupValue: provider.selectedRadius,
                          activeColor: const Color(0xFF7C3AED),
                          onChanged: (v) => provider.setRadius(v!),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _settingsCard(
                    title: '🔔 Alarm',
                    child: SwitchListTile(
                      title: const Text('Enable Alarm'),
                      subtitle: Text(provider.alarmEnabled
                          ? 'Will alert when near home'
                          : 'Alarm is disabled'),
                      value: provider.alarmEnabled,
                      activeColor: const Color(0xFF7C3AED),
                      onChanged: provider.toggleAlarm,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _settingsCard(
                    title: '📡 Tracking',
                    child: SwitchListTile(
                      title: const Text('Location Tracking'),
                      subtitle: Text(provider.isTracking
                          ? 'Active — checking every 30s'
                          : 'Stopped'),
                      value: provider.isTracking,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        if (val) {
                          _requestPermissionsAndStart();
                        } else {
                          provider.stopTracking();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Home Alarm v1.0.0\nMade with Flutter ❤️',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══ SHARED WIDGETS ═══
  Widget _infoCard({
    required Color bgColor,
    required Color borderColor,
    required String icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor.withOpacity(0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$icon  $label',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: borderColor)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _distanceCard(AppProvider provider) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📏  DISTANCE TO HOME',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFD97706))),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  provider.homeLat == null
                      ? '--'
                      : provider.distanceKm.toStringAsFixed(2),
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: provider.distanceColor),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('km',
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.distanceProgress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor:
                    AlwaysStoppedAnimation(provider.distanceColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.homeLat == null
                  ? 'Set home location to start'
                  : provider.distanceKm <= provider.selectedRadius
                      ? '🎉 You\'re in the alarm zone!'
                      : '${(provider.distanceKm - provider.selectedRadius).toStringAsFixed(1)} km until alarm triggers',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton(
      {required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
      ),
    );
  }

  Widget _alarmToggleCard(AppProvider provider) {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('🔔 Alarm',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(provider.alarmEnabled
            ? 'Will alert when within ${provider.selectedRadius.toInt()} km'
            : 'Alarm is OFF'),
        value: provider.alarmEnabled,
        activeColor: const Color(0xFF7C3AED),
        onChanged: provider.toggleAlarm,
      ),
    );
  }

  Widget _settingsCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _alarmService.dispose();
    super.dispose();
  }
}
