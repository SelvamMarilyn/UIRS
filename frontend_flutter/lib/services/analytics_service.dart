import '../models/hotspot.dart';
import 'api_service.dart';

class AnalyticsService {
  final ApiService _apiService = ApiService();

  // Get forecasted hotspots
  Future<Map<String, dynamic>> getForecastedHotspots({
    String? category,
    int forecastDays = 30,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'forecast_days': forecastDays,
      };

      if (category != null) queryParams['category'] = category;

      final response = await _apiService.get(
        '/api/analytics/forecast/hotspots',
        queryParameters: queryParams,
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch forecast: $e');
    }
  }

  // Get current hotspots
  Future<List<Hotspot>> getCurrentHotspots({
    String? category,
    int daysBack = 30,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'days_back': daysBack,
      };

      if (category != null) queryParams['category'] = category;

      final response = await _apiService.get(
        '/api/analytics/hotspots/current',
        queryParameters: queryParams,
      );

      final List<dynamic> hotspotsJson = response.data['hotspots'];
      return hotspotsJson.map((json) => Hotspot.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch hotspots: $e');
    }
  }
}
