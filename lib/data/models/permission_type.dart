import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// نقطة لائحة واحدة (مادة + نص).
class RegulationPoint {
  const RegulationPoint({required this.article, required this.text});

  final String article;
  final String text;
}

/// نوع إذن مع ضوابطه — مستخرج من makeRequest.php.
class PermissionType {
  const PermissionType({
    required this.id,
    required this.title,
    required this.icon,
    required this.points,
    required this.fullText,
  });

  final String id;
  final String title;
  final FaIconData icon;
  final List<RegulationPoint> points;
  final String fullText;
}
