class Issue {
  final int id;
  final int userId;
  final double latitude;
  final double longitude;
  final String? address;
  final String category;
  final String title;
  final String? description;
  final String severity;
  final String status;
  final double priorityScore;
  final int upvotes;
  final DateTime reportedAt;
  final String? department;
  final double? mlCategoryConfidence;
  final double? mlSeverityConfidence;
  final String? imagePath;

  Issue({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.category,
    required this.title,
    this.description,
    required this.severity,
    required this.status,
    required this.priorityScore,
    required this.upvotes,
    required this.reportedAt,
    this.imagePath,
    this.department,
    this.mlCategoryConfidence,
    this.mlSeverityConfidence,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'],
      userId: json['user_id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      category: json['category'],
      title: json['title'],
      description: json['description'],
      severity: json['severity'],
      status: json['status'],
      priorityScore: (json['priority_score'] ?? 0.0).toDouble(),
      upvotes: json['upvotes'] ?? 0,
      reportedAt: DateTime.parse(json['reported_at']),
      imagePath: json['image_path'],
      department: json['department'],
      mlCategoryConfidence: (json['ml_category_confidence'] ?? 0.0).toDouble(),
      mlSeverityConfidence: (json['ml_severity_confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'category': category,
      'title': title,
      'description': description,
      'severity': severity,
      'status': status,
      'priority_score': priorityScore,
      'upvotes': upvotes,
      'reported_at': reportedAt.toIso8601String(),
      'image_path': imagePath,
      'department': department,
      'ml_category_confidence': mlCategoryConfidence,
      'ml_severity_confidence': mlSeverityConfidence,
    };
  }
}
