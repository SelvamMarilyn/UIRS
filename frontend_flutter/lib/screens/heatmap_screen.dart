import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_theme.dart';
import '../services/analytics_service.dart';
import '../models/hotspot.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  List<Hotspot> _hotspots = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadHotspots();
  }

  Future<void> _loadHotspots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hotspots = await _analyticsService.getCurrentHotspots(
        category: _selectedCategory,
        daysBack: 30,
      );
      setState(() {
        _hotspots = hotspots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getMarkerColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.errorRed;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Hotspots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHotspots,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load hotspots',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadHotspots,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: _hotspots.isNotEmpty
                            ? LatLng(_hotspots.first.latitude, _hotspots.first.longitude)
                            : const LatLng(11.9416, 79.8083), // Puducherry default
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.urbanai.system',
                        ),
                        MarkerLayer(
                          markers: _hotspots.map((hotspot) {
                            return Marker(
                              point: LatLng(hotspot.latitude, hotspot.longitude),
                              width: 80,
                              height: 80,
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('${hotspot.category.toUpperCase()} Hotspot'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Issues: ${hotspot.issueCount}'),
                                          Text('Severity: ${hotspot.severity}'),
                                          Text(
                                            'Location: ${hotspot.latitude.toStringAsFixed(4)}, ${hotspot.longitude.toStringAsFixed(4)}',
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: _getMarkerColor(hotspot.severity),
                                      size: 40,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${hotspot.issueCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Showing ${_hotspots.length} hotspots (Last 30 days)',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                              ),
                              DropdownButton<String?>(
                                value: _selectedCategory,
                                hint: const Text('All'),
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All')),
                                  const DropdownMenuItem(value: 'road', child: Text('Road')),
                                  const DropdownMenuItem(value: 'waste', child: Text('Waste')),
                                  const DropdownMenuItem(value: 'light', child: Text('Light')),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedCategory = value);
                                  _loadHotspots();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      right: 16,
                      left: 16,
                      child: _buildLegend(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _legendItem('High Severity', AppTheme.errorRed),
            _legendItem('Medium', Colors.orange),
            _legendItem('Low', Colors.yellow),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
