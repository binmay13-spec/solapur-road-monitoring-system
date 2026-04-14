// NEW FILE | Extends: flutter_app/lib/screens/citizen/live_map_screen.dart
// Interactive Map using OpenStreetMap (flutter_map) instead of Google Maps

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import '../../services/report_service_new.dart';

class MapScreenNew extends StatefulWidget {
  const MapScreenNew({super.key});

  @override
  State<MapScreenNew> createState() => _MapScreenNewState();
}

class _MapScreenNewState extends State<MapScreenNew> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  bool _isLoading = true;

  final LatLng _initialPosition = const LatLng(17.6599, 75.9064); // Solapur Default

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final reports = await reportApi.getMapData();
    List<Marker> newMarkers = [];
    
    for (var r in reports) {
      newMarkers.add(
        Marker(
          point: LatLng(r['latitude'], r['longitude']),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${r['category']} - ${r['status']}")),
              );
            },
            child: Icon(
              Icons.location_on,
              size: 40,
              color: r['status'] == 'completed' ? Colors.green : Colors.red,
            ),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_road_monitor',
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          
          // Header Filter
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All", true),
                  _buildFilterChip("Potholes", false),
                  _buildFilterChip("Fixed", false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {},
        backgroundColor: Colors.white.withOpacity(0.9),
        selectedColor: const Color(0xFF77B6EA).withOpacity(0.3),
      ),
    );
  }
}
