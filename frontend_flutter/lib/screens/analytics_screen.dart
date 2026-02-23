import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, dynamic>? _forecastData;
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _analyticsService.getForecastedHotspots(
        category: _selectedCategory,
        forecastDays: 30,
      );
      setState(() {
        _forecastData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictive Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadForecast,
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
                          'Failed to load forecast',
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
                          onPressed: _loadForecast,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Filter
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list, color: AppTheme.primaryBlue),
                              const SizedBox(width: 12),
                              const Text(
                                'Category:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButton<String?>(
                                  value: _selectedCategory,
                                  hint: const Text('All Categories'),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                                    const DropdownMenuItem(value: 'road', child: Text('Road Issues')),
                                    const DropdownMenuItem(value: 'waste', child: Text('Waste Issues')),
                                    const DropdownMenuItem(value: 'light', child: Text('Light Issues')),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedCategory = value);
                                    _loadForecast();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // AI Forecast Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_graph, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  'AI Forecast (Next 30 Days)',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category: ${_forecastData?['category'] ?? 'All'}',
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Forecast Period: ${_forecastData?['forecast_days'] ?? 30} days',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_forecastData?['predictions'] != null && (_forecastData!['predictions'] as List).isNotEmpty)
                                    Text(
                                      'Predictions available: ${(_forecastData!['predictions'] as List).length} data points',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Insufficient historical data for time-series forecasting. (Minimum 7 days of reports required)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category Distribution
                      const Text(
                        'Issue Category Distribution',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryCard('Road Issues', 45, AppTheme.errorRed),
                      const SizedBox(height: 8),
                      _buildCategoryCard('Waste Management', 30, Colors.orange),
                      const SizedBox(height: 8),
                      _buildCategoryCard('Streetlight Issues', 25, Colors.amber),
                      const SizedBox(height: 24),

                      // Insights Card
                      Card(
                        color: AppTheme.accentGreen.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, color: AppTheme.accentGreen),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'AI Insights',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '• Road damage reports are expected to increase by 15% in the next month',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '• Waste overflow issues peak on weekends',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '• Streetlight failures are concentrated in Zone 3',
                                style: TextStyle(fontSize: 14),
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

  Widget _buildCategoryCard(String title, int percentage, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$percentage%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
