import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

class ReceiptDialog extends StatelessWidget {
  final SalesTransactionModel transaction;

  const ReceiptDialog({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat("dd/MM/yyyy 'às' HH:mm");

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFD1FAE5),
            child: Icon(Icons.check_circle, color: AppTheme.circularGreen, size: 36),
          ),
          SizedBox(height: 10),
          Text(
            'Baixa & Pagamento Confirmados!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Comprovante de Retirada Presencial (Sede IHL Mogi)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('Comprovante ID:', transaction.id),
              const Divider(height: 16),
              _buildRow('Item Retirado:', transaction.productTitle, isBold: true),
              _buildRow('Categoria:', transaction.category.name.toUpperCase()),
              _buildRow('Comprador:', transaction.buyerName),
              _buildRow('Forma de Pagamento:', transaction.paymentMethod),
              _buildRow('Data/Hora:', dateFormat.format(transaction.confirmedAt)),
              const Divider(height: 16),
              _buildRow(
                'Valor Pago no Balcão:',
                currencyFormat.format(transaction.amount),
                isBold: true,
                valueColor: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.recycling, color: AppTheme.circularGreen, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Obrigado por apoiar a economia circular e as oficinas do Instituto Horizonte Livre!',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            minimumSize: const Size(double.infinity, 44),
          ),
          child: const Text('Concluir Atendimento'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
