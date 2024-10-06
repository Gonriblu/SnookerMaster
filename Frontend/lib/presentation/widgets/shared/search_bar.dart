import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/location.dart';

class SearchMapBar extends StatefulWidget {
  final Function(Location? location) onLocationSelected;

  const SearchMapBar({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<SearchMapBar> createState() => _SearchMapBarState();
}

class _SearchMapBarState extends State<SearchMapBar> {
  List<Location> _locations = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  bool _hasSelectedlocation = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_hasSelectedlocation) {
      return;
    }

    final query = _searchController.text;

    setState(() {
      _locations = [];
    });
    _removeOverlay();

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (query.length >= 3) {
      _debounceTimer = Timer(const Duration(seconds: 1), () async {
        try {
          final locations = await _fetchLocations(query);
          if (mounted && !_hasSelectedlocation) {
            setState(() {
              _locations = locations;
            });
            if (_locations.isNotEmpty) {
              _showOverlay();
            } else {
              _removeOverlay();
            }
          }
        } catch (e) {
          print('Error al obtener sugerencias: $e');
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _locations = [];
        });
        _removeOverlay();
      }
    }
  }

  Future<List<Location>> _fetchLocations(String query) async {
    try {
      final url =
          'https://api.opencagedata.com/geocode/v1/json?q=$query&key=${Environment.apiKey}&countrycode=es&language=es&pretty=1';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return (data['results'] as List).map<Location>((result) {
          final formatted = result['formatted'] as String;
          final geometry = result['geometry'] as Map<String, dynamic>;
          final lat = geometry['lat'] as double;
          final lng = geometry['lng'] as double;

          return Location(
            formatted: formatted,
            lat: lat,
            lng: lng,
          );
        }).toList();
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      rethrow;
    }
  }

  void _onLocationSelected(Location location) {
    setState(() {
      _searchController.text = location.formatted;
      _hasSelectedlocation = true;
      _locations = [];
    });
    _removeOverlay();
    widget.onLocationSelected(location);
  }

  void _clearSelection() {
    setState(() {
      _searchController.clear();
      _hasSelectedlocation = false;
    });
    _searchFocusNode.requestFocus();
    widget.onLocationSelected(null);
  }

  void _showOverlay() {
    if (!_hasSelectedlocation) {
      _overlayEntry ??= _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            ModalBarrier(
              color:
                  Colors.transparent, // Puede ajustar la opacidad si lo desea
              onDismiss: () {
                _removeOverlay();
              },
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height,
              width: size.width,
              child: Material(
                elevation: 4.0,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: _locations.map((location) {
                      return ListTile(
                        title: Text(location.formatted),
                        onTap: () => _onLocationSelected(location),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              enabled: !_hasSelectedlocation,
              decoration: InputDecoration(
                labelText: 'Buscar Ubicación',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_hasSelectedlocation)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
            ),
        ],
      ),
    );
  }
}
