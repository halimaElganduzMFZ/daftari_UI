import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// بند لائحة عادي (مادة + نص).
class RegulationItem {
  const RegulationItem({required this.article, required this.text});

  final String article;
  final String text;
}

/// قسم داخل تبويب (عنوان + بنود).
class RegulationSection {
  const RegulationSection({
    required this.title,
    this.items = const [],
    this.penaltyCategories = const [],
  });

  final String title;
  final List<RegulationItem> items;
  final List<PenaltyCategory> penaltyCategories;

  bool get isPenaltyTable => penaltyCategories.isNotEmpty;
}

/// خلية في جدول الجزاءات (قد تمتد على أكثر من عمود).
class PenaltyCell {
  const PenaltyCell(this.text, {this.colspan = 1});

  final String text;
  final int colspan;
}

/// صف مخالفة في جدول الجزاءات.
class PenaltyRow {
  const PenaltyRow({required this.violation, required this.penalties});

  final String violation;
  final List<PenaltyCell> penalties;
}

/// فئة مخالفات داخل جدول الجزاءات.
class PenaltyCategory {
  const PenaltyCategory({
    required this.title,
    required this.shortLabel,
    required this.headers,
    required this.rows,
  });

  final String title;
  final String shortLabel;
  final List<String> headers;
  final List<PenaltyRow> rows;
}

/// تبويب في مركز اللوائح.
class RegulationTab {
  const RegulationTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.sections,
  });

  final String id;
  final String label;
  final FaIconData icon;
  final List<RegulationSection> sections;
}
