import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/attachment_viewer.dart';
import '../../data/models/employee_clip.dart';
import '../../data/models/request_attachment.dart';
import '../../data/static/static_employee_clips.dart';

/// قصاصات ومستندات الموظف (بديل getYourPdfs.php).
class EmployeeClipsScreen extends StatefulWidget {
  const EmployeeClipsScreen({super.key});

  @override
  State<EmployeeClipsScreen> createState() => _EmployeeClipsScreenState();
}

class _EmployeeClipsScreenState extends State<EmployeeClipsScreen> {
  static const _pageSize = 6;
  int _visible = _pageSize;

  FaIconData _iconFor(EmployeeClipKind kind) => switch (kind) {
        EmployeeClipKind.timesheetCard => FontAwesomeIcons.clock,
        EmployeeClipKind.paySlip => FontAwesomeIcons.moneyBillWave,
        EmployeeClipKind.message => FontAwesomeIcons.envelopeOpenText,
        EmployeeClipKind.other => FontAwesomeIcons.fileLines,
      };

  Color _colorFor(EmployeeClipKind kind) => switch (kind) {
        EmployeeClipKind.timesheetCard => AppColors.info,
        EmployeeClipKind.paySlip => AppColors.success,
        EmployeeClipKind.message => AppColors.goldDeep,
        EmployeeClipKind.other => AppColors.slate,
      };

  void _openClip(EmployeeClip clip) {
    final attachment = RequestAttachment.demoStudy(
      fileName: clip.fileName,
      sizeBytes: 420000,
    );
    AttachmentViewer.show(
      context,
      attachment: attachment,
      subtitle: clip.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final clips = StaticEmployeeClips.clips;
    final visible = clips.take(_visible).toList();
    final hasMore = _visible < clips.length;
    final dateFmt = DateFormat('yyyy/MM/dd', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('قصاصاتك')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF3A3530), Color(0xFF5A4A36)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaIcon(
                  FontAwesomeIcons.folderOpen,
                  color: Color(0xFFE2C79A),
                  size: 20,
                ),
                SizedBox(height: 10),
                Text(
                  'مستنداتك الرسمية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'بطاقات زمنية، قسائم مالية، ورسائل موجّهة إليك — اضغط للمعاينة.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'عرض ${visible.length} من ${clips.length}',
            style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          for (final clip in visible) ...[
            AppSurface(
              onTap: () => _openClip(clip),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _colorFor(clip.kind).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: FaIcon(
                      _iconFor(clip.kind),
                      size: 17,
                      color: _colorFor(clip.kind),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clip.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dateFmt.format(clip.date),
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _openClip(clip),
                    child: const Text('عرض'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (hasMore)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _visible = (_visible + _pageSize).clamp(0, clips.length);
              }),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('عرض المزيد (${clips.length - visible.length})'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.goldDeep,
                side: const BorderSide(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}
