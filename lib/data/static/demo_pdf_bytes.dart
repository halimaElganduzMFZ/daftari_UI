import 'dart:convert';
import 'dart:typed_data';

/// مولّد PDF تجريبي صغير للمعاينة (بدون حزم خارجية).
///
/// **أفضل تخزين للإنتاج:** ملف كمرفق على التخزين (Disk/S3) + مسار/رابط في DB.
/// **Base64 داخل DB:** مناسب للتجارب أو الملفات الصغيرة جداً فقط.
abstract final class DemoPdfBytes {
  static Uint8List? _cached;

  static Uint8List get studyAcceptance => _cached ??= _build();

  static Uint8List _build() {
    final content = utf8.encode(
      'BT\n'
      '/F1 22 Tf\n'
      '72 760 Td\n'
      '(Study Leave Acceptance) Tj\n'
      '0 -28 Td\n'
      '/F1 13 Tf\n'
      '(Free Zone - Demo Attachment) Tj\n'
      '0 -22 Td\n'
      '(Employee sample document for in-app preview.) Tj\n'
      '0 -22 Td\n'
      '(Status: Valid for design demo) Tj\n'
      'ET\n',
    );

    final objects = <List<int>>[];
    void addObject(String header, [List<int>? stream]) {
      final buffer = BytesBuilder();
      buffer.add(utf8.encode(header));
      if (stream != null) {
        buffer.add(utf8.encode('stream\n'));
        buffer.add(stream);
        buffer.add(utf8.encode('\nendstream\n'));
      }
      buffer.add(utf8.encode('endobj\n'));
      objects.add(buffer.toBytes());
    }

    addObject('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\n');
    addObject('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\n');
    addObject(
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
      '/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\n',
    );
    addObject(
      '4 0 obj\n<< /Length ${content.length} >>\n',
      content,
    );
    addObject(
      '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\n',
    );

    final out = BytesBuilder();
    out.add(utf8.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'));
    final offsets = <int>[0];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(out.length);
      out.add(objects[i]);
    }
    final xrefStart = out.length;
    out.add(utf8.encode('xref\n0 ${objects.length + 1}\n'));
    out.add(utf8.encode('0000000000 65535 f \n'));
    for (var i = 1; i < offsets.length; i++) {
      out.add(
        utf8.encode('${offsets[i].toString().padLeft(10, '0')} 00000 n \n'),
      );
    }
    out.add(
      utf8.encode(
        'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
        'startxref\n$xrefStart\n%%EOF\n',
      ),
    );
    return out.toBytes();
  }
}
