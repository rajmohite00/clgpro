import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final begin = Offset(0.05.w, 0.0.h);
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }
}

class AnimatedScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const AnimatedScaleButton({Key? key, required this.onTap, required this.child}) : super(key: key);

  @override
  _AnimatedScaleButtonState createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          splashFactory: InkRipple.splashFactory,
          child: widget.child,
        ),
      ),
    );
  }
}

class StaggeredListItem extends StatefulWidget {
  final Widget child;
  final int index;
  const StaggeredListItem({Key? key, required this.child, required this.index}) : super(key: key);

  @override
  _StaggeredListItemState createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.w, 0.12.h), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const InteractiveCard({Key? key, required this.child, this.onTap}) : super(key: key);

  @override
  _InteractiveCardState createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -3.0 : 0.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 20.r,
                    offset: Offset(0.w, 10.h),
                  )
                ]
              : [
                  BoxShadow(
                    color: theme.brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 10.r,
                    offset: Offset(0.w, 4.h),
                  )
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  const AnimatedGradientBackground({Key? key, required this.child}) : super(key: key);

  @override
  _AnimatedGradientBackgroundState createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;
  late Animation<Color?> _color3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _color1 = ColorTween(
      begin: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
      end: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
    ).animate(_controller);

    _color2 = ColorTween(
      begin: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
      end: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
    ).animate(_controller);

    _color3 = ColorTween(
      begin: isDark ? const Color(0xFF172554) : const Color(0xFFF0F9FF),
      end: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _color1.value ?? Colors.black,
                _color2.value ?? Colors.black,
                _color3.value ?? Colors.black,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const GlassContainer({Key? key, required this.child, this.padding = EdgeInsets.zero, this.borderColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: borderColor ?? (isDark ? accent.withOpacity(0.15) : Colors.white.withOpacity(0.8)),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
            blurRadius: 40.r,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: accent.withOpacity(isDark ? 0.08 : 0.04),
            blurRadius: 60.r,
            spreadRadius: 10.r,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Shimmer Effect ────────────────────────────────────────────────────────
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const ShimmerWidget({Key? key, required this.width, required this.height, this.borderRadius = 12}) : super(key: key);

  @override
  _ShimmerWidgetState createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: isDark
                  ? [Colors.white.withOpacity(0.04), Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)]
                  : [Colors.grey.withOpacity(0.08), Colors.grey.withOpacity(0.14), Colors.grey.withOpacity(0.08)],
            ),
          ),
        );
      },
    );
  }
}

// ─── Pulse Glow Widget ────────────────────────────────────────────────────
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double radius;

  const PulseGlow({Key? key, required this.child, required this.color, this.radius = 40}) : super(key: key);

  @override
  _PulseGlowState createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35 * _pulseAnimation.value),
                blurRadius: widget.radius.r,
                spreadRadius: (widget.radius * 0.2).r,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

// ─── Floating Orbs Background ─────────────────────────────────────────────
class FloatingOrbsBackground extends StatefulWidget {
  final Widget child;
  final List<Color> orbColors;

  const FloatingOrbsBackground({
    Key? key,
    required this.child,
    this.orbColors = const [Color(0xFF3B82F6), Color(0xFF1D4ED8), Color(0xFF60A5FA)],
  }) : super(key: key);

  @override
  _FloatingOrbsBackgroundState createState() => _FloatingOrbsBackgroundState();
}

class _OrbData {
  double x, y, size, speed, phase;
  _OrbData({required this.x, required this.y, required this.size, required this.speed, required this.phase});
}

class _FloatingOrbsBackgroundState extends State<FloatingOrbsBackground> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<_OrbData> _orbs;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _orbs = List.generate(5, (i) => _OrbData(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 100 + rng.nextDouble() * 150,
      speed: 0.3 + rng.nextDouble() * 0.4,
      phase: rng.nextDouble() * pi * 2,
    ));
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _OrbsPainter(_orbs, _controller.value, widget.orbColors),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _OrbsPainter extends CustomPainter {
  final List<_OrbData> orbs;
  final double t;
  final List<Color> colors;

  _OrbsPainter(this.orbs, this.t, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < orbs.length; i++) {
      final orb = orbs[i];
      final color = colors[i % colors.length];
      final dx = orb.x * size.width + sin(t * 2 * pi * orb.speed + orb.phase) * 40;
      final dy = orb.y * size.height + cos(t * 2 * pi * orb.speed + orb.phase) * 30;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: orb.size));

      canvas.drawCircle(Offset(dx, dy), orb.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter old) => true;
}
