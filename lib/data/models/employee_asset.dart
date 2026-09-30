/// أصل مسجّل على الموظف (صف من `dbAssets.dbo.v_EmployeeAssets`؛ مقابل `EmployeeAssetDto`).
class EmployeeAsset {
  const EmployeeAsset({
    required this.id,
    required this.serial,
    required this.financialNumber,
    required this.name,
  });

  final String id;

  /// «ر.م» — رقم الصف في القائمة المطبوعة.
  final int serial;

  /// «الرقم المالي»؛ `—` عندما يكون فارغاً في السجل.
  final String financialNumber;

  /// «الأصل».
  final String name;

  factory EmployeeAsset.fromApi(Map<String, dynamic> json, {int? fallbackSeq}) {
    final seq = (json['seq'] as num?)?.toInt() ?? fallbackSeq ?? 0;
    final financial = (json['financialNumber'] as String?)?.trim();
    return EmployeeAsset(
      id: '$seq:${financial ?? ''}',
      serial: seq,
      financialNumber: financial == null || financial.isEmpty ? '—' : financial,
      name: (json['name'] as String?)?.trim() ?? '',
    );
  }
}

/// نتيجة `GET /me/assets`: القائمة، أو «غير متاح» عندما يكون سجل الأصول (SQL Server) مطفأً/بعيد المنال.
class EmployeeAssetsResult {
  const EmployeeAssetsResult({required this.available, required this.assets});

  final bool available;
  final List<EmployeeAsset> assets;

  int get total => assets.length;

  static const unavailable = EmployeeAssetsResult(available: false, assets: []);

  factory EmployeeAssetsResult.fromApi(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    var i = 0;
    return EmployeeAssetsResult(
      available: status != 'unavailable',
      assets: [
        for (final item in (json['data'] as List?) ?? const [])
          if (item is Map<String, dynamic>)
            EmployeeAsset.fromApi(item, fallbackSeq: ++i),
      ],
    );
  }
}
