import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/donation_model.dart';
import '../models/transaction_model.dart';
import 'mock_data.dart';

class IhlRepository {
  static final IhlRepository _instance = IhlRepository._internal();
  factory IhlRepository() => _instance;
  IhlRepository._internal() {
    _initialize();
  }

  final List<UserModel> _users = [];
  final List<ProductModel> _products = [];
  final List<DonationScheduleModel> _donations = [];
  final List<SalesTransactionModel> _transactions = [];

  void _initialize() {
    _users.addAll(MockData.getInitialUsers());
    _products.addAll(MockData.getInitialProducts());
    _donations.addAll(MockData.getInitialDonations());
    _transactions.addAll(MockData.getInitialTransactions());
  }

  // --- USUÁRIOS & LGPD ---

  List<UserModel> getUsers() => List.unmodifiable(_users);

  UserModel? findUserByEmail(String email) {
    try {
      return _users.firstWhere(
        (u) => u.email.trim().toLowerCase() == email.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  UserModel? findUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  UserModel registerUser({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required bool termsAccepted,
  }) {
    if (!termsAccepted) {
      throw Exception(
        'É obrigatório aceitar os Termos de Privacidade e Proteção de Dados (LGPD).',
      );
    }

    final existing = findUserByEmail(email);
    if (existing != null) {
      throw Exception('Já existe uma conta cadastrada com este e-mail.');
    }

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: role,
      termsAccepted: true,
      termsAcceptedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    _users.add(newUser);
    return newUser;
  }

  /// Exclusão Imediata e Definitiva de Conta (LGPD Art. 18)
  /// Remove os dados do usuário e devolve quaisquer itens reservados à vitrine pública
  bool deleteUserAccount(String userId) {
    // 1. Libera todos os itens que estavam reservados por este usuário
    for (int i = 0; i < _products.length; i++) {
      if (_products[i].reservedByUserId == userId && _products[i].isReserved) {
        _products[i] = _products[i].copyWith(
          clearReservation: true,
        );
      }
    }

    // 2. Remove agendamentos pendentes do usuário
    _donations.removeWhere(
      (d) => d.donorUserId == userId && d.status == DonationStatus.scheduled,
    );

    // 3. Remove o registro cadastral do usuário de forma definitiva
    _users.removeWhere((u) => u.id == userId);
    return true;
  }

  // --- PRODUTOS & VITRINE ---

  List<ProductModel> getAllProducts() => List.unmodifiable(_products);

  /// Vitrine Digital: Oculta automaticamente itens Reservados ou Vendidos (WHERE status = 'Disponível')
  List<ProductModel> getAvailableProducts() {
    return _products.where((p) => p.isAvailable).toList();
  }

  List<ProductModel> getProductsByCategory(ProductCategory category) {
    return _products
        .where((p) => p.isAvailable && p.category == category)
        .toList();
  }

  List<ProductModel> getReservedProductsByUser(String userId) {
    return _products
        .where((p) => p.isReserved && p.reservedByUserId == userId)
        .toList();
  }

  List<ProductModel> getAllReservedProducts() {
    return _products.where((p) => p.isReserved).toList();
  }

  /// Regra 1: Reserva com Cronômetro de 7 Dias (168 Horas)
  bool reserveProduct({
    required String productId,
    required String userId,
    required String userName,
  }) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return false;

    final product = _products[index];
    if (!product.isAvailable) {
      throw Exception('Este item já não está mais disponível para reserva.');
    }

    final now = DateTime.now();
    // 168 horas = 7 dias corridos
    final expiresAt = now.add(const Duration(hours: 168));

    _products[index] = product.copyWith(
      status: ProductStatus.reserved,
      reservedByUserId: userId,
      reservedByName: userName,
      reservedAt: now,
      expiresAt: expiresAt,
    );

    return true;
  }

  /// Cancela uma reserva manualmente
  bool cancelReservation(String productId) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return false;

    final product = _products[index];
    _products[index] = product.copyWith(
      clearReservation: true,
    );
    return true;
  }

  /// Liberação Automática de Reservas Expiradas (> 168h)
  int releaseExpiredReservations() {
    final now = DateTime.now();
    int freedCount = 0;

    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];
      if (p.isReserved && p.expiresAt != null && now.isAfter(p.expiresAt!)) {
        _products[i] = p.copyWith(
          clearReservation: true,
        );
        freedCount++;
      }
    }
    return freedCount;
  }

  /// Regra 2: Cadastro com trava de R$ 50 nos Artesanatos PcD e autor obrigatório
  ProductModel addProduct({
    required String title,
    required String description,
    required ProductCategory category,
    required double price,
    required String imageUrl,
    String? authorPcd,
    String? conditionOrSize,
  }) {
    if (category == ProductCategory.artesanato) {
      if (price > 50.0) {
        throw Exception(
          'Regra de Negócio: Peças da categoria "Artesanato" têm limite máximo de preço de R\$ 50,00.',
        );
      }
      if (authorPcd == null || authorPcd.trim().isEmpty) {
        throw Exception(
          'O crédito nominal do assistido autor é obrigatório para peças de artesanato.',
        );
      }
    }

    final newProduct = ProductModel(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      category: category,
      price: price,
      imageUrl: imageUrl.trim().isEmpty
          ? 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=700&q=80'
          : imageUrl.trim(),
      authorPcd: category == ProductCategory.artesanato ? authorPcd?.trim() : null,
      conditionOrSize: conditionOrSize?.trim(),
      status: ProductStatus.available,
    );

    _products.insert(0, newProduct);
    return newProduct;
  }

  // --- BAIXA DE PAGAMENTO PRESENCIAL & GUICHÊ ---

  /// Regra 3: Pagamento e Retirada 100% Presenciais na Sede em Mogi das Cruzes
  SalesTransactionModel confirmPaymentAndFulfill({
    required String productId,
    required String paymentMethod,
    required String adminId,
  }) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) {
      throw Exception('Produto não encontrado.');
    }

    final product = _products[index];
    final buyerId = product.reservedByUserId ?? 'usr_balcao_avulso';
    final buyerName = product.reservedByName ?? 'Comprador Presencial';
    final now = DateTime.now();

    // 1. Muda status no banco para 'sold' (Vendido)
    _products[index] = product.copyWith(
      status: ProductStatus.sold,
      soldAt: now,
      buyerUserId: buyerId,
    );

    // 2. Registra transação simplificada (Regra 4)
    final tx = SalesTransactionModel(
      id: 'tx_${now.millisecondsSinceEpoch}',
      productId: product.id,
      productTitle: product.title,
      category: product.category,
      amount: product.price,
      paymentMethod: paymentMethod,
      buyerUserId: buyerId,
      buyerName: buyerName,
      confirmedByAdminId: adminId,
      confirmedAt: now,
    );

    _transactions.insert(0, tx);
    return tx;
  }

  // --- AGENDAMENTO DE DOAÇÕES ---

  List<DonationScheduleModel> getAllDonations() =>
      List.unmodifiable(_donations);

  List<DonationScheduleModel> getDonationsByUser(String userId) {
    return _donations.where((d) => d.donorUserId == userId).toList();
  }

  DonationScheduleModel scheduleDonation({
    required String donorUserId,
    required String donorName,
    required String donorPhone,
    required String donorEmail,
    required String title,
    required String description,
    required DonationCategory category,
    required DateTime scheduledDate,
    required String scheduledTimeSlot,
    String? imageUrl,
  }) {
    final newDonation = DonationScheduleModel(
      id: 'don_${DateTime.now().millisecondsSinceEpoch}',
      donorUserId: donorUserId,
      donorName: donorName,
      donorPhone: donorPhone,
      donorEmail: donorEmail,
      title: title.trim(),
      description: description.trim(),
      category: category,
      scheduledDate: scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot,
      imageUrl: imageUrl,
      status: DonationStatus.scheduled,
      createdAt: DateTime.now(),
    );

    _donations.insert(0, newDonation);
    return newDonation;
  }

  bool markDonationReceived({
    required String donationId,
    required String adminId,
  }) {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index == -1) return false;

    _donations[index] = _donations[index].copyWith(
      status: DonationStatus.received,
      receivedAt: DateTime.now(),
      receivedByAdminId: adminId,
    );
    return true;
  }

  // --- MÉTRICAS SIMPLIFICADAS (REGRA 4 - SEM DESTINAÇÃO ESPECÍFICA) ---

  List<SalesTransactionModel> getAllTransactions() =>
      List.unmodifiable(_transactions);

  /// Valor Total Arrecadado Acumulado (R$)
  double getTotalRevenue() {
    return _transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Total Geral de Horas de Terapias PcD Financiadas (R$ 50 = 1 hora)
  double getTotalTherapyHours() {
    return getTotalRevenue() / 50.0;
  }

  /// Total Geral de Peças Recirculadas/Vendidas pelo App (unidades)
  int getTotalRecirculatedItems() {
    return _transactions.length;
  }

  int getItemsSoldCountByCategory(ProductCategory category) {
    return _transactions.where((tx) => tx.category == category).length;
  }

  /// Métrica 1 do Usuário: Valor Total em Compras Realizadas (R$)
  double getUserTotalInvestment(String userId) {
    return _transactions
        .where((tx) => tx.buyerUserId == userId)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Horas de terapia PcD financiadas pelo usuário (R$ 50 = 1 hora)
  double getUserTherapyHours(String userId) {
    return getUserTotalInvestment(userId) / 50.0;
  }

  /// Métrica 2 do Usuário: Quantidade Total de Peças Recirculadas/Adquiridas (unidades)
  int getUserTotalItemsCount(String userId) {
    return _transactions.where((tx) => tx.buyerUserId == userId).length;
  }
}
