import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PcdAuthorBadge extends StatelessWidget {
  final String authorName;
  final bool isDetailCard;

  const PcdAuthorBadge({
    super.key,
    required this.authorName,
    this.isDetailCard = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDetailCard) {
      // Tag em destaque para os cards da vitrine: "Por: [Nome do Assistido]"
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.palette_outlined, size: 12, color: AppTheme.accentBlue),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Por: $authorName',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Cartão do Autor na Tela de Detalhes 1.1.A conforme especificação:
    // "✨ Criado com carinho por: [Nome do Assistido] — Produto confeccionado nas oficinas de desenvolvimento do IHL."
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.circularGreen.withAlpha(40),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.circularGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.circularGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ARTESANATO INCLUSIVO PCD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '✨ Criado com carinho por: $authorName — Produto confeccionado nas oficinas de desenvolvimento do IHL.',
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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
