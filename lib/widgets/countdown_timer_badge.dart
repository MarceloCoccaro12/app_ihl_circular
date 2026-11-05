import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

class CountdownTimerBadge extends StatelessWidget {
  final ProductModel product;
  final bool isCompact;

  const CountdownTimerBadge({
    super.key,
    required this.product,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!product.isReserved || product.expiresAt == null) {
      return const SizedBox.shrink();
    }

    final remaining = product.timeRemaining;
    final isWarning = remaining.inHours < 24 && remaining.inSeconds > 0;
    final isExpired = remaining.inSeconds <= 0;

    final Color bgColor = isExpired
        ? AppTheme.lightRed
        : (isWarning ? AppTheme.lightOrange : const Color(0xFFEFF6FF));

    final Color textColor = isExpired
        ? AppTheme.darkRed
        : (isWarning ? AppTheme.warningOrange : AppTheme.accentBlue);

    final String text = product.formattedCountdown;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: textColor.withAlpha(80), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withAlpha(100), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.alarm, color: textColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? 'Prazo de Retirada Expirado'
                      : 'Tempo Restante para Retirada Presencial:',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '⏱️ $text',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
