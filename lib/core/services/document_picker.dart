import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// نتيجة اختيار مرفق من جهاز المستخدم (ويب / جوال / سطح مكتب).
class PickedAttachment {
  const PickedAttachment({
    required this.name,
    this.bytes,
    this.size,
    this.extension,
  });

  final String name;
  final Uint8List? bytes;
  final int? size;
  final String? extension;
}

/// اختيار مستندات الإجازة الدراسية وغيرها.
///
/// على الويب: المتصفح يفتح نافذة ملفات الجهاز عند الضغط فقط
/// (لا توجد سماحية مسبقة دائمة مثل أندرويد؛ هذا قيد أمني في المتصفح).
abstract final class DocumentPicker {
  static const allowedExtensions = <String>[
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
  ];

  /// يفتح مستعرض ملفات الجهاز ويُرجع الملف المختار أو null عند الإلغاء.
  static Future<PickedAttachment?> pickStudyDocument() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'اختر مستند الإجازة الدراسية',
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (files.isEmpty) return null;

    final file = files.first;
    final name = file.name.trim().isEmpty ? 'مرفق_دراسي' : file.name;
    final bytes = await file.readAsBytes();
    final size = file.lengthSync() ?? bytes.length;

    return PickedAttachment(
      name: name,
      bytes: bytes,
      size: size,
      extension: file.extension,
    );
  }
}
