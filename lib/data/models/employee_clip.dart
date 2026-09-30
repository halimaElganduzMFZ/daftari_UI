import 'dart:typed_data';

/// تصنيف المستند كما في `getFileDisplayName` القديمة (`DocumentKind` في الـ API).
enum EmployeeClipKind { timesheetCard, productionVoucher, paySlip, message, other }

/// قصاصة/مستند للموظف (صف من `DBWhatsApp.smswhatsappt`؛ مقابل `DocumentDto`).
class EmployeeClip {
  const EmployeeClip({
    required this.id,
    required this.title,
    required this.date,
    required this.kind,
    required this.fileName,
    this.extension = 'pdf',
    this.contentType = 'application/pdf',
  });

  /// `smswhatsappt.AutoID`.
  final int id;

  /// الاسم المعروض القديم («قسيمة مالية»، «بطاقة زمنية للموظف»…).
  final String title;

  /// `SMSDate` — يوم تجهيز الملف؛ قد يكون `null`.
  final DateTime? date;
  final EmployeeClipKind kind;

  /// اسم الملف فقط (basename من `FilePath`).
  final String fileName;
  final String extension;
  final String contentType;

  bool get isPdf => extension.toLowerCase() == 'pdf' || contentType == 'application/pdf';
  bool get isImage => contentType.startsWith('image/');

  /// مسارات نسبية لقاعدة الـ API (`ApiConfig.baseUrl`).
  String get filePath => '/me/documents/$id/file';
  String get linkPath => '/me/documents/$id/link';

  static EmployeeClipKind kindFromApi(String? raw) => switch (raw) {
        'TIMESHEET' => EmployeeClipKind.timesheetCard,
        'PRODUCTION_VOUCHER' => EmployeeClipKind.productionVoucher,
        'PAYSLIP' => EmployeeClipKind.paySlip,
        'MESSAGE' => EmployeeClipKind.message,
        _ => EmployeeClipKind.other,
      };

  factory EmployeeClip.fromApi(Map<String, dynamic> json) {
    final fileName = (json['fileName'] as String?) ?? '';
    final dot = fileName.lastIndexOf('.');
    final extFromName = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    final dateRaw = json['date'];
    return EmployeeClip(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'مستند',
      date: dateRaw is String ? DateTime.tryParse(dateRaw) : null,
      kind: kindFromApi(json['kind'] as String?),
      fileName: fileName,
      extension: ((json['extension'] as String?) ?? extFromName).toLowerCase(),
      contentType:
          (json['contentType'] as String?) ?? 'application/octet-stream',
    );
  }
}

/// صفحة من `GET /me/documents` مع حالة توفر فهرس المستندات.
class EmployeeClipsPage {
  const EmployeeClipsPage({
    required this.available,
    required this.items,
    required this.page,
    required this.hasNext,
  });

  /// `false` عندما تكون قاعدة الفهرس (DBWhatsApp) مطفأة أو بعيدة المنال.
  final bool available;
  final List<EmployeeClip> items;
  final int page;
  final bool hasNext;

  factory EmployeeClipsPage.fromApi(Map<String, dynamic> json) {
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return EmployeeClipsPage(
      available: json['status'] != 'unavailable',
      items: [
        for (final item in (json['data'] as List?) ?? const [])
          if (item is Map<String, dynamic>) EmployeeClip.fromApi(item),
      ],
      page: (meta['page'] as num?)?.toInt() ?? 1,
      hasNext: meta['hasNext'] as bool? ?? false,
    );
  }
}

/// محتوى ملف مستند محمّل عبر التوكن.
class EmployeeClipFile {
  const EmployeeClipFile({
    required this.bytes,
    required this.contentType,
    required this.fileName,
  });

  final Uint8List bytes;
  final String contentType;
  final String fileName;

  bool get isPdf => contentType == 'application/pdf';
  bool get isImage => contentType.startsWith('image/');
}

/// رابط موقّع مؤقت لعرض المستند دون توكن (`SignedLinkDto`).
class EmployeeClipLink {
  const EmployeeClipLink({required this.url, this.expiresAt});

  final Uri url;
  final DateTime? expiresAt;

  factory EmployeeClipLink.fromApi(Map<String, dynamic> json) {
    final exp = json['expiresAt'];
    return EmployeeClipLink(
      url: Uri.parse((json['url'] as String?) ?? ''),
      expiresAt: exp is String ? DateTime.tryParse(exp) : null,
    );
  }
}
