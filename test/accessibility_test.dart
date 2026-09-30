import 'dart:convert';

import 'package:employee_affairs/core/constants/app_strings.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/core/theme/app_theme.dart';
import 'package:employee_affairs/core/utils/large_text.dart';
import 'package:employee_affairs/core/widgets/date_range_filter_bar.dart';
import 'package:employee_affairs/core/widgets/status_pill.dart';
import 'package:employee_affairs/data/models/announcements.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';
import 'package:employee_affairs/features/auth/login_screen.dart';
import 'package:employee_affairs/features/home/announcements_banner.dart';
import 'package:employee_affairs/features/manager/remote_manager_attendance_screen.dart';
import 'package:employee_affairs/features/manager/remote_manager_requests_screen.dart';
import 'package:employee_affairs/features/manager/remote_manager_widgets.dart';
import 'package:employee_affairs/features/request/widgets/all_regulations_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart' show DateFormat;

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Directionality(textDirection: TextDirection.rtl, child: home),
);

/// A 360 × 780 phone, the narrow end of common Android screens.
void _phone(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

AnnouncementsFeed _feed({required bool autoplay}) => AnnouncementsFeed.fromApi({
  'slideshow': {'intervalSeconds': 3, 'autoplay': autoplay, 'loop': true},
  'items': [
    {
      'id': 1,
      'title': 'تعميم بشأن مواعيد الدوام الرسمي خلال شهر رمضان المبارك',
      'body': 'يبدأ الدوام الساعة التاسعة صباحاً وينتهي الساعة الثانية ظهراً '
          'في جميع الإدارات والأقسام',
      'linkUrl': 'https://example.com',
      'pinned': true,
    },
    {'id': 2, 'title': 'إعلان ثانٍ'},
  ],
});

AnnouncementsFeed _shortLinkFeed() => AnnouncementsFeed.fromApi({
  'slideshow': {'intervalSeconds': 3, 'autoplay': false, 'loop': true},
  'items': [
    {'id': 1, 'title': 'إعلان', 'linkUrl': 'https://example.com'},
  ],
});

double _bannerPage(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!.page!;

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Scrolls the page itself, not the text fields or tables inside it.
Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('status pills announce the status with a distinct icon per tone', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Wrap(
            children: [
              for (final tone in StatusTone.values)
                StatusPill(label: tone.name, tone: tone),
            ],
          ),
        ),
      ),
    );

    for (final tone in StatusTone.values) {
      expect(find.bySemanticsLabel('الحالة: ${tone.name}'), findsOneWidget);
    }
    final icons = tester.widgetList<Icon>(find.byType(Icon)).map((i) => i.icon);
    expect(icons.toSet(), hasLength(StatusTone.values.length));
    semantics.dispose();
  });

  group('login screen', () {
    testWidgets('names both fields and the password toggle', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const LoginScreen()));
      await tester.pumpAndSettle();

      final username = tester.getSemantics(find.byType(TextField).first);
      final password = tester.getSemantics(find.byType(TextField).last);
      expect(username, isSemantics(isTextField: true));
      expect(username.label, startsWith(AppStrings.username));
      // The field's name only: no asterisks from the hint.
      expect(
        password,
        isSemantics(label: AppStrings.password, isTextField: true),
      );
      // The visible labels above the fields are not read a second time.
      expect(find.bySemanticsLabel(AppStrings.password), findsOneWidget);

      await tester.tap(find.byTooltip(AppStrings.showPassword));
      await tester.pump();
      expect(find.byTooltip(AppStrings.hidePassword), findsOneWidget);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('fits a 360 px phone at 200 % text', (tester) async {
      _phone(tester, textScale: 2);
      await tester.pumpWidget(_app(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the card at once when animations are removed', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(_app(const LoginScreen()));
      await tester.pump();

      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(AppStrings.orgName),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1);
    });
  });

  group('announcements banner', () {
    Future<void> pumpBanner(WidgetTester tester, AnnouncementsFeed feed) =>
        tester.pumpWidget(
          _app(
            Scaffold(
              body: ListView(children: [AnnouncementsBanner(feed: feed)]),
            ),
          ),
        );

    testWidgets('advances on its own by default', (tester) async {
      await pumpBanner(tester, _feed(autoplay: true));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(_bannerPage(tester), 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    for (final (reason, features) in [
      (
        'animations are removed',
        const FakeAccessibilityFeatures(disableAnimations: true),
      ),
      (
        'a screen reader is on',
        const FakeAccessibilityFeatures(accessibleNavigation: true),
      ),
    ]) {
      testWidgets('stays on the first slide when $reason', (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue = features;
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pumpBanner(tester, _feed(autoplay: true));
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();

        expect(_bannerPage(tester), 0);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    // A pinned slide with a two-line title, a two-line body and a link is
    // taller than the slide at normal text size too.
    for (final scale in [1.0, 2.0]) {
      testWidgets('fits a 360 px phone at ${(scale * 100).round()} % text', (
        tester,
      ) async {
        _phone(tester, textScale: scale);
        await pumpBanner(tester, _feed(autoplay: false));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('keeps the tap-to-open hint when there is room', (tester) async {
      _phone(tester);
      await pumpBanner(tester, _shortLinkFeed());
      await tester.pump();

      expect(find.text('اضغط للفتح'), findsOneWidget);
    });
  });

  group('large text', () {
    testWidgets('starts at 130 %', (tester) async {
      final results = <double, bool>{};
      for (final scale in [1.0, 1.15, 1.3, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) {
                results[scale] = isLargeText(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();

      expect(results, {1.0: false, 1.15: false, 1.3: true, 2.0: true});
    });

    Widget pillRow() => _app(
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(20),
          child: StatusPillRow(
            content: Text('إجازة سنوية'),
            pill: StatusPill(label: 'قيد المراجعة', tone: StatusTone.warning),
          ),
        ),
      ),
    );

    testWidgets('keeps the status pill beside the text at normal size', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(pillRow());

      final text = tester.getRect(find.text('إجازة سنوية'));
      final pill = tester.getRect(find.byType(StatusPill));
      expect(pill.top, lessThan(text.bottom));
      expect(pill.bottom, greaterThan(text.top));
    });

    testWidgets('moves the status pill under full-width text when large', (
      tester,
    ) async {
      _phone(tester, textScale: 2);
      await tester.pumpWidget(pillRow());

      final text = tester.getRect(find.text('إجازة سنوية'));
      final pill = tester.getRect(find.byType(StatusPill));
      expect(pill.top, greaterThanOrEqualTo(text.bottom));
      expect(text.width, 320);
    });

    final format = DateFormat('yyyy/MM/dd');
    final from = DateTime(2026, 9, 1);
    final to = DateTime(2026, 9, 29);
    Widget dateBar() => _app(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: DateRangeFilterBar(
            from: from,
            to: to,
            onFromChanged: (_) {},
            onToChanged: (_) {},
          ),
        ),
      ),
    );

    testWidgets('keeps the two dates side by side at normal size', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(dateBar());

      final fromRect = tester.getRect(find.text(format.format(from)));
      final toRect = tester.getRect(find.text(format.format(to)));
      expect(toRect.top, fromRect.top);
    });

    testWidgets('gives each date a full-width field when large', (
      tester,
    ) async {
      _phone(tester, textScale: 2);
      await tester.pumpWidget(dateBar());

      final fromRect = tester.getRect(find.text(format.format(from)));
      final toRect = tester.getRect(find.text(format.format(to)));
      expect(toRect.top, greaterThan(fromRect.bottom));
    });
  });

  group('live manager screens at 200 % text', () {
    testWidgets('the inbox and its swipe card fit a 360 px phone', (
      tester,
    ) async {
      _phone(tester, textScale: 2);
      const name = 'عبد الرحمن محمد الساعدي';
      final client = ApiClient(
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/lookups/request-types')) {
            return _json([
              {'code': 'ANNUAL_LEAVE', 'label': 'إجازة سنوية'},
            ]);
          }
          if (path.endsWith('/counts')) {
            return _json({'pending': 1, 'approved': 12, 'rejected': 3});
          }
          return _json({
            'data': [
              {
                'id': 7,
                'status': 'pending',
                'state': 'بانتظار اعتماد المدير المباشر',
                'type': 'إجازة سنوية',
                'fromDate': '2026-10-04',
                'toDate': '2026-10-08',
                'employee': {'name': name, 'number': 'FZ-10021'},
              },
            ],
            'meta': {'hasNext': false, 'total': 1},
          });
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: RemoteManagerRequestsScreen(
              repository: ManagerRepository(client),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text(name));

      expect(find.byType(ManagerSwipeActions), findsOneWidget);
    });

    testWidgets('attendance rows grow to show a long note', (tester) async {
      _phone(tester, textScale: 2);
      const note =
          'حضر متأخراً بسبب ازدحام الطريق عند البوابة الرئيسية للمنطقة الحرة';
      final client = ApiClient(
        httpClient: MockClient(
          (_) async => _json({
            'status': 'ok',
            'summary': {'days': 1, 'present': 1},
            'days': [
              {
                'date': '2026-09-23',
                'weekdayName': 'الأربعاء',
                'dayTypeName': 'دوام العمل',
                'punches': {
                  'checkIn': {'time': '08:41'},
                },
                'verdict': {'status': 'present', 'text': 'حاضر'},
                'note': note,
              },
            ],
          }),
        ),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        _app(
          ManagerEmployeeAttendanceScreen(
            repository: ManagerRepository(client),
            employee: const {'id': 4321, 'name': 'موظف الاختبار'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text(note));

      final paragraph = tester.renderObject<RenderParagraph>(find.text(note));
      expect(paragraph.size.height, paragraph.textSize.height);
    });
  });

  testWidgets('regulations tab chips grow with 200 % text', (tester) async {
    _phone(tester, textScale: 2);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showAllRegulationsSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The chip strip used to be a list pinned at 46 px.
    expect(tester.getSize(find.byType(ChoiceChip).first).height, greaterThan(46));
  });
}
