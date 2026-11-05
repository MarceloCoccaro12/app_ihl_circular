import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../models/donation_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/ihl_repository.dart';

class AppProvider extends ChangeNotifier {
  final IhlRepository _repository = IhlRepository();
  Timer? _countdownTicker;

  String _searchQuery = '';
  ProductCategory? _selectedCategory;

  String get searchQuery => _searchQuery;
  ProductCategory? get selectedCategory => _selectedCategory;

  AppProvider() {
    _startCountdownTicker();
  }

  void _startCountdownTicker() {
    // Ticker a cada 1 segundo para atualizar cronômetros regressivos em tempo real
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final freed = _repository.releaseExpiredReservations();
      notifyListeners();
      if (freed > 0) {
        if (kDebugMode) {
          print('$freed reserva(s) expirada(s) retornada(s) à vitrine.');
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  // --- FILTROS E BUSCA DINÂMICA ---

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(ProductCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();
  }

  // --- GETTERS DE PRODUTOS ---

  List<ProductModel> get allProducts => _repository.getAllProducts();

  /// Carrossel 1: 🎨 FEITO POR NOSSOS ASSISTIDOS (Somente Disponíveis)
  List<ProductModel> get artisanProducts =>
      _repository.getProductsByCategory(ProductCategory.artesanato);

  /// Carrossel 2: 👕 GARIMPO SOLIDÁRIO (BRECHÓ) (Somente Disponíveis)
  List<ProductModel> get brechoProducts =>
      _repository.getProductsByCategory(ProductCategory.brecho);

  /// Carrossel 3: 🪵 OUTROS MATERIAIS CIRCULARES (Somente Disponíveis)
  List<ProductModel> get materialProducts =>
      _repository.getProductsByCategory(ProductCategory.materiais);

  /// Lista filtrada para busca em tempo real na Vitrine
  List<ProductModel> get filteredProducts {
    final available = _repository.getAvailableProducts();

    return available.where((p) {
      final matchesCategory = _selectedCategory == null ||
          p.category == _selectedCategory;

      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          p.title.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          (p.authorPcd != null && p.authorPcd!.toLowerCase().contains(query));

      return matchesCategory && matchesQuery;
    }).toList();
  }

  ProductModel? getProductById(String id) {
    try {
      return _repository.getAllProducts().firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- RESERVAS (168 HORAS / 7 DIAS) ---

  List<ProductModel> getUserActiveReservations(String userId) {
    return _repository.getReservedProductsByUser(userId);
  }

  List<ProductModel> get allActiveReservations {
    return _repository.getAllReservedProducts();
  }

  Future<void> reserveItem({
    required String productId,
    required UserModel user,
  }) async {
    _repository.reserveProduct(
      productId: productId,
      userId: user.id,
      userName: user.name,
    );
    notifyListeners();
  }

  Future<void> cancelReservation(String productId) async {
    _repository.cancelReservation(productId);
    notifyListeners();
  }

  /// Botão de Manutenção no Painel Admin: [⏰ Liberar Reservas Expiradas]
  int liberarReservasExpiradas() {
    final freed = _repository.releaseExpiredReservations();
    notifyListeners();
    return freed;
  }

  // --- CADASTRO DE PRODUTO (ADMIN) ---

  Future<ProductModel> addProduct({
    required String title,
    required String description,
    required ProductCategory category,
    required double price,
    required String imageUrl,
    String? authorPcd,
    String? conditionOrSize,
  }) async {
    final product = _repository.addProduct(
      title: title,
      description: description,
      category: category,
      price: price,
      imageUrl: imageUrl,
      authorPcd: authorPcd,
      conditionOrSize: conditionOrSize,
    );
    notifyListeners();
    return product;
  }

  // --- BAIXA DE PAGAMENTO PRESENCIAL (GUICHÊ ADMIN) ---

  Future<SalesTransactionModel> confirmPaymentAndFulfill({
    required String productId,
    required String paymentMethod,
    required String adminId,
  }) async {
    final tx = _repository.confirmPaymentAndFulfill(
      productId: productId,
      paymentMethod: paymentMethod,
      adminId: adminId,
    );
    notifyListeners();
    return tx;
  }

  // --- DOAÇÕES ---

  List<DonationScheduleModel> get allDonations =>
      _repository.getAllDonations();

  List<DonationScheduleModel> getUserDonations(String userId) =>
      _repository.getDonationsByUser(userId);

  Future<DonationScheduleModel> scheduleDonation({
    required UserModel user,
    required String title,
    required String description,
    required DonationCategory category,
    required DateTime scheduledDate,
    required String scheduledTimeSlot,
    String? imageUrl,
  }) async {
    final donation = _repository.scheduleDonation(
      donorUserId: user.id,
      donorName: user.name,
      donorPhone: user.phone,
      donorEmail: user.email,
      title: title,
      description: description,
      category: category,
      scheduledDate: scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot,
      imageUrl: imageUrl,
    );
    notifyListeners();
    return donation;
  }

  Future<bool> markDonationReceived({
    required String donationId,
    required String adminId,
  }) async {
    final success = _repository.markDonationReceived(
      donationId: donationId,
      adminId: adminId,
    );
    if (success) {
      notifyListeners();
    }
    return success;
  }

  // --- MÉTRICAS SIMPLIFICADAS (REGRA 4 - SEM DESTINAÇÃO ESPECÍFICA) ---

  /// Valor Total Arrecadado Acumulado (R$)
  double get totalRevenue => _repository.getTotalRevenue();

  /// Total Geral de Horas de Terapias PcD Financiadas
  double get totalTherapyHours => _repository.getTotalTherapyHours();

  /// Total Geral de Peças Recirculadas pelo App (unidades)
  int get totalSoldItems => _repository.getTotalRecirculatedItems();

  int get soldArtisanCount =>
      _repository.getItemsSoldCountByCategory(ProductCategory.artesanato);

  int get soldBrechoCount =>
      _repository.getItemsSoldCountByCategory(ProductCategory.brecho);

  int get soldMaterialsCount =>
      _repository.getItemsSoldCountByCategory(ProductCategory.materiais);

  /// Métrica 1 do Usuário: Valor Total em Compras Realizadas (R$)
  double getUserTotalInvestment(String userId) =>
      _repository.getUserTotalInvestment(userId);

  /// Métrica: Total de Horas de Terapias Financiadas pelo Usuário
  double getUserTherapyHours(String userId) =>
      _repository.getUserTherapyHours(userId);

  /// Métrica 2 do Usuário: Quantidade Total de Peças Recirculadas/Adquiridas (unidades)
  int getUserTotalItemsCount(String userId) =>
      _repository.getUserTotalItemsCount(userId);

  /// Gera Relatório de Prestação de Contas para a Diretoria (Conforme Tela 2.3)
  String generateDirectorReport() {
    final now = DateTime.now();
    final dateFormat = DateFormat("dd/MM/yyyy 'às' HH:mm");
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final transactions = _repository.getAllTransactions();
    final donations = _repository.getAllDonations();
    final receivedDonations =
        donations.where((d) => d.status == DonationStatus.received).length;

    final sb = StringBuffer();
    sb.writeln('====================================================');
    sb.writeln('   INSTITUTO HORIZONTE LIVRE (IHL CIRCULAR)');
    sb.writeln('   RELATÓRIO INSTITUCIONAL DE GESTÃO E VENDAS');
    sb.writeln('====================================================');
    sb.writeln('Emissão: ${dateFormat.format(now)}');
    sb.writeln('Sede: Rua Cel. Santos Cardoso, 420 - Mogi das Cruzes / SP');
    sb.writeln('');
    sb.writeln('--- 1. PAINEL DE MÉTRICAS FINANCEIRAS E OPERACIONAIS ---');
    sb.writeln(
        '• 💰 Arrecadação Total Acumulada: ${currencyFormat.format(totalRevenue)}');
    sb.writeln('• 📊 Total Geral de Peças Recirculadas: $totalSoldItems unidades');
    sb.writeln('  - 👕 Peças de Brechó Vendidas: $soldBrechoCount unidades');
    sb.writeln('  - 🎨 Artesanatos Vendidos: $soldArtisanCount unidades');
    sb.writeln('  - 🪵 Materiais Circulares Destinados: $soldMaterialsCount unidades');
    sb.writeln('• 📦 Doações Recebidas e Triadas no Balcão: $receivedDonations lotes');
    sb.writeln('');
    sb.writeln('--- 2. DETALHAMENTO DE VENDAS (GUICHÊ PRESENCIAL) ---');
    for (final tx in transactions) {
      sb.writeln(
          '• [${DateFormat('dd/MM/yyyy').format(tx.confirmedAt)}] ${tx.productTitle} | ${currencyFormat.format(tx.amount)} (${tx.paymentMethod}) | Comprador: ${tx.buyerName}');
    }
    sb.writeln('');
    sb.writeln('--- 3. CONFORMIDADE COM REGRAS OPERACIONAIS ---');
    sb.writeln(
        '• Teto de R\$ 50,00 no Artesanato: Cumprido com crédito aos assistidos autores.');
    sb.writeln(
        '• Regra de Reserva de 168h: Monitoramento ativo com expurgo de itens vencidos.');
    sb.writeln(
        '• Operação 100% Presencial: Pagamento e entrega realizados exclusivamente na sede.');
    sb.writeln(
        '• Governança LGPD: Dados enxutos e funcionalidade de exclusão imediata.');
    sb.writeln('====================================================');

    return sb.toString();
  }
}
