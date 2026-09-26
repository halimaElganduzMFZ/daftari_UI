import 'app_role.dart';

/// نماذج المصادقة — مطابقة لـ `auth.dto.ts` في Nest API (`MeDto` / `TokenPairDto`).
class StructureRef {
  const StructureRef({required this.id, this.type, this.name});

  /// `taksem.numr1` (= `assignerinfo_tbl.structure_Num`).
  final int id;

  /// `taksem.Type_Structure` — 1..3 هياكل عليا، وما بعدها أقسام/وحدات.
  final int? type;
  final String? name;

  factory StructureRef.fromJson(Map<String, dynamic> json) {
    final rawId = json['num'] ?? json['id'];
    return StructureRef(
      id: (rawId as num).toInt(),
      type: (json['type'] as num?)?.toInt(),
      name: json['name'] as String?,
    );
  }

  /// تسمية نوع الهيكل للعرض (مقابلة أزرار whichApp.php).
  String get typeLabel => switch (type) {
    1 => 'إدارة عامة',
    2 => 'إدارة',
    3 => 'مكتب',
    4 => 'قسم',
    5 => 'وحدة',
    _ => 'هيكل',
  };

  /// تحويل إلى الهيكل المستخدم في الجلسة وشاشات المدير.
  ManagedStructure toManagedStructure() => ManagedStructure(
    id: id.toString(),
    name: (name ?? '').trim().isEmpty ? 'هيكل رقم $id' : name!.trim(),
    typeLabel: typeLabel,
  );
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
    this.canActOnBehalf = false,
    this.canManageAwol = false,
    this.isRequestReviewer = false,
    this.email,
    this.fullName,
    this.workplace,
    this.workplaceName,
    this.primaryStructure,
  });

  /// `auth_users.id`
  final int id;

  /// `employee_card.NumAtou`
  final int employeeId;

  /// `employee_card.Num_Employee`
  final String employeeNumber;
  final String? email;
  final String? fullName;

  /// `employee_card.MakenH` (legacy MAKAN).
  final int? workplace;
  final String? workplaceName;
  final bool isAdmin;

  /// مسؤول عن هيكل واحد على الأقل (`assignerinfo_tbl`).
  final bool isAssigner;
  final List<StructureRef> structures;
  final int? primaryStructure;

  /// الهيكل الأساسي علوي (Type 1-3): يمكنه الدخول نيابة عن موظفي الهياكل الأدنى.
  final bool canActOnBehalf;

  /// صلاحية المنقطعين من الـ API فقط، مستقلة عن العدد وصلاحية مدير النظام.
  final bool canManageAwol;

  /// مدرج في `AUTH_REQUEST_REVIEWERS`: مراجعة طلبات كل الموظفين.
  final bool isRequestReviewer;
  final bool canChangePassword;

  String get displayName => (fullName != null && fullName!.trim().isNotEmpty)
      ? fullName!.trim()
      : employeeNumber;

  String get displayRole {
    if (isAdmin) return 'مسؤول النظام';
    if (isAssigner) return 'مسؤول هيكل تنظيمي';
    return 'موظف';
  }

  /// هل يمر المستخدم على صفحة تحديد نوع الدخول (whichApp)؟
  bool get canManageStructures => isAssigner && structures.isNotEmpty;

  List<ManagedStructure> get managedStructures => [
    for (final s in structures) s.toManagedStructure(),
  ];

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final structuresJson = json['structures'];
    final structures = structuresJson is List
        ? structuresJson
              .whereType<Map<String, dynamic>>()
              .map(StructureRef.fromJson)
              .toList()
        : <StructureRef>[];
    return AuthUser(
      id: (json['id'] as num).toInt(),
      employeeId: (json['employeeId'] as num).toInt(),
      employeeNumber: json['employeeNumber']?.toString() ?? '',
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      workplace: (json['workplace'] as num?)?.toInt(),
      workplaceName: json['workplaceName'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isAssigner: json['isAssigner'] as bool? ?? false,
      structures: structures,
      primaryStructure: (json['primaryStructure'] as num?)?.toInt(),
      canActOnBehalf: json['canActOnBehalf'] as bool? ?? false,
      canManageAwol: json['canManageAwol'] == true,
      isRequestReviewer: json['isRequestReviewer'] as bool? ?? false,
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
