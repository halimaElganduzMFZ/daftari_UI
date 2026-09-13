import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'permission_type.dart';

/// نوع إجازة مع ضوابطه — من Taking_a_day_off.php.
class LeaveKind {
  const LeaveKind({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.points,
    required this.fullText,
    this.fixedDays,
    this.needsLocation = false,
    this.needsEmergencyReason = false,
    this.needsStudyAttachment = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final FaIconData icon;
  final List<RegulationPoint> points;
  final String fullText;
  final int? fixedDays;
  final bool needsLocation;
  final bool needsEmergencyReason;
  final bool needsStudyAttachment;
}
