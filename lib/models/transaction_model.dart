import 'product_model.dart';

class SalesTransactionModel {
  final String id;
  final String productId;
  final String productTitle;
  final ProductCategory category;
  final double amount;
  final String paymentMethod; // "Dinheiro", "PIX IHL", "Cartão Débito"
  final String buyerUserId;
  final String buyerName;
  final String confirmedByAdminId;
  final DateTime confirmedAt;

  // Impacto Social: R$ 50,00 financiam 1 hora de terapia clínica de reabilitação PcD
  double get therapyHoursGenerated => amount / 50.0;

  const SalesTransactionModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.buyerUserId,
    required this.buyerName,
    required this.confirmedByAdminId,
    required this.confirmedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_title': productTitle,
      'category': category.name,
      'amount': amount,
      'payment_method': paymentMethod,
      'buyer_user_id': buyerUserId,
      'buyer_name': buyerName,
      'therapy_hours_generated': therapyHoursGenerated,
      'confirmed_by_admin_id': confirmedByAdminId,
      'confirmed_at': confirmedAt.toIso8601String(),
    };
  }

  factory SalesTransactionModel.fromJson(Map<String, dynamic> json) {
    return SalesTransactionModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productTitle: json['product_title'] as String,
      category: ProductCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ProductCategory.brecho,
      ),
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      buyerUserId: json['buyer_user_id'] as String,
      buyerName: json['buyer_name'] as String,
      confirmedByAdminId: json['confirmed_by_admin_id'] as String,
      confirmedAt: DateTime.parse(json['confirmed_at'] as String),
    );
  }
}
