import 'enums.dart';

class User {
  final String id;
  final String email;
  final String fullName;
  final String? role; // Admin or Member
  final DateTime createdDate;

  bool get isAdmin => role?.toLowerCase() == 'admin';

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.role,
    required this.createdDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      role: json['role'],
      createdDate: DateTime.parse(json['createdDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}

class Member {
  final int id;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final DateTime joinDate;
  final double walletBalance;
  final MemberTier tier;
  final double rankLevel;
  final double totalSpent;
  final bool isActive;

  Member({
    required this.id,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.joinDate,
    required this.walletBalance,
    required this.tier,
    required this.rankLevel,
    required this.totalSpent,
    required this.isActive,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      userId: json['userId'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      joinDate: DateTime.parse(json['joinDate']),
      walletBalance: (json['walletBalance'] as num).toDouble(),
      tier: MemberTier.values[json['tier']],
      rankLevel: (json['rankLevel'] as num).toDouble(),
      totalSpent: (json['totalSpent'] as num).toDouble(),
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'joinDate': joinDate.toIso8601String(),
      'walletBalance': walletBalance,
      'tier': tier.index,
      'rankLevel': rankLevel,
      'totalSpent': totalSpent,
      'isActive': isActive,
    };
  }
}

class LoginResponse {
  final String token;
  final String email;
  final String fullName;
  final String role;
  final int? memberId;
  final double walletBalance;

  LoginResponse({
    required this.token,
    required this.email,
    required this.fullName,
    required this.role,
    this.memberId,
    required this.walletBalance,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      email: json['email'],
      fullName: json['fullName'],
      role: json['role'],
      memberId: json['memberId'] != null && json['memberId'] != 0
          ? json['memberId']
          : null,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
