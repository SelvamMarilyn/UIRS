import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../services/issue_service.dart';
import '../services/auth_service.dart';
import '../models/issue.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  final IssueService _issueService = IssueService();
  final AuthService _authService = AuthService();
  List<Issue> _issues = [];
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _authService.getCurrentUser(),
        _issueService.getIssues(limit: 20),
      ]);
      setState(() {
        _user = results[0] as User;
        _issues = results[1] as List<Issue>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return AppTheme.accentGreen;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.errorRed;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Urban AI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.secondaryDark,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryBlue, AppTheme.secondaryDark],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            _user?.fullName ?? _user?.username ?? 'Citizen',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stats row
                          Row(
                            children: [
                              _StatChip(
                                label: 'Total Issues',
                                value: '${_issues.length}',
                                icon: Icons.report,
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                label: 'Pending',
                                value: '${_issues.where((i) => i.status == 'pending').length}',
                                icon: Icons.hourglass_empty,
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                label: 'Resolved',
                                value: '${_issues.where((i) => i.status == 'resolved').length}',
                                icon: Icons.check_circle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.pushNamed(context, '/report-issue');
                                _loadData(); // Refresh after reporting
                              },
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('REPORT NEW ISSUE'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Issues List
                          Text(
                            'Recent Community Reports',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All civic issues in your area',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 12),

                          if (_error != null)
                            _ErrorBanner(
                              message: _error!,
                              onRetry: _loadData,
                            )
                          else if (_issues.isEmpty)
                            _EmptyState(
                              onReport: () => Navigator.pushNamed(context, '/report-issue'),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _issues.length,
                              itemBuilder: (context, index) {
                                final issue = _issues[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/issue-detail',
                                      arguments: issue,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: (issue.imagePath != null && issue.imagePath!.isNotEmpty)
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Image.network(
                                                      '${ApiService.baseUrl}/${issue.imagePath}',
                                                      width: 36,
                                                      height: 36,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, e, s) => Icon(
                                                        _categoryIcon(issue.category),
                                                        color: AppTheme.primaryBlue,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  )
                                                : Icon(
                                                    _categoryIcon(issue.category),
                                                    color: AppTheme.primaryBlue,
                                                    size: 20,
                                                  ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    issue.title,
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  if (issue.description != null &&
                                                      issue.description!.isNotEmpty)
                                                    Text(
                                                      issue.description!,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  const SizedBox(height: 4),
                                                  if (issue.department != null)
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.apartment, size: 10, color: AppTheme.primaryBlue),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          issue.department!.replaceAll('_', ' ').toUpperCase(),
                                                          style: GoogleFonts.outfit(
                                                            color: AppTheme.primaryBlue,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  if (issue.mlCategoryConfidence != null && issue.mlCategoryConfidence! > 0.5)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.verified, size: 10, color: AppTheme.accentGreen),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'AI VERIFIED • ${(issue.mlCategoryConfidence! * 100).toStringAsFixed(0)}%',
                                                            style: const TextStyle(
                                                              color: AppTheme.accentGreen,
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            _Tag(
                                              label: issue.category.toUpperCase(),
                                              color: AppTheme.primaryBlue,
                                            ),
                                            const SizedBox(width: 6),
                                            _Tag(
                                              label: issue.severity.toUpperCase(),
                                              color: _severityColor(issue.severity),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(issue.status)
                                                    .withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                issue.status.replaceAll('_', ' ').toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _statusColor(issue.status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Icons.car_repair;
      case 'waste':
        return Icons.delete_outline;
      case 'light':
        return Icons.lightbulb_outline;
      default:
        return Icons.report_problem;
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off, color: AppTheme.errorRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not connect to server',
                  style: TextStyle(
                      color: AppTheme.errorRed, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReport;
  const _EmptyState({required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No issues reported yet',
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to report a civic issue in your area',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add),
              label: const Text('Report First Issue'),
            ),
          ],
        ),
      ),
    );
  }
}
