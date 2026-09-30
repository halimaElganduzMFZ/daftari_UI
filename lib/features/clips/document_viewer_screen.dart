import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pdf_frame.dart';
import '../../data/models/employee_clip.dart';
import '../../data/repositories/documents_repository.dart';

/// عارض مستند واحد: يحمّل الملف بالتوكن (`/me/documents/:id/file`) ويعرضه،
/// مع فتحه خارجياً عبر رابط موقّع مؤقت (`/me/documents/:id/link`) ومشاركته.
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
  bool _linking = false;
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

  Future<void> _openExternally({bool download = false}) async {
    if (_linking) return;
    setState(() => _linking = true);
    try {
      final link = await _repo.signedLink(clip, download: download);
      final ok = await launchUrl(link.url, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الرابط على هذا الجهاز')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeDocumentError(e))),
      );
    } finally {
      if (mounted) setState(() => _linking = false);
    }
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
          IconButton(
            tooltip: 'فتح في تطبيق خارجي',
            onPressed: _linking ? null : () => _openExternally(),
            icon: _linking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.open_in_new_rounded),
          ),
          if (_file != null && _file!.isPdf)
            IconButton(
              tooltip: 'مشاركة / حفظ',
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
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
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                    style: FilledButton.styleFrom(backgroundColor: style.color),
                  ),
                  OutlinedButton.icon(
                    onPressed: _linking ? null : () => _openExternally(),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('فتح عبر رابط مؤقت'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final file = _file!;
    if (file.isImage) {
      return InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image.memory(file.bytes, fit: BoxFit.contain)),
      );
    }
    if (file.isPdf) {
      if (kIsWeb) {
        return buildPdfFrame(
          bytes: file.bytes,
          viewType: 'doc-${clip.id}-${file.bytes.length}',
        );
      }
      return PdfPreview(
        build: (_) async => file.bytes,
        pdfFileName: file.fileName,
        useActions: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        scrollViewDecoration: const BoxDecoration(color: Color(0xFF1C1C1A)),
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
        onError: (context, error) => _UnsupportedFile(
          fileName: file.fileName,
          onOpen: () => _openExternally(),
          message: 'تعذّر تصيير الـ PDF على هذا الجهاز؛ افتحه في تطبيق خارجي.',
        ),
      );
    }
    return _UnsupportedFile(
      fileName: file.fileName,
      onOpen: () => _openExternally(download: true),
      message: 'نوع الملف (${file.contentType}) لا يُعرض داخل التطبيق.',
    );
  }
}

class _UnsupportedFile extends StatelessWidget {
  const _UnsupportedFile({
    required this.fileName,
    required this.onOpen,
    required this.message,
  });

  final String fileName;
  final VoidCallback onOpen;
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
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('فتح / تحميل خارجياً'),
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
