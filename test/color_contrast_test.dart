import 'package:employee_affairs/core/theme/app_colors.dart';
import 'package:employee_affairs/core/theme/app_theme.dart';
import 'package:employee_affairs/core/widgets/status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG AA minimum for normal-size text; the app's labels are 12–14 px.
const _text = 4.5;

/// WCAG AA minimum for borders, focus rings, icons and selection indicators.
const _nonText = 3.0;

const _lightBackgrounds = {
  'background': AppColors.background,
  'surface': AppColors.surface,
  'white': Colors.white,
};

void _expectContrast(
  Color foreground,
  Color background,
  String pair,
  double minimum,
) {
  final ratio = _contrast(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(minimum),
    reason: '$pair is ${ratio.toStringAsFixed(2)}:1',
  );
}

void _expectReadable(Color text, Color background, String pair) =>
    _expectContrast(text, background, pair, _text);

void main() {
  test('contrast formula matches the WCAG reference values', () {
    expect(_contrast(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(_contrast(Colors.white, Colors.white), 1);
  });

  group('text colours on light surfaces', () {
    const texts = {
      'charcoal': AppColors.charcoal,
      'slate': AppColors.slate,
      'goldDeep': AppColors.goldDeep,
      'success': AppColors.success,
      'warning': AppColors.warning,
      'danger': AppColors.danger,
      'info': AppColors.info,
    };

    for (final text in texts.entries) {
      test(text.key, () {
        for (final background in _lightBackgrounds.entries) {
          _expectReadable(
            text.value,
            background.value,
            '${text.key} on ${background.key}',
          );
        }
      });
    }

    test('goldDeep on goldSoft', () {
      _expectReadable(AppColors.goldDeep, AppColors.goldSoft, 'goldDeep');
    });
  });

  group('borders, focus rings and icons', () {
    test('gold on light surfaces', () {
      for (final background in _lightBackgrounds.entries) {
        _expectContrast(
          AppColors.gold,
          background.value,
          'gold on ${background.key}',
          _nonText,
        );
      }
    });

    test('focused text field border', () {
      final input = AppTheme.light().inputDecorationTheme;
      _expectContrast(
        input.focusedBorder!.borderSide.color,
        input.fillColor!,
        'focus border',
        _nonText,
      );
    });
  });

  group('theme', () {
    final theme = AppTheme.light();
    final scheme = theme.colorScheme;

    test('filled button label', () {
      final style = theme.filledButtonTheme.style!;
      _expectReadable(
        style.foregroundColor!.resolve({})!,
        style.backgroundColor!.resolve({})!,
        'filled button label',
      );
    });

    test('primary text and onPrimary', () {
      _expectReadable(scheme.primary, AppColors.background, 'primary');
      _expectReadable(scheme.primary, scheme.surface, 'primary on surface');
      _expectReadable(scheme.onPrimary, scheme.primary, 'onPrimary');
    });

    test('chip label and checkmark', () {
      final chip = theme.chipTheme;
      final label = chip.labelStyle!.color!;
      _expectReadable(label, chip.backgroundColor!, 'chip label');
      _expectReadable(label, chip.selectedColor!, 'selected chip label');
      _expectReadable(chip.checkmarkColor!, chip.selectedColor!, 'checkmark');
    });

    test('navigation bar labels', () {
      final nav = theme.navigationBarTheme;
      for (final states in [<WidgetState>{}, {WidgetState.selected}]) {
        _expectReadable(
          nav.labelTextStyle!.resolve(states)!.color!,
          nav.backgroundColor!,
          'navigation label $states',
        );
      }
    });
  });

  group('status pills', () {
    for (final tone in StatusTone.values) {
      testWidgets(tone.name, (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: StatusPill(label: 'قيد المراجعة', tone: tone),
          ),
        );

        final label = tester.widget<Text>(find.byType(Text)).style!.color!;
        final tint =
            (tester.widget<Container>(find.byType(Container)).decoration!
                    as BoxDecoration)
                .color!;
        _expectReadable(label, tint, '${tone.name} pill');
      });
    }
  });
}
