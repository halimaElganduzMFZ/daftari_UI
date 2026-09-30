import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/employee_asset.dart';
import '../../data/repositories/assets_repository.dart';
import '../../data/session/app_session.dart';

/// قائمة أصول الموظف + معاينة طباعة (بديل Employee_Assets.php) — `GET /me/assets`.
class EmployeeAssetsScreen extends StatefulWidget {
  const EmployeeAssetsScreen({super.key, this.repository});

  /// للاختبارات؛ الافتراضي `AppServices.assets`.
  final AssetsRepository? repository;

  @override
  State<EmployeeAssetsScreen> createState() => _EmployeeAssetsScreenState();
}

class _EmployeeAssetsScreenState extends State<EmployeeAssetsScreen> {
  static const _pageSize = 10;

  int _visibleCount = _pageSize;
  EmployeeAssetsResult? _result;
  bool _loading = true;
  String? _error;

  AssetsRepository get _repo => widget.repository ?? AppServices.assets;

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
      final result = await _repo.list();
      if (!mounted) return;
      setState(() {
        _result = result;
        _visibleCount = _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = switch (e) {
          ApiException(isNetwork: true) =>
            'لا يوجد اتصال بالخادم. تحقق من الشبكة وحاول مجدداً.',
          ApiException(statusCode: 401) => 'انتهت الجلسة، أعد تسجيل الدخول.',
          ApiException(statusCode: 403) =>
            'هذه الصفحة متاحة لحساب الموظف فقط.',
          ApiException(:final message) => message,
          _ => 'حدث خطأ غير متوقع. حاول مرة أخرى.',
        };
      });
    }
  }

  Future<void> _openPrintPreview({
    required List<EmployeeAsset> assets,
    required String name,
    required String employeeNumber,
    required String department,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AssetsPrintPreviewPage(
          employeeName: name,
          employeeNumber: employeeNumber,
          department: department,
          assets: assets,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final result = _result;
    final assets = result?.assets ?? const <EmployeeAsset>[];
    final theme = Theme.of(context);

    final name = employee?.fullName ?? 'موظف';
    final employeeNumber = employee?.employeeNumber ?? '—';
    final department = employee?.department ?? '—';
    final visible = assets.take(_visibleCount).toList();
    final hasMore = _visibleCount < assets.length;
    final ready = !_loading && _error == null && result != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الأصول المسجلة'),
        actions: [
          if (ready && assets.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilledButton.icon(
                onPressed: () => _openPrintPreview(
                  assets: assets,
                  name: name,
                  employeeNumber: employeeNumber,
                  department: department,
                ),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('طباعة'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.goldDeep,
        onRefresh: _load,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'عرض أصولك المسجّلة لديك وطباعتها عند الحاجة.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _EmployeeBanner(
            name: name,
            employeeNumber: employeeNumber,
            department: department,
          ),
          const SizedBox(height: 20),
          if (_loading)
            const _AssetsSkeleton()
          else if (_error != null)
            _StatusCard(
              icon: Icons.cloud_off_rounded,
              title: 'تعذّر تحميل الأصول',
              message: _error!,
              onRetry: _load,
            )
          else if (result != null && !result.available)
            _StatusCard(
              icon: Icons.inventory_outlined,
              title: 'سجل الأصول غير متاح حالياً',
              message:
                  'خادم سجل الأصول مطفأ أو لا يمكن الوصول إليه من الـ API. حاول لاحقاً أو راجع قسم الأصول.',
              onRetry: _load,
            )
          else if (assets.isEmpty)
            const _EmptyAssets()
          else ...[
            Row(
              children: [
                Text(
                  'قائمة الأصول',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const Spacer(),
                Text(
                  assets.length > _pageSize
                      ? 'عرض ${visible.length} من ${assets.length}'
                      : '${assets.length} عنصر',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _TableHeader(),
            const SizedBox(height: 4),
            for (var i = 0; i < visible.length; i++) ...[
              _AssetRow(asset: visible[i]),
              if (i != visible.length - 1)
                const Divider(height: 1, color: AppColors.line),
            ],
            if (hasMore) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _visibleCount =
                      (_visibleCount + _pageSize).clamp(0, assets.length);
                }),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  'عرض المزيد (${assets.length - visible.length})',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.goldDeep,
                  side: const BorderSide(color: AppColors.gold),
                ),
              ),
            ],
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => _openPrintPreview(
                assets: assets,
                name: name,
                employeeNumber: employeeNumber,
                department: department,
              ),
              icon: const Icon(Icons.print_outlined),
              label: const Text('معاينة وطباعة القائمة'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستفتح معاينة ثم أمر الطباعة للجهاز المتصل (أو حفظ كملف PDF).',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
                height: 1.45,
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}

class _AssetsSkeleton extends StatelessWidget {
  const _AssetsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width) => Container(
          width: width,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar(110),
        const SizedBox(height: 18),
        for (var i = 0; i < 5; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Row(
              children: [
                SizedBox(width: 40, child: bar(18)),
                SizedBox(width: 110, child: bar(70)),
                Expanded(child: bar(double.infinity)),
              ],
            ),
          ),
          if (i != 4) const Divider(height: 1, color: AppColors.line),
        ],
      ],
    );
  }
}

/// خطأ تحميل أو «سجل غير متاح» مع زر إعادة المحاولة.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.slate.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
              height: 1.45,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldDeep,
                side: const BorderSide(color: AppColors.gold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmployeeBanner extends StatelessWidget {
  const _EmployeeBanner({
    required this.name,
    required this.employeeNumber,
    required this.department,
  });

  final String name;
  final String employeeNumber;
  final String department;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'الرقم الوظيفي: $employeeNumber',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            department,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.slate,
          fontWeight: FontWeight.w700,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('ر.م', style: style)),
          SizedBox(width: 110, child: Text('الرقم المالي', style: style)),
          Expanded(child: Text('الأصل', style: style)),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset});

  final EmployeeAsset asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${asset.serial}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.goldDeep,
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              asset.financialNumber,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
            ),
          ),
          Expanded(
            child: Text(
              asset.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssets extends StatelessWidget {
  const _EmptyAssets();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.slate.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 14),
          Text(
            'لا توجد أصول مسجّلة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'عند تسجيل أصول باسمك ستظهر هنا ويمكنك طباعتها.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetsPrintPreviewPage extends StatelessWidget {
  const _AssetsPrintPreviewPage({
    required this.employeeName,
    required this.employeeNumber,
    required this.department,
    required this.assets,
  });

  final String employeeName;
  final String employeeNumber;
  final String department;
  final List<EmployeeAsset> assets;

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final regularData =
        await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);

    final now = DateTime.now();
    final dateLabel =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    // pdf Table يرسم الأعمدة من اليسار لليمين دائماً، لذلك نعكس الترتيب
    // ليظهر بصرياً RTL: يمين = ر.م ، وسط = الرقم المالي ، يسار = الأصل
    pw.Widget cell(
      String text, {
      pw.Font? font,
      bool header = false,
      pw.TextAlign align = pw.TextAlign.right,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        alignment: align == pw.TextAlign.center
            ? pw.Alignment.center
            : pw.Alignment.centerRight,
        child: pw.Text(
          text,
          textAlign: align,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
            font: font ?? regular,
            fontSize: header ? 10 : 10,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'قائمة أصول الموظف',
              style: pw.TextStyle(font: bold, fontSize: 18),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'الاسم: $employeeName',
            style: pw.TextStyle(font: regular, fontSize: 11),
            textAlign: pw.TextAlign.right,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'الرقم الوظيفي: $employeeNumber',
            style: pw.TextStyle(font: regular, fontSize: 11),
            textAlign: pw.TextAlign.right,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'الإدارة: $department',
            style: pw.TextStyle(font: regular, fontSize: 11),
            textAlign: pw.TextAlign.right,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 18),
          pw.Table(
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xFFE2E0DC),
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(), // الأصل (يسار الصفحة)
              1: const pw.FixedColumnWidth(95), // الرقم المالي
              2: const pw.FixedColumnWidth(42), // ر.م (يمين الصفحة)
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF3EADA),
                ),
                children: [
                  cell('الأصل', font: bold, header: true),
                  cell(
                    'الرقم المالي',
                    font: bold,
                    header: true,
                    align: pw.TextAlign.center,
                  ),
                  cell(
                    'ر.م',
                    font: bold,
                    header: true,
                    align: pw.TextAlign.center,
                  ),
                ],
              ),
              for (final a in assets)
                pw.TableRow(
                  children: [
                    cell(a.name),
                    cell(
                      a.financialNumber,
                      align: pw.TextAlign.center,
                    ),
                    cell(
                      '${a.serial}',
                      align: pw.TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'تاريخ الطباعة: $dateLabel',
            style: pw.TextStyle(
              font: regular,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.right,
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('معاينة الطباعة'),
      ),
      body: PdfPreview(
        build: _buildPdf,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'employee_assets.pdf',
        actions: const [],
      ),
    );
  }
}
