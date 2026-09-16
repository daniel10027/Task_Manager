import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Live, animated online/offline status pill shown in the app bar.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.isOnline, required this.pendingCount});

  final bool isOnline;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final fg = isOnline ? AppColors.online : AppColors.offline;
    final bg = isOnline ? AppColors.onlineBg : AppColors.offlineBg;
    final label = isOnline
        ? 'En ligne'
        : pendingCount > 0
            ? 'Hors ligne — synchronisation en attente ($pendingCount)'
            : 'Hors ligne — synchronisation en attente';

    return AnimatedContainer(
      key: ValueKey('status_pill_${isOnline}_$pendingCount'),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: fg, animate: isOnline),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(isOnline)).fadeIn(duration: 250.ms);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.animate});

  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (!animate) return dot;
    return dot
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.7, end: 1.2, duration: 900.ms, curve: Curves.easeInOut);
  }
}
