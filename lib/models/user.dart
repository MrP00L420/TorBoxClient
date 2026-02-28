class User {
  final String email;
  final String customer;
  final String premiumExpiresAt;

  User({
    required this.email,
    required this.customer,
    required this.premiumExpiresAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? 'N/A',
      customer: json['customer'] ?? 'N/A',
      premiumExpiresAt: json['premium_expires_at'] ?? 'N/A',
    );
  }
}
