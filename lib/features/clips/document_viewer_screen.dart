import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:printing/printing.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bottom_inset_spacer.dart';
import '../../core/widgets/pdf_frame.dart';
import '../../core/widgets/zoomable_view.dart';
import '../../data/models/employee_clip.dart';
import '../../data/repositories/documents_repository.dart';

/// عارض مستند واحد: يحمّل الملف بالتوكن (`/me/documents/:id/file`) ويعرضه
/// مع التكبير والتصغير، ويتيح حفظه على الجهاز ومشاركته.
class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({
    super.key,
    required this.clip,
    this.repository,
  });

  final EmployeeClip clip;
  final DocumentsRepository? repository;

  static Future<void> open(
    BuildContext context,
    EmployeeClip clip, {
    DocumentsRepository? repository,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentViewerScreen(clip: clip, repository: repository),
      ),
    );
  }

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  EmployeeClipFile? _file;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  DocumentsRepository get _repo => widget.repository ?? AppServices.documents;
  EmployeeClip get clip => widget.clip;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await _repo.fetchFile(clip);
      if (!mounted) return;
      setState(() {
        _file = file;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = describeDocumentError(e);
      });
    }
  }

  Future<void> _download() async {
    final file = _file;
    if (file == null || _saving) return;
    setState(() => _saving = true);
    try {
      final saved = await FilePicker.saveFile(
        dialogTitle: 'حفظ المستند',
        fileName: _safeFileName(file.fileName),
        bytes: file.bytes,
        mimeType: file.contentType,
      );
      if (saved != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المستند على الجهاز')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ المستند على هذا الجهاز')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'مستند' : cleaned;
  }

  // دالة ثابتة لا دالة جديدة في كل بناء: PdfPreview يعيد تصيير الصفحات
  // كلما تغيّرت دالة build.
  Future<Uint8List> _pdfBytes(PdfPageFormat _) async => _file!.bytes;

  // ضعف دقة ملء عرض الشاشة لتبقى الكتابة حادة عند التكبير، وبحد أعلى
  // يحدّ من ذاكرة الصفحات.
  double _pdfDpi() {
    final widthPx =
        MediaQuery.sizeOf(context).width *
        MediaQuery.devicePixelRatioOf(context);
    return math.min(
      2 * widthPx / PdfPageFormat.a4.width * PdfPageFormat.inch,
      300.0,
    );
  }

  Future<void> _share() async {
    final file = _file;
    if (file == null) return;
    try {
      await Printing.sharePdf(bytes: file.bytes, filename: file.fileName);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المشاركة غير متاحة على هذا الجهاز')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = clip.date == null
        ? null
        : DateFormat('yyyy/MM/dd', 'ar').format(clip.date!);
    final style = clipStyle(clip.kind);

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1A),
      appBar: AppBar(
        backgroundColor: style.color,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(clip.title, style: const TextStyle(fontSize: 16)),
            Text(
              [?date, clip.fileName].join(' · '),
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_file != null)
            IconButton(
              tooltip: 'تحميل',
              onPressed: _saving ? null : _download,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
            ),
          if (_file != null && _file!.isPdf)
            IconButton(
              tooltip: 'مشاركة',
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      bottomNavigationBar: const BottomInsetSpacer(),
      body: _buildBody(style),
    );
  }

  Widget _buildBody(ClipStyle style) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white70),
            SizedBox(height: 14),
            Text(
              'جاري تحميل المستند…',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.fileCircleXmark,
                size: 40,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              const Text(
                'تعذّر عرض المستند',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                style: FilledButton.styleFrom(backgroundColor: style.color),
              ),
            ],
          ),
        ),
      );
    }

    final file = _file!;
    if (file.isImage) {
      return ZoomableView(
        maxScale: 5,
        builder: (context, viewport) => SizedBox.fromSize(
          size: viewport,
          child: Image.memory(file.bytes, fit: BoxFit.contain),
        ),
      );
    }
    if (file.isPdf) {
      if (kIsWeb) {
        return buildPdfFrame(
          bytes: file.bytes,
          viewType: 'doc-${clip.id}-${file.bytes.length}',
        );
      }
      return PdfPreview.builder(
        build: _pdfBytes,
        pdfFileName: file.fileName,
        useActions: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        dpi: _pdfDpi(),
        scrollViewDecoration: const BoxDecoration(color: Color(0xFF1C1C1A)),
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
        onError: (context, error) => _UnsupportedFile(
          fileName: file.fileName,
          onDownload: _saving ? null : _download,
          message:
              'تعذّر عرض هذا الـ PDF داخل التطبيق؛ يمكنك تحميله إلى جهازك.',
        ),
        pagesBuilder: (context, pages) => ZoomableView(
          builder: (context, viewport) => SizedBox(
            width: viewport.width,
            child: Column(
              children: [
                for (var i = 0; i < pages.length; i++)
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(offset: Offset(0, 3), blurRadius: 5),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: pages[i].aspectRatio,
                      child: Image(
                        image: pages[i].image,
                        fit: BoxFit.cover,
                        semanticLabel: 'صفحة ${i + 1} من ${pages.length}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return _UnsupportedFile(
      fileName: file.fileName,
      onDownload: _saving ? null : _download,
      message:
          'نوع الملف (${file.contentType}) لا يُعرض داخل التطبيق؛ يمكنك تحميله إلى جهازك.',
    );
  }
}

class _UnsupportedFile extends StatelessWidget {
  const _UnsupportedFile({
    required this.fileName,
    required this.onDownload,
    required this.message,
  });

  final String fileName;
  final VoidCallback? onDownload;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.fileLines, size: 40, color: Colors.white70),
            const SizedBox(height: 14),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_rounded),
              label: const Text('تحميل الملف'),
            ),
          ],
        ),
      ),
    );
  }
}

/// أيقونة ولون لكل نوع مستند (مشتركة بين القائمة والعارض).
class ClipStyle {
  const ClipStyle(this.icon, this.color);

  final FaIconData icon;
  final Color color;
}

ClipStyle clipStyle(EmployeeClipKind kind) => switch (kind) {
      EmployeeClipKind.timesheetCard =>
        const ClipStyle(FontAwesomeIcons.clock, AppColors.info),
      EmployeeClipKind.paySlip =>
        const ClipStyle(FontAwesomeIcons.moneyBillWave, AppColors.success),
      EmployeeClipKind.productionVoucher =>
        const ClipStyle(FontAwesomeIcons.receipt, Color(0xFF8F7043)),
      EmployeeClipKind.message =>
        const ClipStyle(FontAwesomeIcons.envelopeOpenText, AppColors.goldDeep),
      EmployeeClipKind.other =>
        const ClipStyle(FontAwesomeIcons.fileLines, AppColors.slate),
    };

/// رسالة عربية لأخطاء المستندات (404 ملف مفقود، 503 فهرس غير متاح، شبكة…).
String describeDocumentError(Object e) {
  if (e is ApiException) {
    if (e.isNetwork) return 'لا يوجد اتصال بالخادم. تحقق من الشبكة وحاول مجدداً.';
    if (e.statusCode == 404) {
      return 'الملف غير موجود على خادم الملفات حالياً. قد يكون مستنداً قديماً لم يُنقل بعد.';
    }
    if (e.statusCode == 503) return 'فهرس المستندات غير متاح حالياً. حاول لاحقاً.';
    if (e.statusCode == 401) return 'انتهت الجلسة، أعد تسجيل الدخول.';
    if (e.statusCode == 403) return 'انتهت صلاحية الرابط أو غير مصرح بالوصول.';
    return e.message;
  }
  return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
