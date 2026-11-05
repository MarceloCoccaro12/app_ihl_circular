import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_timer_badge.dart';
import '../../widgets/pcd_author_badge.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  void _handleReservation(BuildContext context, ProductModel product) async {
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();

    if (!auth.isAuthenticated || auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.darkRed,
          content: Text('Faça login para reservar este item.'),
        ),
      );
      return;
    }

    try {
      await app.reserveItem(productId: product.id, user: auth.currentUser!);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.circularGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item Reservado com Sucesso!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O item "${product.title}" está guardado exclusivamente para você.',
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.alarm, color: AppTheme.warningOrange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Regra de 7 Dias: Você tem até 168 horas para pagar e retirar presencialmente na sede do IHL.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '📍 Endereço de Retirada:\nRua Cel. Santos Cardoso, 420 - Centro, Mogi das Cruzes - SP\nHorário: Seg a Sex, das 09h às 17h',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK, Entendi'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.darkRed,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    }
  }

  void _handleCancelReservation(
      BuildContext context, ProductModel product) async {
    final app = context.read<AppProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar Reserva?'),
        content: const Text(
          'O item retornará imediatamente à vitrine e poderá ser adquirido por outra pessoa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Manter Reserva'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await app.cancelReservation(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.textSecondary,
            content: Text('Reserva cancelada. O item voltou para a vitrine.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final product = app.getProductById(productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produto')),
        body: const Center(child: Text('Produto não encontrado.')),
      );
    }

    final isMyReservation =
        product.isReserved && product.reservedByUserId == auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartilhar Item Solidário',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link solidário copiado para compartilhamento!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO EXPANDIDA DO PRODUTO (Pixels ajustados responsivamente)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 380,
                ),
                child: AspectRatio(
                  aspectRatio: 1.35,
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
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
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
                                ? Icons.brush
                                : Icons.checkroom,
                            color: AppTheme.textMuted,
                            size: 60,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // SEÇÃO DE CRONÔMETRO DE RESERVA ATIVA (SE ESTIVER RESERVADO)
            if (product.isReserved)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: CountdownTimerBadge(product: product, isCompact: false),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoria & Preço
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.category.iconEmoji} ${product.category.label}',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        currencyFormat.format(product.price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Título Completo
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // IMPACTO EM TERAPIAS PCD (R$ 50 = 1 Hora de Terapia Especializada)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: AppTheme.circularGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'IMPACTO SOCIAL DESTE ITEM:',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF065F46),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Financia ~${product.therapyHours.toStringAsFixed(1)} hora(s) de terapia de reabilitação PcD',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF047857),
                                ),
                              ),
                              const Text(
                                'Fonoaudiologia, fisioterapia e terapia ocupacional em Mogi das Cruzes.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARTÃO DE CRÉDITO AO ASSISTIDO AUTOR (REGRA 2 - ARTESANATOS PCD)
                  if (product.category == ProductCategory.artesanato &&
                      product.authorPcd != null) ...[
                    PcdAuthorBadge(
                      authorName: product.authorPcd!,
                      isDetailCard: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // DESCRIÇÃO DO ITEM
                  const Text(
                    'Descrição da Peça:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BANNER EXPLICATIVO DA REGRA DE RETIRADA PRESENCIAL EM ATÉ 7 DIAS NA SEDE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.storefront,
                                color: AppTheme.warningOrange, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'REGRA DE RETIRADA & PAGAMENTO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '1. O app não realiza cobranças online. O pagamento (PIX, Débito ou Dinheiro) ocorre 100% no balcão presencial.\n'
                          '2. Ao reservar, o item fica guardado para você por até 168 horas (7 dias).\n'
                          '3. Caso não seja retirado no prazo, a reserva expira automaticamente e a peça retorna à vitrine solidária.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '📍 Sede do IHL: Rua Cel. Santos Cardoso, 420 - Centro, Mogi das Cruzes - SP.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // BOTÃO DESTACADO: [ 🛒 RESERVAR ESTE ITEM PARA RETIRADA ]
                  if (product.isAvailable)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('🛒 RESERVAR ESTE ITEM PARA RETIRADA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        minimumSize: const Size(double.infinity, 52),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      onPressed: () => _handleReservation(context, product),
                    )
                  else if (isMyReservation) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accentBlue),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.accentBlue),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Este item já está reservado por você! Dirija-se à sede do IHL para efetuar o pagamento e retirada.',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, color: AppTheme.darkRed),
                      label: const Text('Cancelar Minha Reserva',
                          style: TextStyle(color: AppTheme.darkRed)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.darkRed),
                      ),
                      onPressed: () =>
                          _handleCancelReservation(context, product),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          product.isSold
                              ? 'Item Vendido no Balcão'
                              : 'Item Reservado por Outro Comprador',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
