import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';
import '../services/api_service.dart';

class IssueDetailScreen extends StatelessWidget {
  final Issue issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBadge(),
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildAIEvidenceSection(),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),
                  _buildMetadataSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.secondaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: (issue.imagePath != null && issue.imagePath!.isNotEmpty)
            ? Image.network(
                '${ApiService.baseUrl}/${issue.imagePath}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.secondaryDark,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
          SizedBox(height: 16),
          Text('No Image Provided', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    switch (issue.status.toLowerCase()) {
      case 'resolved': statusColor = AppTheme.accentGreen; break;
      case 'in_progress': statusColor = Colors.orange; break;
      default: statusColor = AppTheme.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: statusColor),
          const SizedBox(width: 8),
          Text(
            issue.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          issue.title,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${issue.latitude.toStringAsFixed(4)}, ${issue.longitude.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Spacer(),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(issue.reportedAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIEvidenceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI ANALYSIS EVIDENCE',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAIIndicator(
            'CATEGORY CONFIRMATION',
            issue.category.replaceAll('_', ' ').toUpperCase(),
            issue.mlCategoryConfidence ?? 0.0,
            Icons.category,
          ),
          const Divider(height: 32),
          _buildAIIndicator(
            'SEVERITY ASSESSMENT',
            issue.severity.toUpperCase(),
            issue.mlSeverityConfidence ?? 0.0,
            Icons.priority_high,
          ),
          const Divider(height: 32),
          _buildScoreTile(),
        ],
      ),
    );
  }

  Widget _buildAIIndicator(String label, String value, double confidence, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('CONFIDENCE', style: TextStyle(fontSize: 9, color: Colors.grey)),
            Text('${(confidence * 100).toStringAsFixed(1)}%', 
              style: TextStyle(
                color: confidence > 0.7 ? AppTheme.accentGreen : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreTile() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.secondaryDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            issue.priorityScore.toStringAsFixed(1),
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OVERALL PRIORITY SCORE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('Higher scores are prioritized for immediate crew assignment.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCRIPTION',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        Text(
          issue.description ?? 'No detailed description provided.',
          style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _metadataRow('Department Handling', issue.department?.replaceAll('_', ' ').toUpperCase() ?? 'PENDING'),
          const Divider(),
          _metadataRow('Citizen Upvotes', '${issue.upvotes} Citizens'),
          const Divider(),
          _metadataRow('Report ID', '#${issue.id.toString().padLeft(6, '0')}'),
        ],
      ),
    );
  }

  Widget _metadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
