// ======================================================
// 👤 USER MANAGEMENT MODELS
// ======================================================
// File: lib/models/user.dart
// Purpose: โมเดลและ enum สำหรับจัดการผู้ใช้งาน
// Features:
//   - User roles (Owner, Member, Admin)
//   - Password algorithms
//   - User data model with validation
// ======================================================

// 🔐 USER ROLE DEFINITIONS
enum UserRole { 
  owner,   // เจ้าของระบบ
  member,  // สมาชิกทั่วไป
  admin    // ผู้ดูแลระบบ
}

// 🔒 PASSWORD ALGORITHM TYPES
enum PasswordAlgorithm { 
  bcrypt   // Bcrypt hashing algorithm
}

// ======================================================
// 👤 MAIN USER DATA MODEL
// ======================================================
class AppUser {
  // 🔑 PRIMARY IDENTIFICATION
  final int userId;
  final String username;
  final UserRole role;
  
  // 💰 WALLET INFORMATION
  final double initialWallet;
  final double currentWallet;
  
  // 📧 CONTACT INFORMATION
  final String email;
  final String phone;
  
  // 🔒 SECURITY INFORMATION
  final String passwordHash;
  final PasswordAlgorithm passwordAlgo;
  
  // ✅ VERIFICATION STATUS
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  
  // 📅 TIMESTAMP INFORMATION
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.userId,
    required this.username,
    required this.role,
    required this.initialWallet,
    required this.currentWallet,
    required this.email,
    required this.phone,
    required this.passwordHash,
    this.passwordAlgo = PasswordAlgorithm.bcrypt,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // ======================================================
  // 🔧 COMPUTED PROPERTIES & GETTERS
  // ======================================================
  
  // 🔄 BACKWARD COMPATIBILITY GETTERS
  String get id => userId.toString();
  int get wallet => currentWallet.toInt();

  // ✅ VERIFICATION STATUS CHECKERS
  bool get isEmailVerified => emailVerifiedAt != null;
  bool get isPhoneVerified => phoneVerifiedAt != null;
  bool get isFullyVerified => isEmailVerified && isPhoneVerified;

  // 🔐 ROLE-BASED PERMISSION CHECKERS
  bool get isOwner => role == UserRole.owner;
  bool get isMember => role == UserRole.member;
  bool get isAdmin => role == UserRole.admin;

  // ======================================================
  // 🔄 OBJECT MANIPULATION METHODS
  // ======================================================
  
  /// Creates a copy of this user with updated fields
  AppUser copyWith({
    int? userId,
    String? username,
    UserRole? role,
    double? wallet,
    String? email,
    String? phone,
    String? passwordHash,
    PasswordAlgorithm? passwordAlgo,
    DateTime? emailVerifiedAt,
    DateTime? phoneVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      role: role ?? this.role,
      initialWallet: wallet ?? this.currentWallet,
      currentWallet: wallet ?? this.currentWallet,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordAlgo: passwordAlgo ?? this.passwordAlgo,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ======================================================
  // 📤 JSON SERIALIZATION METHODS
  // ======================================================
  
  /// Converts user object to JSON for API communication
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'role': role.name,
      'wallet': currentWallet,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'password_algo': passwordAlgo.name,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates user object from JSON data (API response)
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final walletValue = (json['wallet'] ?? json['current_wallet'] ?? json['initial_wallet'] ?? 0.0);
    final walletDouble = walletValue is num ? walletValue.toDouble() : 0.0;
    
    return AppUser(
      userId: (json['user_id'] ?? json['id'] ?? 0) is num ? (json['user_id'] ?? json['id'] ?? 0) as int : 0,
      username: (json['username'] ?? '').toString(),
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role']?.toString(),
        orElse: () => UserRole.member,
      ),
      initialWallet: walletDouble,
      currentWallet: walletDouble,
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      passwordHash: (json['password_hash'] ?? '').toString(),
      passwordAlgo: PasswordAlgorithm.values.firstWhere(
        (e) => e.name == json['password_algo']?.toString(),
        orElse: () => PasswordAlgorithm.bcrypt,
      ),
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'].toString())
          : null,
      phoneVerifiedAt: json['phone_verified_at'] != null
          ? DateTime.parse(json['phone_verified_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  // ======================================================
  // 🔧 OBJECT OVERRIDE METHODS
  // ======================================================
  
  @override
  String toString() {
    return 'AppUser(userId: $userId, username: $username, role: ${role.name}, currentWallet: $currentWallet, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
