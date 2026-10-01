import 'dart:math' as math;

import 'package:flutter/material.dart';

/// عرض قابل للتكبير والتصغير بإصبعين أو بالنقر المزدوج أو بأزرار أسفله.
/// يُبنى المحتوى بمعرفة حجم منطقة العرض عند 100٪؛ والأطول منها يُسحب.
class ZoomableView extends StatefulWidget {
  const ZoomableView({super.key, required this.builder, this.maxScale = 4});

  final Widget Function(BuildContext context, Size viewport) builder;
  final double maxScale;

  @override
  State<ZoomableView> createState() => _ZoomableViewState();
}

class _ZoomableViewState extends State<ZoomableView> {
  static const _step = 1.5;
  static const _doubleTapScale = 2.5;

  final _controller = TransformationController();
  final _contentKey = GlobalKey();
  Size _viewport = Size.zero;
  Offset? _doubleTapAt;

  double get _scale => _controller.value.getMaxScaleOnAxis();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoomTo(double target, [Offset? focal]) {
    final scale = target.clamp(1.0, widget.maxScale);
    final at = focal ?? _viewport.center(Offset.zero);
    final factor = scale / _scale;
    final moved = Matrix4.translationValues(at.dx, at.dy, 0)
      ..multiply(Matrix4.diagonal3Values(factor, factor, 1))
      ..multiply(Matrix4.translationValues(-at.dx, -at.dy, 0))
      ..multiply(_controller.value);

    // InteractiveViewer يقيّد السحب والقرص فقط، لا القيم المضبوطة من الأزرار.
    final content = _contentKey.currentContext?.size ?? _viewport;
    final minX = math.min(0.0, _viewport.width - content.width * scale);
    final minY = math.min(0.0, _viewport.height - content.height * scale);
    final offset = moved.getTranslation();
    _controller.value = Matrix4.translationValues(
      offset.x.clamp(minX, 0.0),
      offset.y.clamp(minY, 0.0),
      0,
    )..multiply(Matrix4.diagonal3Values(scale, scale, 1));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewport = constraints.biggest;
                return GestureDetector(
                  onDoubleTapDown: (details) =>
                      _doubleTapAt = details.localPosition,
                  onDoubleTap: () => _zoomTo(
                    _scale > 1.01 ? 1 : _doubleTapScale,
                    _doubleTapAt,
                  ),
                  child: InteractiveViewer(
                    transformationController: _controller,
                    constrained: false,
                    minScale: 1,
                    maxScale: widget.maxScale,
                    child: KeyedSubtree(
                      key: _contentKey,
                      child: widget.builder(context, _viewport),
                    ),
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<Matrix4>(
            valueListenable: _controller,
            builder: (context, matrix, _) {
              final scale = matrix.getMaxScaleOnAxis();
              return _ZoomControls(
                percent: (scale * 100).round(),
                onZoomOut: scale > 1.01 ? () => _zoomTo(scale / _step) : null,
                onZoomIn: scale < widget.maxScale - 0.01
                    ? () => _zoomTo(scale * _step)
                    : null,
                onReset: scale > 1.01 ? () => _zoomTo(1) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.percent,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onReset,
  });

  final int percent;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'تصغير',
              onPressed: onZoomOut,
              color: Colors.white,
              disabledColor: Colors.white38,
              icon: const Icon(Icons.zoom_out_rounded),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 56),
              child: Semantics(
                label: 'نسبة التكبير',
                liveRegion: true,
                child: Text(
                  '$percent٪',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'تكبير',
              onPressed: onZoomIn,
              color: Colors.white,
              disabledColor: Colors.white38,
              icon: const Icon(Icons.zoom_in_rounded),
            ),
            IconButton(
              tooltip: 'الحجم الأصلي',
              onPressed: onReset,
              color: Colors.white,
              disabledColor: Colors.white38,
              icon: const Icon(Icons.fit_screen_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
