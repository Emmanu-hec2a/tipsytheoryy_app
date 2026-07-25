import '../core/api_client.dart';

class UserModel {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String role;
  final int loyaltyPoints;
  final double walletBalance;
  final String? profilePicture;
  final bool isAvailable;
  final bool isAgeVerified;
  final int riskScore;

  // Rider specific
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final double avgRating;
  final int totalDeliveries;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.firstName,
    this.lastName,
    required this.role,
    required this.loyaltyPoints,
    this.walletBalance = 0.0,
    this.profilePicture,
    this.isAvailable = false,
    this.isAgeVerified = false,
    this.riskScore = 0,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.avgRating = 0.0,
    this.totalDeliveries = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? photoUrl = json['profile_picture'];

    if (photoUrl != null && photoUrl.startsWith('/')) {
      final base = ApiClient.baseUrl.replaceAll('/api/v1/', '');
      photoUrl = "$base$photoUrl";
    }

    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'] ?? 'customer',
      loyaltyPoints: json['loyalty_points'] ?? 0,
      walletBalance: double.tryParse(json['wallet_balance']?.toString() ?? '0.0') ?? 0.0,
      profilePicture: photoUrl,
      isAvailable: json['is_available'] ?? false,
      isAgeVerified: json['is_age_verified'] ?? false,
      riskScore: json['risk_score'] ?? 0,
      bankName: json['bank_name'],
      bankAccountName: json['bank_account_name'],
      bankAccountNumber: json['bank_account_number'],
      avgRating: double.tryParse(json['avg_rating']?.toString() ?? '0.0') ?? 0.0,
      totalDeliveries: json['total_deliveries'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'loyalty_points': loyaltyPoints,
      'wallet_balance': walletBalance,
      'profile_picture': profilePicture,
      'is_available': isAvailable,
      'is_age_verified': isAgeVerified,
      'risk_score': riskScore,
      'bank_name': bankName,
      'bank_account_name': bankAccountName,
      'bank_account_number': bankAccountNumber,
      'avg_rating': avgRating,
      'total_deliveries': totalDeliveries,
    };
  }

  String get fullName => "${firstName ?? ''} ${lastName ?? ''}".trim();

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? role,
    int? loyaltyPoints,
    double? walletBalance,
    String? profilePicture,
    bool? isAvailable,
    bool? isAgeVerified,
    int? riskScore,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
    double? avgRating,
    int? totalDeliveries,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      walletBalance: walletBalance ?? this.walletBalance,
      profilePicture: profilePicture ?? this.profilePicture,
      isAvailable: isAvailable ?? this.isAvailable,
      isAgeVerified: isAgeVerified ?? this.isAgeVerified,
      riskScore: riskScore ?? this.riskScore,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      avgRating: avgRating ?? this.avgRating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
    );
  }
}
