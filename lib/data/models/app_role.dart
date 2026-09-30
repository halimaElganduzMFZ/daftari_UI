/// أدوار الدخول بعد صفحة whichApp.
enum AppRole {
  /// الدخول كموظف عادي.
  employee,

  /// الدخول مسؤولاً عن هيكل (وحدة / إدارة / ...).
  structureManager,
}

/// هيكل يديره المستخدم (مثل صفوف جدول STRUCTURE في whichApp.php).
class ManagedStructure {
  const ManagedStructure({
    required this.id,
    required this.name,
    required this.typeLabel,
  });

  final String id;
  final String name;

  /// مثل: وحدة، إدارة، قسم…
  final String typeLabel;
}
