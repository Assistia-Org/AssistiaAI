import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

const _kMapsApiKey = 'AIzaSyBpthuDO-1VN7C8W9WGh8Wu4uVdZuJghz0';

class LocationResult {
  final double lat;
  final double lng;
  final String address;

  LocationResult({required this.lat, required this.lng, required this.address});
}

// ─── Place Prediction Model ───────────────────────────────────────────────────
class _PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullDescription;

  _PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullDescription,
  });
}

class _PlacesResult {
  final List<_PlacePrediction> predictions;
  final String? errorMessage; // null = OK
  _PlacesResult({required this.predictions, this.errorMessage});
}

// ─── API Helpers ──────────────────────────────────────────────────────────────
Future<_PlacesResult> _autocomplete(String input) async {
  if (input.trim().length < 2) return _PlacesResult(predictions: []);

  final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
    'input': input,
    'language': 'tr',
    'key': _kMapsApiKey,
  });

  try {
    final res = await http.get(uri).timeout(const Duration(seconds: 6));
    final data = json.decode(res.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'UNKNOWN';
    final apiErrorMsg = data['error_message'] as String?;

    debugPrint('[Places API] status=$status error=$apiErrorMsg');

    if (status == 'ZERO_RESULTS') return _PlacesResult(predictions: []);
    if (status == 'OK') {
      final predictions = (data['predictions'] as List<dynamic>).take(5).map((p) {
        final structured = p['structured_formatting'] as Map<String, dynamic>?;
        return _PlacePrediction(
          placeId: p['place_id'] as String,
          mainText: structured?['main_text'] as String? ?? p['description'],
          secondaryText: structured?['secondary_text'] as String? ?? '',
          fullDescription: p['description'] as String,
        );
      }).toList();
      return _PlacesResult(predictions: predictions);
    }

    // Error statuses
    String msg;
    switch (status) {
      case 'REQUEST_DENIED':
        msg = 'API anahtarı reddedildi (REQUEST_DENIED).\n'
            'API key\'nizin uygulama kısıtlaması yoksa veya IP/referrer kısıtlaması varsa\n'
            'Google Cloud Console > Credentials > API key > Edit > Application restrictions: None';
      case 'INVALID_REQUEST':
        msg = 'Geçersiz istek (INVALID_REQUEST). ${apiErrorMsg ?? ''}';
      case 'OVER_DAILY_LIMIT':
      case 'OVER_QUERY_LIMIT':
        msg = 'API kota limiti aşıldı. (${status})';
      default:
        msg = 'Hata: $status${apiErrorMsg != null ? ' - $apiErrorMsg' : ''}';
    }
    return _PlacesResult(predictions: [], errorMessage: msg);
  } catch (e) {
    debugPrint('[Places API] Exception: $e');
    return _PlacesResult(predictions: [], errorMessage: 'Bağlantı hatası: $e');
  }
}

Future<LatLng?> _placeDetails(String placeId) async {
  final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
    'place_id': placeId,
    'fields': 'geometry',
    'key': _kMapsApiKey,
  });

  try {
    final res = await http.get(uri).timeout(const Duration(seconds: 6));
    final data = json.decode(res.body) as Map<String, dynamic>;
    final loc = data['result']?['geometry']?['location'];
    if (loc == null) return null;
    return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
  } catch (e) {
    debugPrint('[Place Details] Error: $e');
    return null;
  }
}

// ─── Map Picker Page ──────────────────────────────────────────────────────────
class _MapPickerPage extends StatefulWidget {
  final LatLng initialPosition;
  const _MapPickerPage({required this.initialPosition});

  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  late LatLng _pin;
  GoogleMapController? _mapCtrl;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  List<_PlacePrediction> _suggestions = [];
  bool _searching = false;
  bool _showDropdown = false;
  String? _apiError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pin = widget.initialPosition;

    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && _searchCtrl.text.isEmpty) {
        // Show hint text but no suggestions until user types
        setState(() => _showDropdown = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showDropdown = false;
        _apiError = null;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final result = await _autocomplete(value);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _suggestions = result.predictions;
        _apiError = result.errorMessage;
        _showDropdown = result.predictions.isNotEmpty || result.errorMessage != null;
      });
    });
  }

  Future<void> _selectPrediction(_PlacePrediction p) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _showDropdown = false;
      _searching = true;
      _searchCtrl.text = p.fullDescription;
    });

    final latLng = await _placeDetails(p.placeId);
    if (!mounted) return;
    setState(() => _searching = false);

    if (latLng != null) {
      setState(() => _pin = latLng);
      _mapCtrl?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 16)),
      );
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _suggestions = [];
      _showDropdown = false;
      _searching = false;
      _apiError = null;
    });
  }

  void _confirm() {
    final addr = _searchCtrl.text.trim().isNotEmpty
        ? _searchCtrl.text.trim()
        : '${_pin.latitude.toStringAsFixed(5)}, ${_pin.longitude.toStringAsFixed(5)}';
    Navigator.pop(context, LocationResult(lat: _pin.latitude, lng: _pin.longitude, address: addr));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('Konum Seç',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: Text('Onayla',
                style: GoogleFonts.inter(
                    color: const Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _showDropdown = false);
        },
        child: Stack(
          children: [
            // ── Map ──────────────────────────────────────────────
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _pin, zoom: 13),
              onMapCreated: (c) => _mapCtrl = c,
              onTap: (ll) {
                FocusScope.of(context).unfocus();
                setState(() {
                  _pin = ll;
                  _showDropdown = false;
                });
              },
              markers: {
                Marker(
                  markerId: const MarkerId('pin'),
                  position: _pin,
                  draggable: true,
                  onDragEnd: (ll) => setState(() => _pin = ll),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              buildingsEnabled: true,
            ),

            // ── Search Bar + Dropdown ─────────────────────────────
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Field
                  Material(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    elevation: 6,
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: _onTextChanged,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Yer, adres veya işletme ara...',
                        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                        prefixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0EA5E9)),
                                ),
                              )
                            : const Icon(Icons.search_rounded,
                                color: Color(0xFF0EA5E9), size: 22),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white38, size: 20),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                      ),
                    ),
                  ),

                  // Suggestions dropdown
                  if (_showDropdown && _suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _suggestions.asMap().entries.map((entry) {
                            final i = entry.key;
                            final s = entry.value;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                InkWell(
                                  onTap: () => _selectPrediction(s),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0EA5E9)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                              Icons.location_on_outlined,
                                              color: Color(0xFF0EA5E9),
                                              size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.mainText,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (s.secondaryText.isNotEmpty)
                                                Text(
                                                  s.secondaryText,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white38,
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                            Icons.north_west_rounded,
                                            color: Colors.white24,
                                            size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  // API Error hint
                  if (_apiError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _apiError!,
                              style: GoogleFonts.inter(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Bottom Info ───────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded,
                            color: Color(0xFF0EA5E9), size: 16),
                        const SizedBox(width: 8),
                        Text('Seçili Koordinat',
                            style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          '${_pin.latitude.toStringAsFixed(4)}, ${_pin.longitude.toStringAsFixed(4)}',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                    if (_searchCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _searchCtrl.text,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Aramak için yazın • Pini sürükleyin • Haritaya dokunun',
                      style: GoogleFonts.inter(
                          color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Location Picker Widget ─────────────────────────────────────────
class LocationPickerWidget extends StatefulWidget {
  final LocationResult? initialValue;
  final ValueChanged<LocationResult?> onChanged;
  final Color accentColor;

  const LocationPickerWidget({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.accentColor = const Color(0xFF0EA5E9),
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  LocationResult? _selected;
  static const LatLng _defaultCenter = LatLng(39.9208, 32.8541); // Ankara

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  Future<void> _openPicker() async {
    final initialPos = _selected != null
        ? LatLng(_selected!.lat, _selected!.lng)
        : _defaultCenter;

    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
          builder: (_) => _MapPickerPage(initialPosition: initialPos)),
    );

    if (result != null) {
      setState(() => _selected = result);
      widget.onChanged(result);
    }
  }

  void _clear() {
    setState(() => _selected = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _selected != null;
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasLocation
                ? widget.accentColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasLocation
                    ? widget.accentColor.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasLocation
                    ? Icons.location_on_rounded
                    : Icons.add_location_alt_outlined,
                color: hasLocation ? widget.accentColor : Colors.white38,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation ? 'Konum Seçildi' : 'Konum Ekle (Opsiyonel)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasLocation ? Colors.white : Colors.white54,
                    ),
                  ),
                  if (hasLocation) ...[
                    const SizedBox(height: 2),
                    Text(
                      _selected!.address,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: widget.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (hasLocation)
              GestureDetector(
                onTap: _clear,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child:
                      Icon(Icons.close_rounded, size: 18, color: Colors.white38),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
