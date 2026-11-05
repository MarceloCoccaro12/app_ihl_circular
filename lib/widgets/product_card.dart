import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../screens/common/product_detail_screen.dart';
import 'pcd_author_badge.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double? width;
  final bool isHorizontalCarousel;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.isHorizontalCarousel = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      width: width ?? (isHorizontalCarousel ? 220 : null),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: product.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagem com Badge de Categoria e Teto R$ 50
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: isHorizontalCarousel ? 1.55 : 1.35,
                    child: Container(
                      color: const Color(0xFFF1F5F9),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFE2E8F0),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              product.category == ProductCategory.artesanato
                                  ? Icons.palette
                                  : (product.category == ProductCategory.brecho
                                      ? Icons.checkroom
                                      : Icons.recycling),
                              color: AppTheme.textMuted,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Categoria Pill
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.category.iconEmoji,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.category.shortLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selo Especial de Teto R$ 50 para Artesanato PcD
                  if (product.category == ProductCategory.artesanato)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.circularGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TETO R\$ 50',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Detalhes do Produto
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carrossel 1: Tag em destaque "Por: [Nome do Assistido]"
                    if (product.category == ProductCategory.artesanato &&
                        product.authorPcd != null) ...[
                      PcdAuthorBadge(
                        authorName: product.authorPcd!,
                        isDetailCard: false,
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Carrossel 2 / 3: Tamanho ou Estado de conservação
                    if (product.conditionOrSize != null &&
                        product.category != ProductCategory.artesanato) ...[
                      Text(
                        product.conditionOrSize!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Título
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Preço (R$)
                    Text(
                      currencyFormat.format(product.price),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
