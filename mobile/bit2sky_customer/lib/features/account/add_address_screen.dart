import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/account_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/warm_scaffold.dart';

/// Add address with a FREE OpenStreetMap picker (flutter_map, no API key) +
/// GPS "use my location" + reverse geocoding — ported from PRESSO.
class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _map = MapController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  String _type = 'Home';
  bool _busyLoc = false;
  bool _saving = false;
  String? _error;

  static const _defaultCenter = LatLng(19.0330, 73.0297); // Navi Mumbai

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _busyLoc = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Location is off — enable GPS to use this.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('Location permission denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      try {
        _map.move(here, 16);
      } catch (_) {/* map not mounted yet */}
      await _fillFromLatLng(here);
    } catch (_) {
      _snack('Could not get your location. Try again.');
    } finally {
      if (mounted) setState(() => _busyLoc = false);
    }
  }

  Future<void> _useMapCenter() async {
    setState(() => _busyLoc = true);
    await _fillFromLatLng(_map.camera.center);
    if (mounted) setState(() => _busyLoc = false);
  }

  /// Reverse-geocode a point and populate the address fields.
  Future<void> _fillFromLatLng(LatLng p) async {
    try {
      final marks = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (marks.isEmpty || !mounted) return;
      final m = marks.first;
      final line1 = [m.subThoroughfare, m.thoroughfare, m.subLocality]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
      setState(() {
        if (line1.isNotEmpty) _line1.text = line1;
        _city.text = (m.locality?.isNotEmpty ?? false)
            ? m.locality!
            : (m.subAdministrativeArea ?? _city.text);
        if (m.administrativeArea?.isNotEmpty ?? false) _state.text = m.administrativeArea!;
        if (m.postalCode?.isNotEmpty ?? false) _pincode.text = m.postalCode!;
        _error = null;
      });
    } catch (_) {
      _snack('Got the pin but could not read the address — fill it manually.');
    }
  }

  Future<void> _save() async {
    if (_line1.text.trim().isEmpty || _pincode.text.trim().length != 6) {
      return setState(() => _error = 'Enter an address line and a 6-digit pincode.');
    }
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(addressProvider.notifier).add({
        'type': _type,
        'line1': _line1.text.trim(),
        if (_line2.text.trim().isNotEmpty) 'line2': _line2.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'pincode': _pincode.text.trim(),
      });
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Could not save the address. Try again.'; });
    }
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return WarmScaffold(
      title: 'Add address',
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Map picker (drag to move the pin) ──
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _map,
                  options: const MapOptions(
                    initialCenter: _defaultCenter,
                    initialZoom: 15,
                    interactionOptions:
                        InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bit2sky.customer',
                    ),
                  ],
                ),
                // Fixed centre pin — the map moves under it.
                const Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Icon(Icons.location_pin, size: 44, color: AppColors.teal700),
                ),
                if (_busyLoc)
                  Container(
                    color: Colors.white54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'loc',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.teal700,
                    onPressed: _busyLoc ? null : _useMyLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busyLoc ? null : _useMapCenter,
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('Use the pinned location'),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                TextField(
                    controller: _line1,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Address / flat / street *')),
                const SizedBox(height: AppSpacing.s12),
                TextField(
                    controller: _line2,
                    decoration: const InputDecoration(labelText: 'Area / landmark (optional)')),
                const SizedBox(height: AppSpacing.s12),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: _city,
                          decoration: const InputDecoration(labelText: 'City'))),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                      child: TextField(
                          controller: _state,
                          decoration: const InputDecoration(labelText: 'State'))),
                ]),
                const SizedBox(height: AppSpacing.s12),
                TextField(
                    controller: _pincode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration:
                        const InputDecoration(labelText: 'Pincode *', counterText: '')),
                const SizedBox(height: AppSpacing.s8),
                Text('Save as', style: AppTextStyles.label),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Home', 'Work', 'Other'].map((t) {
                    final on = _type == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: on,
                      onSelected: (_) => setState(() => _type = t),
                      selectedColor: AppColors.teal50,
                      labelStyle: TextStyle(
                          color: on ? AppColors.teal700 : AppColors.textPrimary,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w400),
                    );
                  }).toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Text(_error!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed)),
                ],
                const SizedBox(height: AppSpacing.s20),
                PrimaryButton(
                    label: _saving ? 'Saving…' : 'Save address',
                    loading: _saving,
                    onPressed: _saving ? null : _save),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
