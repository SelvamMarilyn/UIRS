import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../models/issue.dart';
import 'api_service.dart';

class IssueService {
  final ApiService _apiService = ApiService();

  // Create new issue — image is optional
  Future<Issue> createIssue({
    required int userId,
    required double latitude,
    required double longitude,
    required String title,
    String? description,
    String category = 'road',
    XFile? imageFile,
  }) async {
    try {
      final fields = <String, dynamic>{
        'user_id': userId.toString(),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'title': title,
        'description': description ?? '',
        'category': category,
      };

      if (imageFile != null) {
        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          fields['image'] = MultipartFile.fromBytes(
            bytes,
            filename: imageFile.name,
          );
        } else {
          fields['image'] = await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split(RegExp(r'[/\\]')).last,
          );
        }
      }

      final formData = FormData.fromMap(fields);
      final response = await _apiService.postFormData('/api/issues/', formData);
      return Issue.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create issue: $e');
    }
  }

  // Get all issues with optional filters
  Future<List<Issue>> getIssues({
    String? category,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get('/api/issues/', queryParameters: queryParams);
      final List<dynamic> issuesJson = response.data;
      return issuesJson.map((json) => Issue.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch issues: $e');
    }
  }

  // Get single issue by ID
  Future<Issue> getIssue(int issueId) async {
    try {
      final response = await _apiService.get('/api/issues/$issueId');
      return Issue.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch issue: $e');
    }
  }

  // Update issue status
  Future<void> updateIssueStatus(int issueId, String status) async {
    try {
      await _apiService.put('/api/issues/$issueId/status', data: {'status': status});
    } catch (e) {
      throw Exception('Failed to update issue status: $e');
    }
  }
}
