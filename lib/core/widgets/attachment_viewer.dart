import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../../data/models/request_attachment.dart';
import 'pdf_frame.dart';

/// شريحة مرفق قابلة للضغط — تظهر في بطاقة الطلب.
class AttachmentChip extends StatelessWidget {
  const AttachmentChip({
    super.key,
    required this.attachment,
    this.dense = false,
    this.viewerSubtitle,
  });

  final RequestAttachment attachment;
  final bool dense;
  final String? viewerSubtitle;

  @override
  Widget build(BuildContext context) {
    final style = _AttachmentStyle.of(attachment.kind);

    return Material(
      color: style.soft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => AttachmentViewer.show(
          context,
          attachment: attachment,
          subtitle: viewerSubtitle,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 12,
            vertical: dense ? 8 : 10,
          ),
          child: Row(
            children: [
              Container(
                width: dense ? 34 : 40,
                height: dense ? 34 : 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [style.strong, style.mid],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: style.strong.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: FaIcon(style.icon, size: dense ? 14 : 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: dense ? 12.5 : 13.5,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${attachment.extensionLabel} · ${attachment.sizeLabel} · اضغط للمعاينة',
                      style: TextStyle(
                        fontSize: dense ? 11 : 11.5,
                        fontWeight: FontWeight.w600,
                        color: style.strong,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.visibility_rounded, size: 18, color: style.strong),
            ],
          ),
        ),
      ),
    );
  }
}

/// عارض مرفق بملء الشاشة تقريباً — تجربة فتح احترافية.
abstract final class AttachmentViewer {
  static Future<void> show(
    BuildContext context, {
    required RequestAttachment attachment,
    String? subtitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => _AttachmentViewerSheet(
        attachment: attachment,
        subtitle: subtitle,
      ),
    );
  }
}

class _AttachmentViewerSheet extends StatefulWidget {
  const _AttachmentViewerSheet({
    required this.attachment,
    this.subtitle,
  });

  final RequestAttachment attachment;
  final String? subtitle;

  @override
  State<_AttachmentViewerSheet> createState() => _AttachmentViewerSheetState();
}

class _AttachmentViewerSheetState extends State<_AttachmentViewerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _immersive = false;

  RequestAttachment get attachment => widget.attachment;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _AttachmentStyle.of(attachment.kind);
    final height = MediaQuery.sizeOf(context).height * (_immersive ? 0.96 : 0.88);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _Header(
                  attachment: attachment,
                  subtitle: widget.subtitle,
                  style: style,
                  immersive: _immersive,
                  onClose: () => Navigator.of(context).pop(),
                  onToggleImmersive: () =>
                      setState(() => _immersive = !_immersive),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _immersive
                        ? _ImmersivePreview(
                            key: const ValueKey('immersive'),
                            attachment: attachment,
                            style: style,
                          )
                        : _StudioPreview(
                            key: const ValueKey('studio'),
                            attachment: attachment,
                            style: style,
                          ),
                  ),
                ),
                _FooterActions(
                  style: style,
                  immersive: _immersive,
                  onOpen: () => setState(() => _immersive = true),
                  onClosePreview: () => setState(() => _immersive = false),
                  onDone: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.attachment,
    required this.style,
    required this.immersive,
    required this.onClose,
    required this.onToggleImmersive,
    this.subtitle,
  });

  final RequestAttachment attachment;
  final String? subtitle;
  final _AttachmentStyle style;
  final bool immersive;
  final VoidCallback onClose;
  final VoidCallback onToggleImmersive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            style.strong,
            style.mid,
            const Color(0xFF2A2A28),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: FaIcon(style.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: immersive ? 'تصغير' : 'ملء الشاشة',
                  onPressed: onToggleImmersive,
                  icon: Icon(
                    immersive
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaBadge(
                  icon: Icons.insert_drive_file_outlined,
                  label: attachment.extensionLabel,
                ),
                _MetaBadge(
                  icon: Icons.data_usage_rounded,
                  label: attachment.sizeLabel,
                ),
                if (attachment.uploadedAt != null)
                  _MetaBadge(
                    icon: Icons.schedule_rounded,
                    label: DateFormat('yyyy/MM/dd HH:mm', 'ar')
                        .format(attachment.uploadedAt!),
                  ),
                _MetaBadge(
                  icon: Icons.verified_outlined,
                  label: 'مرفق رسمي',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioPreview extends StatelessWidget {
  const _StudioPreview({
    super.key,
    required this.attachment,
    required this.style,
  });

  final RequestAttachment attachment;
  final _AttachmentStyle style;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      children: [
        Text(
          'معاينة المستند',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'افتح المستند للتحقق قبل الاعتماد — تجربة عرض واضحة ورسمية.',
          style: TextStyle(color: AppColors.slate, height: 1.45),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 0.78,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFE8E6E1),
                  AppColors.surface,
                ],
              ),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: style.strong.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PaperGrainPainter(color: style.soft),
                  ),
                ),
                if (attachment.kind == AttachmentKind.pdf &&
                    attachment.hasPreviewBytes)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: buildPdfFrame(
                          bytes: attachment.bytes!,
                          viewType:
                              'pdf-studio-${attachment.fileName}-${attachment.bytes!.length}',
                        ),
                      ),
                    ),
                  )
                else if (attachment.kind == AttachmentKind.pdf)
                  const _PdfPagesMock()
                else if (attachment.kind == AttachmentKind.image)
                  _ImageMock(attachment: attachment, style: style)
                else
                  _GenericDocMock(style: style, attachment: attachment),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: style.strong,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      attachment.extensionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.goldDeep),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'بعد ربط الخادم يُجلب الملف من التخزين (مرفق/URL) أو يُفك Base64 عند الحاجة للمعاينة.',
                  style: TextStyle(
                    color: AppColors.goldDeep,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImmersivePreview extends StatelessWidget {
  const _ImmersivePreview({
    super.key,
    required this.attachment,
    required this.style,
  });

  final RequestAttachment attachment;
  final _AttachmentStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1A),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: attachment.kind == AttachmentKind.image &&
                    attachment.bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      attachment.bytes!,
                      fit: BoxFit.contain,
                    ),
                  )
                : attachment.kind == AttachmentKind.pdf &&
                        attachment.hasPreviewBytes
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: buildPdfFrame(
                          bytes: attachment.bytes!,
                          viewType:
                              'pdf-immersive-${attachment.fileName}-${attachment.bytes!.length}',
                        ),
                      )
                    : attachment.kind == AttachmentKind.pdf
                        ? const _PdfPagesMock(dark: true)
                        : _GenericDocMock(
                            style: style,
                            attachment: attachment,
                            dark: true,
                          ),
          ),
        ),
      ),
    );
  }
}

class _PdfPagesMock extends StatelessWidget {
  const _PdfPagesMock({this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final page = dark ? const Color(0xFFF4F1EA) : Colors.white;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(-18, 10),
          child: Transform.rotate(
            angle: -0.04,
            child: _page(page, opacity: 0.55),
          ),
        ),
        Transform.translate(
          offset: const Offset(16, 6),
          child: Transform.rotate(
            angle: 0.035,
            child: _page(page, opacity: 0.75),
          ),
        ),
        _page(page, opacity: 1, showLines: true),
      ],
    );
  }

  Widget _page(Color color, {required double opacity, bool showLines = false}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 210,
        height: 280,
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: showLines
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 88,
                    height: 10,
                    color: AppColors.gold.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < 9; i++) ...[
                    Container(
                      width: i == 3 || i == 7 ? 120.0 : double.infinity,
                      height: 7,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: AppColors.line,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            Container(height: 6, color: AppColors.line),
                            const SizedBox(height: 6),
                            Container(height: 6, color: AppColors.line),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

class _ImageMock extends StatelessWidget {
  const _ImageMock({required this.attachment, required this.style});

  final RequestAttachment attachment;
  final _AttachmentStyle style;

  @override
  Widget build(BuildContext context) {
    if (attachment.bytes != null) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(attachment.bytes!, fit: BoxFit.cover),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(style.icon, size: 42, color: style.strong),
          const SizedBox(height: 12),
          Text(
            'معاينة صورة المستند',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: style.strong,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenericDocMock extends StatelessWidget {
  const _GenericDocMock({
    required this.style,
    required this.attachment,
    this.dark = false,
  });

  final _AttachmentStyle style;
  final RequestAttachment attachment;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 108,
            decoration: BoxDecoration(
              color: dark ? Colors.white10 : style.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dark
                    ? Colors.white24
                    : style.strong.withValues(alpha: 0.35),
              ),
            ),
            alignment: Alignment.center,
            child: FaIcon(
              style.icon,
              size: 34,
              color: dark ? Colors.white : style.strong,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            attachment.fileName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: dark ? Colors.white : AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.style,
    required this.immersive,
    required this.onOpen,
    required this.onClosePreview,
    required this.onDone,
  });

  final _AttachmentStyle style;
  final bool immersive;
  final VoidCallback onOpen;
  final VoidCallback onClosePreview;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: immersive ? onClosePreview : onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: style.strong,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    immersive
                        ? Icons.view_agenda_outlined
                        : Icons.open_in_full_rounded,
                  ),
                  label: Text(immersive ? 'عرض البطاقة' : 'فتح المستند'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: onDone,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.line),
                ),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperGrainPainter extends CustomPainter {
  _PaperGrainPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.15), 70, paint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.75), 90, paint);
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AttachmentStyle {
  const _AttachmentStyle({
    required this.icon,
    required this.strong,
    required this.mid,
    required this.soft,
  });

  final FaIconData icon;
  final Color strong;
  final Color mid;
  final Color soft;

  static _AttachmentStyle of(AttachmentKind kind) => switch (kind) {
        AttachmentKind.pdf => const _AttachmentStyle(
            icon: FontAwesomeIcons.filePdf,
            strong: Color(0xFF9B3B3B),
            mid: Color(0xFFC45C5C),
            soft: Color(0xFFF6E8E8),
          ),
        AttachmentKind.word => const _AttachmentStyle(
            icon: FontAwesomeIcons.fileWord,
            strong: Color(0xFF2F5F8F),
            mid: Color(0xFF4F7AA8),
            soft: Color(0xFFE8EEF5),
          ),
        AttachmentKind.image => const _AttachmentStyle(
            icon: FontAwesomeIcons.fileImage,
            strong: Color(0xFF8F7043),
            mid: Color(0xFFB08D57),
            soft: Color(0xFFF3EADA),
          ),
        AttachmentKind.other => const _AttachmentStyle(
            icon: FontAwesomeIcons.fileLines,
            strong: Color(0xFF5C738A),
            mid: Color(0xFF7A8FA3),
            soft: Color(0xFFE8EEF3),
          ),
      };
}
