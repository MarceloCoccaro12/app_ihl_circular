import 'package:flutter_test/flutter_test.dart';
import 'package:ihl_circular/models/product_model.dart';
import 'package:ihl_circular/models/donation_model.dart';
import 'package:ihl_circular/models/user_model.dart';
import 'package:ihl_circular/providers/app_provider.dart';
import 'package:ihl_circular/providers/auth_provider.dart';

void main() {
  group('2. Testes de Integração - IHL Circular', () {
    late AuthProvider authProvider;
    late AppProvider appProvider;

    setUp(() {
      authProvider = AuthProvider();
      appProvider = AppProvider();
    });

    tearDown(() {
      appProvider.dispose();
    });

    test('2.1 Ciclo Completo: Cadastro -> Vitrine -> Reserva (168h) -> Caixa Presencial -> Faturamento', () async {
      // 1. Cadastro de novo usuário
      final email = 'integracao_${DateTime.now().millisecondsSinceEpoch}@ihl.org.br';
      final registered = await authProvider.register(
        name: 'Ana Carolina Teste',
        email: email,
        phone: '(11) 98888-7777',
        role: UserRole.comum,
        termsAccepted: true,
      );
      expect(registered, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      final currentUser = authProvider.currentUser!;

      // 2. Localiza item disponível na Vitrine ou cadastra um para o teste
      final targetProduct = await appProvider.addProduct(
        title: 'Casaco Denim Integrado',
        description: 'Peça para teste integrado',
        category: ProductCategory.brecho,
        price: 60.0,
        imageUrl: 'https://sample.com/casaco.jpg',
      );

      // 3. Usuário reserva o item na Vitrine
      await appProvider.reserveItem(
        productId: targetProduct.id,
        user: currentUser,
      );

      // 4. Item sai da vitrine pública de disponíveis
      expect(
        appProvider.filteredProducts.any((p) => p.id == targetProduct.id),
        isFalse,
      );

      // 5. Item aparece na aba "Minhas Reservas" do Usuário com cronômetro
      final userReservations = appProvider.getUserActiveReservations(currentUser.id);
      expect(userReservations.any((p) => p.id == targetProduct.id), isTrue);
      final reservation = userReservations.firstWhere((p) => p.id == targetProduct.id);
      expect(reservation.expiresAt, isNotNull);

      // 6. Monitor do IHL visualiza a reserva na fila do Caixa Presencial
      final cashierQueue = appProvider.allActiveReservations;
      expect(cashierQueue.any((p) => p.id == targetProduct.id), isTrue);

      // 7. Cobrança e baixa presencial com meio de pagamento (PIX IHL)
      final tx = await appProvider.confirmPaymentAndFulfill(
        productId: targetProduct.id,
        paymentMethod: 'PIX IHL',
        adminId: 'admin_carlos',
      );
      expect(tx.amount, equals(targetProduct.price));
      expect(tx.therapyHoursGenerated, equals(targetProduct.price / 50.0));

      // 8. O item deixa de estar na fila do caixa e passa a constar como vendido
      expect(appProvider.allActiveReservations.any((p) => p.id == targetProduct.id), isFalse);

      // 9. Estatísticas e Faturamento atualizados refletindo o valor e horas de terapia
      expect(appProvider.totalRevenue, greaterThanOrEqualTo(targetProduct.price));
      expect(appProvider.totalTherapyHours, greaterThanOrEqualTo(targetProduct.price / 50.0));
      expect(appProvider.generateDirectorReport(), contains('RELATÓRIO INSTITUCIONAL DE GESTÃO E VENDAS'));
    });

    test('2.2 Ciclo Completo de Doação: Agendamento pelo Doador -> Gestão no Admin -> Baixa Presencial', () async {
      // 1. Usuário comum logado agenda uma entrega de doação
      authProvider.switchDemoUser(UserRole.comum);
      final donor = authProvider.currentUser!;

      final scheduleDate = DateTime.now().add(const Duration(days: 2));
      final donation = await appProvider.scheduleDonation(
        user: donor,
        title: 'Caixa com 20 Livros e Brinquedos Educativos',
        description: 'Materiais em perfeito estado para bazar/oficinas',
        category: DonationCategory.materiais,
        scheduledDate: scheduleDate,
        scheduledTimeSlot: '13:30 - 15:00',
      );

      expect(donation.status, equals(DonationStatus.scheduled));

      // 2. O usuário vê no seu histórico pessoal
      final userDonations = appProvider.getUserDonations(donor.id);
      expect(userDonations.any((d) => d.id == donation.id), isTrue);

      // 3. Monitor acessa a lista de doações pendentes
      final pendingDonations = appProvider.allDonations.where((d) => d.isScheduled).toList();
      expect(pendingDonations.any((d) => d.id == donation.id), isTrue);

      // 4. Monitor confirma o recebimento físico dos materiais na sede
      final receivedSuccess = await appProvider.markDonationReceived(
        donationId: donation.id,
        adminId: 'admin_carlos',
      );
      expect(receivedSuccess, isTrue);

      // 5. Status do agendamento é atualizado para recebido
      final updatedDonation = appProvider.allDonations.firstWhere((d) => d.id == donation.id);
      expect(updatedDonation.isReceived, isTrue);
      expect(updatedDonation.receivedAt, isNotNull);
      expect(updatedDonation.receivedByAdminId, equals('admin_carlos'));
    });

    test('2.3 Ciclo LGPD e Economia Circular: Exclusão de Conta com Devolução de Estoque', () async {
      // 1. Cria usuário e autentica
      final email = 'lgpd_flow_${DateTime.now().millisecondsSinceEpoch}@ihl.org.br';
      await authProvider.register(
        name: 'Usuário LGPD Teste',
        email: email,
        phone: '(11) 97777-6666',
        role: UserRole.comum,
        termsAccepted: true,
      );
      final user = authProvider.currentUser!;

      // 2. Adiciona e reserva um produto disponível
      final product = await appProvider.addProduct(
        title: 'Cesto Organizador Reutilizável',
        description: 'Cesto para teste de lgpd',
        category: ProductCategory.materiais,
        price: 25.0,
        imageUrl: 'https://sample.com/cesto.jpg',
      );
      await appProvider.reserveItem(productId: product.id, user: user);
      expect(appProvider.getUserActiveReservations(user.id).length, equals(1));

      // 3. Usuário exerce o Direito ao Esquecimento (LGPD Art. 18) e exclui a conta
      final deleted = await authProvider.deleteAccount();
      expect(deleted, isTrue);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);

      // 4. Verifica que o produto reservado foi automaticamente devolvido à vitrine pública
      final productAfter = appProvider.allProducts.firstWhere((p) => p.id == product.id);
      expect(productAfter.isAvailable, isTrue);
      expect(productAfter.reservedByUserId, isNull);
      expect(productAfter.reservedByName, isNull);
    });
  });
}
