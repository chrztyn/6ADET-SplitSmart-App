import 'package:flutter/material.dart';

/// A single shimmer box that sweeps from left to right.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFDDE8F5),
              Color(0xFFF0F6FF),
              Color(0xFFDDE8F5),
            ],
          ),
        ),
      ),
    );
  }
}

/// A shimmer row with a leading circle and two text lines — used for list items.
class SkeletonListItem extends StatelessWidget {
  final double circleSize;
  final EdgeInsetsGeometry padding;
  final bool showTrailing;

  const SkeletonListItem({
    super.key,
    this.circleSize = 40,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.showTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          SkeletonBox(
            width: circleSize,
            height: circleSize,
            borderRadius: circleSize / 2,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 12, borderRadius: 6),
                const SizedBox(height: 6),
                SkeletonBox(width: 140, height: 10, borderRadius: 5),
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 12),
            SkeletonBox(width: 60, height: 12, borderRadius: 6),
          ],
        ],
      ),
    );
  }
}

/// A shimmer card — used for group / debt cards.
class SkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry margin;

  const SkeletonCard({
    super.key,
    this.height = 80,
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SkeletonBox(width: 44, height: 44, borderRadius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(height: 13, borderRadius: 6),
                const SizedBox(height: 8),
                SkeletonBox(width: 100, height: 10, borderRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SkeletonBox(width: 56, height: 13, borderRadius: 6),
        ],
      ),
    );
  }
}
