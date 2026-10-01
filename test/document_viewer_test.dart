import 'dart:convert';
import 'dart:typed_data';

import 'package:employee_affairs/core/network/api_exception.dart';
import 'package:employee_affairs/core/theme/app_theme.dart';
import 'package:employee_affairs/core/widgets/zoomable_view.dart';
import 'package:employee_affairs/data/models/employee_clip.dart';
import 'package:employee_affairs/data/repositories/documents_repository.dart';
import 'package:employee_affairs/features/clips/document_viewer_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:printing/printing.dart';
// ignore: implementation_imports
import 'package:printing/src/interface.dart';

/// A 1 × 1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

class _Documents implements DocumentsRepository {
  _Documents(this._fetch);

  final Future<EmployeeClipFile> Function() _fetch;

  @override
  Future<EmployeeClipsPage> list({
    String? month,
    int page = 1,
    int limit = 6,
  }) => throw UnimplementedError();

  @override
  Future<EmployeeClipFile> fetchFile(EmployeeClip clip) => _fetch();
}

/// Records what the screen hands to the system save dialog.
class _SaveDialog extends FilePickerPlatform {
  _SaveDialog(this.result);

  final Uri? result;
  final saved = <({String fileName, Uint8List bytes, String mimeType})>[];

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    saved.add((fileName: fileName, bytes: bytes, mimeType: mimeType));
    return result;
  }
}

_SaveDialog _saveDialog({Uri? result}) {
  final previous = FilePickerPlatform.instance;
  final dialog = _SaveDialog(result);
  FilePickerPlatform.instance = dialog;
  addTearDown(() => FilePickerPlatform.instance = previous);
  return dialog;
}

/// Stands in for the native PDF renderer; every document has two pages.
class _PdfRenderer extends PrintingPlatform {
  final renderedAtDpi = <double>[];

  @override
  Future<PrintingInfo> info() async => const PrintingInfo(canRaster: true);

  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {
    renderedAtDpi.add(dpi);
    for (var page = 0; page < 2; page++) {
      yield PdfRaster(20, 28, Uint8List(20 * 28 * 4));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

_PdfRenderer _pdfRenderer() {
  final previous = PrintingPlatform.instance;
  final renderer = _PdfRenderer();
  PrintingPlatform.instance = renderer;
  addTearDown(() => PrintingPlatform.instance = previous);
  return renderer;
}

/// PdfPreview renders 300 ms after it appears, then turns each page into an
/// image outside the test's fake clock.
Future<void> _waitForPdfPages(WidgetTester tester, int count) async {
  final lastPage = find.byWidgetPredicate(
    (widget) =>
        widget is Image && widget.semanticLabel == 'صفحة $count من $count',
  );
  for (var i = 0; i < 50 && lastPage.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(lastPage, findsOneWidget);
}

/// A 360 × 780 phone.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _openViewer(
  WidgetTester tester,
  Future<EmployeeClipFile> Function() fetch, {
  String fileName = 'scan.png',
}) async {
  await _pumpViewer(tester, fetch, fileName: fileName);
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester,
  Future<EmployeeClipFile> Function() fetch, {
  required String fileName,
}) async {
  _phone(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DocumentViewerScreen(
        repository: _Documents(fetch),
        clip: EmployeeClip(
          id: 7,
          title: 'قسيمة مالية',
          date: DateTime(2026, 9, 1),
          kind: EmployeeClipKind.paySlip,
          fileName: fileName,
        ),
      ),
    ),
  );
}

Future<void> _openImage(WidgetTester tester, {String fileName = 'scan.png'}) =>
    _openViewer(
      tester,
      () async => EmployeeClipFile(
        bytes: _png,
        contentType: 'image/png',
        fileName: fileName,
      ),
      fileName: fileName,
    );

Future<void> _tapButton(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pump();
}

Future<void> _doubleTap(WidgetTester tester, Offset at) async {
  await tester.tapAt(at);
  await tester.pump(kDoubleTapMinTime);
  await tester.tapAt(at);
  await tester.pumpAndSettle();
}

VoidCallback? _onPressed(WidgetTester tester, IconData icon) =>
    tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon)).onPressed;

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('there is no button that opens the document in another app', (
    tester,
  ) async {
    await _openImage(tester);

    expect(find.byTooltip('فتح في تطبيق خارجي'), findsNothing);
    expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);
    expect(find.byTooltip('تحميل'), findsOneWidget);
  });

  testWidgets('the zoom buttons step between 100٪ and the maximum', (
    tester,
  ) async {
    await _openImage(tester);

    expect(find.text('100٪'), findsOneWidget);
    expect(_onPressed(tester, Icons.zoom_out_rounded), isNull);
    expect(_onPressed(tester, Icons.fit_screen_rounded), isNull);

    await _tapButton(tester, 'تكبير');
    expect(find.text('150٪'), findsOneWidget);
    await _tapButton(tester, 'تكبير');
    expect(find.text('225٪'), findsOneWidget);
    await _tapButton(tester, 'تصغير');
    expect(find.text('150٪'), findsOneWidget);
    await _tapButton(tester, 'الحجم الأصلي');
    expect(find.text('100٪'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await _tapButton(tester, 'تكبير');
    }
    expect(find.text('500٪'), findsOneWidget);
    expect(_onPressed(tester, Icons.zoom_in_rounded), isNull);
  });

  testWidgets('a double tap zooms in and back out', (tester) async {
    await _openImage(tester);
    final center = tester.getCenter(find.byType(InteractiveViewer));

    await _doubleTap(tester, center);
    expect(find.text('250٪'), findsOneWidget);

    await _doubleTap(tester, center);
    expect(find.text('100٪'), findsOneWidget);
  });

  testWidgets('pinching with two fingers zooms in', (tester) async {
    await _openImage(tester);
    final center = tester.getCenter(find.byType(InteractiveViewer));

    final left = await tester.startGesture(center - const Offset(40, 0));
    final right = await tester.startGesture(center + const Offset(40, 0));
    for (var i = 0; i < 6; i++) {
      await left.moveBy(const Offset(-10, 0));
      await right.moveBy(const Offset(10, 0));
      await tester.pump();
    }
    await left.up();
    await right.up();
    await tester.pumpAndSettle();

    expect(find.text('100٪'), findsNothing);
    expect(_onPressed(tester, Icons.fit_screen_rounded), isNotNull);
  });

  testWidgets('the download button saves the file where the user chooses', (
    tester,
  ) async {
    final dialog = _saveDialog(result: Uri.parse('content://downloads/1'));
    await _openImage(tester);

    await tester.tap(find.byTooltip('تحميل'));
    await tester.pumpAndSettle();

    expect(dialog.saved, hasLength(1));
    expect(dialog.saved.single.fileName, 'scan.png');
    expect(dialog.saved.single.bytes, _png);
    expect(dialog.saved.single.mimeType, 'image/png');
    expect(find.text('تم حفظ المستند على الجهاز'), findsOneWidget);
  });

  testWidgets('cancelling the save dialog shows no message', (tester) async {
    final dialog = _saveDialog();
    await _openImage(tester);

    await tester.tap(find.byTooltip('تحميل'));
    await tester.pumpAndSettle();

    expect(dialog.saved, hasLength(1));
    expect(find.byType(SnackBar), findsNothing);
    expect(_onPressed(tester, Icons.download_rounded), isNotNull);
  });

  testWidgets('a file name cannot point into another folder', (tester) async {
    final dialog = _saveDialog(result: Uri.parse('content://downloads/1'));
    await _openImage(tester, fileName: r'../scans\9.png');

    await tester.tap(find.byTooltip('تحميل'));
    await tester.pumpAndSettle();

    expect(dialog.saved.single.fileName, '.._scans_9.png');
  });

  testWidgets('a file the app cannot show is offered as a download', (
    tester,
  ) async {
    final dialog = _saveDialog(result: Uri.parse('content://downloads/1'));
    await _openViewer(
      tester,
      () async => EmployeeClipFile(
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'application/msword',
        fileName: 'letter.doc',
      ),
      fileName: 'letter.doc',
    );

    expect(find.text('فتح / تحميل خارجياً'), findsNothing);
    await tester.tap(find.text('تحميل الملف'));
    await tester.pumpAndSettle();

    expect(dialog.saved.single.fileName, 'letter.doc');
    expect(dialog.saved.single.mimeType, 'application/msword');
  });

  testWidgets('a document that fails to load offers only a retry', (
    tester,
  ) async {
    await _openViewer(
      tester,
      () async => throw const ApiException(message: 'missing', statusCode: 404),
    );

    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.text('فتح عبر رابط مؤقت'), findsNothing);
    expect(find.byTooltip('تحميل'), findsNothing);
  });

  testWidgets('PDF pages render sharp, zoom together and survive a save', (
    tester,
  ) async {
    final renderer = _pdfRenderer();
    final dialog = _saveDialog(result: Uri.parse('content://downloads/1'));
    await _pumpViewer(
      tester,
      () async => EmployeeClipFile(
        bytes: Uint8List.fromList(utf8.encode('%PDF-1.4')),
        contentType: 'application/pdf',
        fileName: 'payslip.pdf',
      ),
      fileName: 'payslip.pdf',
    );
    await _waitForPdfPages(tester, 2);

    // Twice the test phone's 1080 px fit-to-width resolution.
    expect(
      renderer.renderedAtDpi.single,
      closeTo(2 * 1080 / PdfPageFormat.a4.width * PdfPageFormat.inch, 0.01),
    );
    expect(find.byType(ZoomableView), findsOneWidget);
    await _tapButton(tester, 'تكبير');
    expect(find.text('150٪'), findsOneWidget);

    await tester.tap(find.byTooltip('تحميل'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(dialog.saved.single.fileName, 'payslip.pdf');
    expect(dialog.saved.single.mimeType, 'application/pdf');
    expect(renderer.renderedAtDpi, hasLength(1));
    expect(find.text('150٪'), findsOneWidget);
  });

  testWidgets('zooming keeps a long document inside the view', (tester) async {
    _phone(tester);
    const contentHeight = 3000.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomableView(
            builder: (context, viewport) => SizedBox(
              width: viewport.width,
              height: contentHeight,
              child: const Placeholder(),
            ),
          ),
        ),
      ),
    );
    final viewer = find.byType(InteractiveViewer);
    final matrix = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    final viewportHeight = tester.getSize(viewer).height;

    await tester.drag(viewer, const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(
      matrix.value.getTranslation().y,
      closeTo(viewportHeight - contentHeight, 0.5),
    );

    await _tapButton(tester, 'تكبير');
    await _tapButton(tester, 'الحجم الأصلي');

    final offset = matrix.value.getTranslation();
    expect(matrix.value.getMaxScaleOnAxis(), 1);
    expect(offset.x, 0);
    expect(offset.y, inInclusiveRange(viewportHeight - contentHeight, 0));
  });
}
