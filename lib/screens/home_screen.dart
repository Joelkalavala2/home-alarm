import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/app_provider.dart';
import '../services/alarm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlarmService _alarmService = AlarmService();
  GoogleMapController? _mapController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _alarmService.init();
    _requestPermissionsAndStart();
  }

  // ─── Request permissions then start tracking ───────────────
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

  // ─── Alarm popup dialog ────────────────────────────────────
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

  // ═══════════════════════════════════════════════════════════
  // TAB 1 — HOME
  // ═══════════════════════════════════════════════════════════
  Widget _buildHomeTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            // Gradient App Bar
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

                  // 📍 Current Location Card
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

                  // 🏠 Home Location Card
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

                  // 📏 Distance Card
                  _distanceCard(provider),
                  const SizedBox(height: 20),

                  // Set Home Button
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

                  // Alarm Toggle
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

  // ═══════════════════════════════════════════════════════════
  // TAB 2 — MAP
  // ═══════════════════════════════════════════════════════════
  Widget _buildMapTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final hasLocation = provider.currentLat != null;

        return Stack(
          children: [
            hasLocation
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                          provider.currentLat!, provider.currentLng!),
                      zoom: 13,
                    ),
                    onMapCreated: (c) => _mapController = c,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: {
                      if (provider.homeLat != null)
                        Marker(
                          markerId: const MarkerId('home'),
                          position: LatLng(
                              provider.homeLat!, provider.homeLng!),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueViolet),
                          infoWindow:
                              const InfoWindow(title: '🏠 Home'),
                        ),
                    },
                    circles: {
                      if (provider.homeLat != null)
                        Circle(
                          circleId: const CircleId('radius'),
                          center: LatLng(
                              provider.homeLat!, provider.homeLng!),
                          radius: provider.selectedRadius * 1000,
                          fillColor: const Color(0xFF7C3AED).withOpacity(0.15),
                          strokeColor: const Color(0xFF7C3AED),
                          strokeWidth: 2,
                        ),
                    },
                  )
                : const Center(child: CircularProgressIndicator()),

            // Map top label
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
                      ? '📍 Set your home location first'
                      : '🟣 Purple circle = ${provider.selectedRadius.toInt()} km alarm zone',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3 — SETTINGS
  // ═══════════════════════════════════════════════════════════
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

                  // Radius Selector
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

                  // Alarm toggle
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

                  // Tracking toggle
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

                  // App info
                  Center(
                    child: Text(
                      'Home Alarm v1.0.0\nMade with Flutter ❤️',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 12),
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

  // ═══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════

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
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
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
        side: BorderSide(
            color: const Color(0xFFF59E0B).withOpacity(0.3)),
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
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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