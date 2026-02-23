class Hotspot {
  final double latitude;
  final double longitude;
  final int issueCount;
  final String category;
  final String severity;

  Hotspot({
    required this.latitude,
    required this.longitude,
    required this.issueCount,
    required this.category,
    required this.severity,
  });

  factory Hotspot.fromJson(Map<String, dynamic> json) {
    return Hotspot(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      issueCount: json['issue_count'] ?? 1,
      category: json['category'] ?? 'unknown',
      severity: json['severity'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'issue_count': issueCount,
      'category': category,
      'severity': severity,
    };
  }
}
