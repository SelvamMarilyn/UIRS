import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final IssueService _issueService = IssueService();
  final AuthService _authService = AuthService();

  List<Issue> _issues = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedDepartment;

  final List<String> _departments = [
    'Road Maintenance',
    'Sanitation',
    'Electrical',
    'General'
  ];

  int get _pendingCount => _issues.where((i) => i.status == 'reported').length;
  int get _inProgressCount => _issues.where((i) => i.status == 'in_progress').length;
  int get _resolvedCount => _issues.where((i) => i.status == 'resolved').length;

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
      final issues = await _issueService.getIssues(limit: 100);
      setState(() {
        _issues = issues;
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
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Admin Console',
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
                    // Stats Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E3A5F), AppTheme.secondaryDark],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard Overview',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${_issues.length} Total Issues',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _StatCard(
                                label: 'Pending',
                                value: '$_pendingCount',
                                color: Colors.orange,
                                icon: Icons.hourglass_empty,
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                label: 'In Progress',
                                value: '$_inProgressCount',
                                color: AppTheme.primaryBlue,
                                icon: Icons.engineering,
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                label: 'Resolved',
                                value: '$_resolvedCount',
                                color: AppTheme.accentGreen,
                                icon: Icons.check_circle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error banner
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Backend not connected: $_error',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // AI Tools Section
                          Text(
                            'AI Tools',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ActionTile(
                            icon: Icons.analytics,
                            color: Colors.green,
                            title: 'Predictive Analytics',
                            subtitle: 'AI hotspot forecasting (next 30 days)',
                            onTap: () => Navigator.pushNamed(context, '/analytics'),
                          ),
                          _ActionTile(
                            icon: Icons.map,
                            color: Colors.red,
                            title: 'Live Issue Heatmap',
                            subtitle: 'Geographic issue clusters in real-time',
                            onTap: () => Navigator.pushNamed(context, '/heatmap'),
                          ),
                          _ActionTile(
                            icon: Icons.auto_awesome,
                            color: Colors.purple,
                            title: 'Optimize Crew Assignments',
                            subtitle: 'AI-powered field crew allocation',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🤖 Optimization engine running...'),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Filter Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Issue Queue',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryDark,
                                ),
                              ),
                              DropdownButton<String?>(
                                value: _selectedDepartment,
                                hint: const Text('All Departments', style: TextStyle(fontSize: 12)),
                                underline: const SizedBox(),
                                icon: const Icon(Icons.filter_list, size: 18),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Departments', style: TextStyle(fontSize: 12))),
                                  ..._departments.map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12)),
                                  )),
                                ],
                                onChanged: (val) => setState(() => _selectedDepartment = val),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_issues.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No issues reported yet',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _issues.where((i) => _selectedDepartment == null || i.department == _selectedDepartment).take(20).length,
                              itemBuilder: (context, index) {
                                final filteredIssues = _issues.where((i) => _selectedDepartment == null || i.department == _selectedDepartment).toList();
                                final issue = filteredIssues[index];
                                return _IssueRow(
                                  issue: issue,
                                  onStatusChange: (newStatus) async {
                                    try {
                                      await _issueService.updateIssueStatus(
                                        issue.id,
                                        newStatus,
                                      );
                                      _loadData();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final Issue issue;
  final Function(String) onStatusChange;
  const _IssueRow({required this.issue, required this.onStatusChange});

  Color get _severityColor {
    switch (issue.severity.toLowerCase()) {
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/issue-detail',
          arguments: issue,
        ),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _severityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              if (issue.imagePath != null && issue.imagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      '${ApiService.baseUrl}/${issue.imagePath}',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, s) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${issue.category.replaceAll('_', ' ').toUpperCase()} • Score: ${issue.priorityScore.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: AppTheme.secondaryDark.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (issue.department != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '📍 Routed to: ${issue.department!.replaceAll('_', ' ').toUpperCase()}',
                          style: GoogleFonts.outfit(
                            color: AppTheme.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (issue.mlCategoryConfidence != null && issue.mlCategoryConfidence! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🤖 AI Accuracy: ${(issue.mlCategoryConfidence! * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    onSelected: onStatusChange,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'pending', child: Text('Pending')),
                      const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
                      const PopupMenuItem(value: 'resolved', child: Text('Resolved')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        issue.status.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
