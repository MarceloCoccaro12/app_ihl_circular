import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_timer_badge.dart';
import '../../widgets/receipt_dialog.dart';

class AdminCashierScreen extends StatefulWidget {
  const AdminCashierScreen({super.key});

  @override
  State<AdminCashierScreen> createState() => _AdminCashierScreenState();
}

class _AdminCashierScreenState extends State<AdminCashierScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleConfirmPayment(
      BuildContext context, ProductModel product) async {
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    String selectedPaymentMethod = 'PIX IHL';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.point_of_sale, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Guichê Presencial: Baixa de Pagamento',
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
                'Item: ${product.title}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'Comprador: ${product.reservedByName ?? "Comprador Presencial"}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Valor a Cobrar no Balcão: ${currencyFormat.format(product.price)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Forma de Pagamento Recebida:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedPaymentMethod,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'PIX IHL', child: Text('📱 PIX IHL')),
                  DropdownMenuItem(
                      value: 'Cartão Débito', child: Text('💳 Cartão Débito')),
                  DropdownMenuItem(
                      value: 'Dinheiro', child: Text('💵 Dinheiro Espécie')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedPaymentMethod = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite,
                        size: 16, color: AppTheme.circularGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Irá creditar +${product.therapyHours.toStringAsFixed(1)}h de terapia no perfil do comprador.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.circularGreen,
                minimumSize: const Size(0, 38),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmar Pagamento & Baixa'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final tx = await app.confirmPaymentAndFulfill(
        productId: product.id,
        paymentMethod: selectedPaymentMethod,
        adminId: auth.currentUser?.id ?? 'admin_carlos',
      );

      if (context.mounted) {
        // Exibe o recibo digital da transação
        showDialog(
          context: context,
          builder: (_) => ReceiptDialog(transaction: tx),
        );
      }
    }
  }

  void _handleCancelReservation(
      BuildContext context, ProductModel product) async {
    final app = context.read<AppProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Liberar Reserva de Balcão?'),
        content: Text(
          'O item "${product.title}" reservado por ${product.reservedByName} retornará imediatamente à vitrine digital.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Liberar Item'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await app.cancelReservation(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada. O produto voltou à vitrine.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final reservedProducts = app.allActiveReservations.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final titleMatch = p.title.toLowerCase().contains(q);
      final buyerMatch =
          p.reservedByName != null && p.reservedByName!.toLowerCase().contains(q);
      return titleMatch || buyerMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Guichê de Reservas & Baixa'),
      ),
      body: Column(
        children: [
          // BARRA DE PESQUISA POR COMPRADOR OU PRODUTO
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val.trim()),
              decoration: InputDecoration(
                hintText: 'Filtrar por nome do comprador ou item...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),

          // LISTA DE RESERVAS PARA ATENDIMENTO NO BALCÃO
          Expanded(
            child: reservedProducts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_outlined,
                              size: 48, color: AppTheme.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'Nenhuma reserva ativa aguardando no balcão',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Quando os compradores reservarem itens no app com prazo de 168h, eles aparecerão aqui para baixa presencial.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reservedProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final prod = reservedProducts[index];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(6),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    prod.imageUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 72,
                                      height: 72,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prod.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currencyFormat.format(prod.price),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.person,
                                              size: 14,
                                              color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Comprador: ${prod.reservedByName ?? "Não identificado"}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Cronômetro Regressivo (168 Horas)
                            CountdownTimerBadge(product: prod, isCompact: false),

                            const SizedBox(height: 12),

                            // AÇÕES DO GUICHÊ PRESENCIAL
                            Row(
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.darkRed,
                                    side:
                                        const BorderSide(color: AppTheme.darkRed),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    minimumSize: const Size(0, 42),
                                  ),
                                  onPressed: () =>
                                      _handleCancelReservation(context, prod),
                                  child: const Text(
                                    'Liberar',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  // BOTÃO [💵 Confirmar Pagamento Presencial e Dar Baixa]
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.circularGreen,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      minimumSize: const Size(0, 42),
                                    ),
                                    onPressed: () =>
                                        _handleConfirmPayment(context, prod),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check, size: 18),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Confirmar Pagamento e Baixa',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
