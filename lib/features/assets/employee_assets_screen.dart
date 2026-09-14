import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/employee_asset.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_employee_assets.dart';

/// قائمة أصول الموظف + معاينة طباعة (بديل Employee_Assets.php).
class EmployeeAssetsScreen extends StatelessWidget {
  const EmployeeAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final assets = kStaticEmployeeAssets;
    final theme = Theme.of(context);

    final name = employee?.fullName ?? 'موظف';
    final employeeNumber = employee?.employeeNumber ?? '—';
    final department = employee?.department ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الأصول المسجلة'),
        actions: [
          if (assets.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilledButton.icon(
                onPressed: () => _openPrintPreview(
                  context,
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
      body: ListView(
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
          if (assets.isEmpty)
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
                  '${assets.length} عنصر',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _TableHeader(),
            const SizedBox(height: 4),
            for (var i = 0; i < assets.length; i++) ...[
              _AssetRow(asset: assets[i]),
              if (i != assets.length - 1)
                const Divider(height: 1, color: AppColors.line),
            ],
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => _openPrintPreview(
                context,
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
    );
  }

  Future<void> _openPrintPreview(
    BuildContext context, {
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

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'قائمة أصول الموظف',
            style: pw.TextStyle(font: bold, fontSize: 18),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 16),
          pw.Text('الاسم: $employeeName', style: pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(
            'الرقم الوظيفي: $employeeNumber',
            style: pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Text('الإدارة: $department', style: pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const ['ر.م', 'الرقم المالي', 'الأصل'],
            data: [
              for (final a in assets)
                ['${a.serial}', a.financialNumber, a.name],
            ],
            headerStyle: pw.TextStyle(font: bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF3EADA),
            ),
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xFFE2E0DC),
              width: 0.5,
            ),
            cellAlignment: pw.Alignment.centerRight,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
            },
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FixedColumnWidth(90),
              2: const pw.FlexColumnWidth(),
            },
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'تاريخ الطباعة: $dateLabel',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
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
