import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Register new user
  Future<User> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await _apiService.post('/api/users/register', data: {
        'email': email,
        'username': username,
        'password': password,
        'full_name': fullName,
        'phone': phone,
      });

      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Login user
  Future<User> login({
    required String username,
    required String password,
  }) async {
    try {
      // OAuth2PasswordRequestForm requires application/x-www-form-urlencoded
      final response = await _apiService.postForm(
        '/api/users/login',
        data: {
          'username': username,
          'password': password,
          'grant_type': 'password',
        },
      );

      // Save token
      final token = response.data['access_token'];
      await _apiService.saveToken(token);

      // Get user info
      return await getCurrentUser();
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Get current user info
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiService.get('/api/users/me');
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get user info: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.clearToken();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _apiService.getToken();
    return token != null;
  }
}
