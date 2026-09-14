import 'dart:typed_data';

import '../static/demo_pdf_bytes.dart';

/// نوع معاينة المرفق حسب الامتداد.
enum AttachmentKind { pdf, word, image, other }

/// مرفق طلب (إجازة دراسية وغيرها).
///
/// **أفضل تخزين للإنتاج:**
/// احفظ الملف كمرفق على التخزين (Disk/S3) واحفظ `storageKey` أو URL في DB،
/// ثم اجلب الـ bytes أو افتح الرابط في المعاينة.
///
/// **Base64 داخل قاعدة البيانات:** مناسب للتجربة أو الملفات الصغيرة جداً فقط.
class RequestAttachment {
  const RequestAttachment({
    required this.fileName,
    this.fileSizeBytes,
    this.extension,
    this.bytes,
    this.title = 'مستند الإجازة الدراسية',
    this.uploadedAt,
    this.storageKey,
  });

  final String fileName;
  final int? fileSizeBytes;
  final String? extension;
  final Uint8List? bytes;
  final String title;
  final DateTime? uploadedAt;

  /// مفتاح/مسار التخزين عند ربط الـ API لاحقاً.
  final String? storageKey;

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
    final size = fileSizeBytes ?? bytes?.length;
    if (size == null) return '—';
    final kb = size / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} ك.ب';
    return '${(kb / 1024).toStringAsFixed(1)} م.ب';
  }

  bool get hasPreviewBytes => bytes != null && bytes!.isNotEmpty;

  static String _extFromName(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0 || i == name.length - 1) return '';
    return name.substring(i + 1);
  }

  /// مرفق تجريبي مع PDF حقيقي (bytes من Base64/مولّد) لمعاينة العرض.
  static RequestAttachment demoStudy({
    String fileName = 'قبول_دراسي_2026.pdf',
    int? sizeBytes,
    DateTime? uploadedAt,
    AttachmentKind forceKind = AttachmentKind.pdf,
  }) {
    final ext = switch (forceKind) {
      AttachmentKind.pdf => 'pdf',
      AttachmentKind.word => 'docx',
      AttachmentKind.image => 'jpg',
      AttachmentKind.other => 'bin',
    };
    final name = fileName.contains('.') ? fileName : '$fileName.$ext';
    final pdfBytes =
        forceKind == AttachmentKind.pdf ? DemoPdfBytes.studyAcceptance : null;
    return RequestAttachment(
      fileName: name,
      fileSizeBytes: sizeBytes ?? pdfBytes?.length ?? 842000,
      extension: ext,
      bytes: pdfBytes,
      title: 'مستند الإجازة الدراسية',
      uploadedAt: uploadedAt ?? DateTime(2026, 9, 8, 10, 24),
      storageKey: 'demo/study/$name',
    );
  }
}
