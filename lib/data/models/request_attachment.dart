import 'dart:typed_data';

/// نوع معاينة المرفق حسب الامتداد.
enum AttachmentKind { pdf, word, image, other }

/// مرفق طلب (إجازة دراسية وغيرها).
class RequestAttachment {
  const RequestAttachment({
    required this.fileName,
    this.fileSizeBytes,
    this.extension,
    this.bytes,
    this.title = 'مستند الإجازة الدراسية',
    this.uploadedAt,
  });

  final String fileName;
  final int? fileSizeBytes;
  final String? extension;
  final Uint8List? bytes;
  final String title;
  final DateTime? uploadedAt;

  AttachmentKind get kind {
    final ext = (extension ?? _extFromName(fileName)).toLowerCase();
    return switch (ext) {
      'pdf' => AttachmentKind.pdf,
      'doc' || 'docx' => AttachmentKind.word,
      'jpg' || 'jpeg' || 'png' || 'webp' || 'gif' => AttachmentKind.image,
      _ => AttachmentKind.other,
    };
  }

  String get extensionLabel {
    final ext = (extension ?? _extFromName(fileName)).toUpperCase();
    return ext.isEmpty ? 'FILE' : ext;
  }

  String get sizeLabel {
    if (fileSizeBytes == null) return '—';
    final kb = fileSizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} ك.ب';
    return '${(kb / 1024).toStringAsFixed(1)} م.ب';
  }

  static String _extFromName(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0 || i == name.length - 1) return '';
    return name.substring(i + 1);
  }

  /// مرفق تجريبي لمعاينة التصميم قبل ربط الخادم.
  static RequestAttachment demoStudy({
    String fileName = 'قبول_دراسي_2026.pdf',
    int sizeBytes = 842000,
    DateTime? uploadedAt,
    AttachmentKind forceKind = AttachmentKind.pdf,
  }) {
    final ext = switch (forceKind) {
      AttachmentKind.pdf => 'pdf',
      AttachmentKind.word => 'docx',
      AttachmentKind.image => 'jpg',
      AttachmentKind.other => 'bin',
    };
    final name = fileName.contains('.')
        ? fileName
        : '$fileName.$ext';
    return RequestAttachment(
      fileName: name,
      fileSizeBytes: sizeBytes,
      extension: ext,
      title: 'مستند الإجازة الدراسية',
      uploadedAt: DateTime(2026, 9, 8, 10, 24),
    );
  }
}
