import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated Medicine Capsule Pull-to-Refresh Indicator
/// مؤشر سحب للتحديث مخصص بتصميم كبسولة دواء متحركة ثلاثية الأبعاد ونابضة بالحياة
class PillRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshingText;

  const PillRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshingText,
  });

  @override
  State<PillRefreshIndicator> createState() => _PillRefreshIndicatorState();
}

class _PillRefreshIndicatorState extends State<PillRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _hasTriggeredHaptic = false;

  static const double _refreshTriggerThreshold = 75.0;
  static const double _maxDragOffset = 110.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _dragOffset = _refreshTriggerThreshold;
    });
    _animController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _animController.stop();
        _animController.reset();
        setState(() {
          _isRefreshing = false;
          _dragOffset = 0.0;
          _hasTriggeredHaptic = false;
        });
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.extentBefore == 0 &&
          notification.scrollDelta != null) {
        if (notification.scrollDelta! < 0) {
          // Dragging down at the top
          setState(() {
            _dragOffset = (_dragOffset - notification.scrollDelta! * 0.5).clamp(
              0.0,
              _maxDragOffset,
            );
          });
          if (_dragOffset >= _refreshTriggerThreshold && !_hasTriggeredHaptic) {
            HapticFeedback.mediumImpact();
            _hasTriggeredHaptic = true;
          }
        } else if (_dragOffset > 0 && notification.scrollDelta! > 0) {
          setState(() {
            _dragOffset = (_dragOffset - notification.scrollDelta!).clamp(
              0.0,
              _maxDragOffset,
            );
          });
        }
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        setState(() {
          _dragOffset = (_dragOffset - notification.overscroll * 0.5).clamp(
            0.0,
            _maxDragOffset,
          );
        });
        if (_dragOffset >= _refreshTriggerThreshold && !_hasTriggeredHaptic) {
          HapticFeedback.mediumImpact();
          _hasTriggeredHaptic = true;
        }
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragOffset >= _refreshTriggerThreshold) {
        _startRefresh();
      } else if (_dragOffset > 0) {
        setState(() {
          _dragOffset = 0.0;
          _hasTriggeredHaptic = false;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_dragOffset / _refreshTriggerThreshold).clamp(0.0, 1.0);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(0, _dragOffset),
            child: widget.child,
          ),
          if (_dragOffset > 4.0 || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _dragOffset.clamp(0.0, _maxDragOffset),
              child: ClipRect(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: (0.75 + (progress * 0.25)).clamp(0.75, 1.0),
                      child: _buildPillWidget(theme),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPillWidget(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final progress = (_dragOffset / _refreshTriggerThreshold).clamp(0.0, 1.0);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(40, 40),
                painter: _TiltedHollowPillBorderSpinnerPainter(
                  progress: _isRefreshing ? _animController.value : progress,
                  isRefreshing: _isRefreshing,
                  primaryColor: primaryColor,
                  trackColor: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : primaryColor.withValues(alpha: 0.22),
                  isDark: isDark,
                ),
              );
            },
          ),
          if (_isRefreshing) ...[
            const SizedBox(height: 4),
            Text(
              widget.refreshingText ?? 'جاري التحديث والتزامن...',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFF5EEAD4)
                    : const Color(0xFF0F766E),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// CustomPainter that renders a compact, diagonally tilted (-45°) 3D hollow capsule
/// with depth shadows, cylindrical specular highlights, and an animated 3D glowing beam
class _TiltedHollowPillBorderSpinnerPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final bool isRefreshing;
  final Color primaryColor;
  final Color trackColor;
  final bool isDark;

  _TiltedHollowPillBorderSpinnerPainter({
    required this.progress,
    required this.isRefreshing,
    required this.primaryColor,
    required this.trackColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Center and rotate diagonally (-45 degrees) like the app's pill icon
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 4);

    // Pill geometry: compact 34 width x 16 height (radius = 8)
    const pillWidth = 34.0;
    const pillHeight = 16.0;
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: pillWidth,
      height: pillHeight,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(pillHeight / 2),
    );

    // 1. 3D Elevation Drop Shadow (floating effect)
    final shadowRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(1.5, 3.0),
        width: pillWidth,
        height: pillHeight,
      ),
      const Radius.circular(pillHeight / 2),
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(shadowRRect, shadowPaint);

    // 2. 3D Crisp White Pill Body with Cylindrical Volume Shading
    final whiteBodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFFFFF), // Pure bright white top highlight
          const Color.fromARGB(255, 20, 114, 208), // Crisp white body
          const Color.fromARGB(
            255,
            240,
            236,
            226,
          ), // Subtle bottom curvature shade for 3D depth
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, whiteBodyPaint);

    // 3. 3D Static Outer Track Border
    final baseTrackPaint = Paint()
      ..color = isDark
          ? const Color(0xFFCBD5E1).withValues(alpha: 0.5)
          : const Color(0xFF94A3B8).withValues(alpha: 0.45)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, baseTrackPaint);

    // Top Specular Highlight on upper white rim
    final topSpecularPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
      ).createShader(rect);
    canvas.drawRRect(rrect, topSpecularPaint);

    // 4. 3D Middle Band Separator Groove (Crisp Medical Pill Division)
    final dividerShadowPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.6)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(0.5, -pillHeight / 2 + 2.5),
      const Offset(0.5, pillHeight / 2 - 2.5),
      dividerShadowPaint,
    );

    final dividerLightPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(-0.6, -pillHeight / 2 + 2.5),
      const Offset(-0.6, pillHeight / 2 - 2.5),
      dividerLightPaint,
    );

    // 5. 3D Glowing Animated Perimeter Beam
    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final totalLength = metric.length;

      if (isRefreshing) {
        final arcLength = totalLength * 0.42; // 42% perimeter arc
        final start = (progress * totalLength) % totalLength;
        final end = start + arcLength;

        // Extract beam path segments (with loop wrap handling)
        Path beamPath = Path();
        if (end <= totalLength) {
          beamPath = metric.extractPath(start, end);
        } else {
          beamPath.addPath(metric.extractPath(start, totalLength), Offset.zero);
          beamPath.addPath(
            metric.extractPath(0, end - totalLength),
            Offset.zero,
          );
        }

        // Layer A: 3D Soft Outer Bloom Glow
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
          ..color = const Color(0xFF14B8A6)
              .withValues(alpha: isDark ? 0.70 : 0.50);
        canvas.drawPath(beamPath, glowPaint);

        // Layer B: 3D Sharp Core Neon Beam
        final corePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            colors: [
              Color(0xFF0D9488), // Deep Emerald Tail
              Color(0xFF14B8A6), // Teal
              Color(0xFF38BDF8), // Cyan
              Colors.white, // Luminous Highlight Head
            ],
          ).createShader(rect);
        canvas.drawPath(beamPath, corePaint);

        // Layer C: 3D Specular Head Sparkle
        final headPosition = end <= totalLength ? end : end - totalLength;
        final tangent = metric.getTangentForOffset(headPosition);
        if (tangent != null) {
          final headCenter = tangent.position;
          final sparkPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
          canvas.drawCircle(headCenter, 2.0, sparkPaint);
        }
      } else {
        // Drag progress contour
        final drawLength = totalLength * progress;
        if (drawLength > 0) {
          final dragPath = metric.extractPath(0, drawLength);
          final dragCorePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round
            ..shader = const LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF38BDF8), Colors.white],
            ).createShader(rect);
          canvas.drawPath(dragPath, dragCorePaint);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _TiltedHollowPillBorderSpinnerPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRefreshing != isRefreshing ||
        oldDelegate.primaryColor != primaryColor;
  }
}
