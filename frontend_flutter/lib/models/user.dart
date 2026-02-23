class User {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final bool isAdmin;
  final double credibilityScore;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    required this.isAdmin,
    required this.credibilityScore,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      isAdmin: json['is_admin'] ?? false,
      credibilityScore: (json['credibility_score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'is_admin': isAdmin,
      'credibility_score': credibilityScore,
    };
  }
}
