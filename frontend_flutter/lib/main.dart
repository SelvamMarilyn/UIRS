import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/citizen_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/report_issue_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/heatmap_screen.dart';
import 'services/auth_service.dart';
import 'screens/issue_detail_screen.dart';
import 'models/issue.dart';
import 'models/user.dart';

void main() {
  runApp(const UrbanAISystemApp());
}

class UrbanAISystemApp extends StatelessWidget {
  const UrbanAISystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban AI System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/role-select': (context) => const RoleSelectionScreen(),
        '/citizen': (context) => const CitizenDashboard(),
        '/admin': (context) => const AdminDashboard(),
        '/report-issue': (context) => const ReportIssueScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/heatmap': (context) => const HeatmapScreen(),
        '/issue-detail': (context) {
          final issue = ModalRoute.of(context)!.settings.arguments as Issue;
          return IssueDetailScreen(issue: issue);
        },
      },
    );
  }
}

// Authentication wrapper to check login status
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      try {
        final user = await _authService.getCurrentUser();
        setState(() {
          _currentUser = user;
          _isLoggedIn = true;
          _isLoading = false;
        });
        return;
      } catch (e) {
        await _authService.logout();
      }
    }
    
    setState(() {
      _isLoggedIn = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.secondaryDark,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_isLoggedIn && _currentUser != null) {
      return _currentUser!.isAdmin ? const AdminDashboard() : const CitizenDashboard();
    }

    return const LoginScreen();
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.secondaryDark,
              AppTheme.secondaryDark.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logout button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    final authService = AuthService();
                    await authService.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ),
              const Spacer(),
              const Icon(Icons.location_city, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'URBAN AI SYSTEM',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart Infrastructure Management',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 48),
              _RoleButton(
                title: 'CONTINUE AS CITIZEN',
                subtitle: 'Report issues & track status',
                icon: Icons.person_pin_circle,
                onPressed: () => Navigator.pushNamed(context, '/citizen'),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                title: 'CONTINUE AS ADMIN',
                subtitle: 'Manage resources & analytics',
                icon: Icons.admin_panel_settings,
                onPressed: () => Navigator.pushNamed(context, '/admin'),
                isSecondary: true,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSecondary;

  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSecondary ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSecondary ? Colors.white : AppTheme.primaryBlue,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSecondary ? Colors.white : AppTheme.secondaryDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSecondary ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isSecondary ? Colors.white54 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
