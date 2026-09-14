/// نماذج المصادقة — مطابقة لـ auth.dto.ts في Nest API.
class StructureRef {
  const StructureRef({
    required this.id,
    this.type,
    this.name,
  });

  final int id;
  final int? type;
  final String? name;

  factory StructureRef.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['num'];
    return StructureRef(
      id: (rawId as num).toInt(),
      type: (json['type'] as num?)?.toInt(),
      name: json['name'] as String?,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.employeeId,
    required this.employeeNumber,
    required this.isAdmin,
    required this.isAssigner,
    required this.structures,
    required this.canChangePassword,
    this.email,
    this.fullName,
    this.workplace,
    this.workplaceName,
    this.primaryStructure,
  });

  final int id;
  final int employeeId;
  final String employeeNumber;
  final String? email;
  final String? fullName;
  final int? workplace;
  final String? workplaceName;
  final bool isAdmin;
  final bool isAssigner;
  final List<StructureRef> structures;
  final int? primaryStructure;
  final bool canChangePassword;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty)
          ? fullName!.trim()
          : employeeNumber;

  String get displayRole {
    if (isAdmin) return 'مسؤول النظام';
    if (isAssigner) return 'مسؤول هيكل تنظيمي';
    return 'موظف';
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final structuresJson = json['structures'];
    return AuthUser(
      id: (json['id'] as num).toInt(),
      employeeId: (json['employeeId'] as num).toInt(),
      employeeNumber: json['employeeNumber'] as String? ?? '',
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      workplace: (json['workplace'] as num?)?.toInt(),
      workplaceName: json['workplaceName'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isAssigner: json['isAssigner'] as bool? ?? false,
      structures: structuresJson is List
          ? structuresJson
              .whereType<Map<String, dynamic>>()
              .map(StructureRef.fromJson)
              .toList()
          : const [],
      primaryStructure: (json['primaryStructure'] as num?)?.toInt(),
      canChangePassword: json['canChangePassword'] as bool? ?? false,
    );
  }
}

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final AuthUser user;

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Missing user in token response');
    }
    return TokenPair(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: AuthUser.fromJson(userJson),
    );
  }
}
