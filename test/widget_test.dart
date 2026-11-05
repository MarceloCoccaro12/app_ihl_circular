import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ihl_circular/models/product_model.dart';
import 'package:ihl_circular/models/donation_model.dart';
import 'package:ihl_circular/models/user_model.dart';
import 'package:ihl_circular/services/ihl_repository.dart';
import 'package:ihl_circular/providers/auth_provider.dart';
import 'package:ihl_circular/providers/app_provider.dart';
import 'package:ihl_circular/screens/auth/login_register_screen.dart';
import 'package:ihl_circular/screens/common/donate_screen.dart';
import 'package:ihl_circular/screens/common/profile_screen.dart';
import 'package:ihl_circular/screens/admin/admin_dashboard_screen.dart';
import 'package:ihl_circular/screens/admin/admin_donations_screen.dart';
import 'package:ihl_circular/theme/app_theme.dart';
import 'package:ihl_circular/main.dart';

void main() {
  group('Regras de Negócio IHL Circular (Testes Unitários)', () {
    late IhlRepository repository;

    setUp(() {
      repository = IhlRepository();
    });

    test('Regra 1: Reserva com Cronômetro de 7 Dias (168h)', () {
      final available = repository.getAvailableProducts();
      expect(available.isNotEmpty, isTrue);

      final product = available.first;
      final success = repository.reserveProduct(
        productId: product.id,
        userId: 'usr_test_1',
        userName: 'Testador IHL',
      );

      expect(success, isTrue);

      final updated = repository.getAllProducts().firstWhere((p) => p.id == product.id);
      expect(updated.status, equals(ProductStatus.reserved));
      expect(updated.reservedByUserId, equals('usr_test_1'));
      expect(updated.expiresAt, isNotNull);

      final diffHours = updated.expiresAt!.difference(updated.reservedAt!).inHours;
      expect(diffHours, equals(168)); // 168 horas = 7 dias exatos
    });

    test('Regra 2: Teto de R\$ 50,00 nos Artesanatos PcD e Crédito Nominal do Autor', () {
      expect(
        () => repository.addProduct(
          title: 'Vaso Extravagante',
          description: 'Teste de teto',
          category: ProductCategory.artesanato,
          price: 50.01,
          imageUrl: 'https://sample.com/img.jpg',
          authorPcd: 'Artista Teste',
        ),
        throwsException,
      );

      expect(
        () => repository.addProduct(
          title: 'Quadro sem autor',
          description: 'Teste de autor',
          category: ProductCategory.artesanato,
          price: 45.0,
          imageUrl: 'https://sample.com/img.jpg',
          authorPcd: null,
        ),
        throwsException,
      );

      final validProduct = repository.addProduct(
        title: 'Bolsa Ecológica PcD',
        description: 'Confeccionada nas oficinas do IHL',
        category: ProductCategory.artesanato,
        price: 50.0,
        imageUrl: 'https://sample.com/img.jpg',
        authorPcd: 'Mariana P. (Oficina de Costura Adaptada)',
      );

      expect(validProduct.price, equals(50.0));
      expect(validProduct.authorPcd, equals('Mariana P. (Oficina de Costura Adaptada)'));
      expect(validProduct.isAvailable, isTrue);
    });

    test('Regra 3: Pagamento e Baixa Presenciais geram horas de terapia e venda', () {
      final available = repository.getAvailableProducts();
      final product = available.first;

      repository.reserveProduct(
        productId: product.id,
        userId: 'usr_comprador',
        userName: 'Comprador Teste',
      );

      final tx = repository.confirmPaymentAndFulfill(
        productId: product.id,
        paymentMethod: 'PIX IHL',
        adminId: 'admin_carlos',
      );

      expect(tx.amount, equals(product.price));
      expect(tx.paymentMethod, equals('PIX IHL'));
      expect(tx.therapyHoursGenerated, equals(product.price / 50.0));

      final updated = repository.getAllProducts().firstWhere((p) => p.id == product.id);
      expect(updated.isSold, isTrue);
      expect(repository.getAvailableProducts().any((p) => p.id == product.id), isFalse);
    });

    test('Regra 4: Governança LGPD e Exclusão Imediata de Conta com Devolução à Vitrine', () {
      final user = repository.registerUser(
        name: 'Usuário Temporário',
        email: 'temp.user@email.com',
        phone: '(11) 99999-8888',
        role: UserRole.comum,
        termsAccepted: true,
      );

      final available = repository.getAvailableProducts();
      final product = available.first;

      repository.reserveProduct(
        productId: product.id,
        userId: user.id,
        userName: user.name,
      );

      expect(repository.getReservedProductsByUser(user.id).length, equals(1));

      repository.deleteUserAccount(user.id);

      expect(repository.findUserById(user.id), isNull);

      final returned = repository.getAllProducts().firstWhere((p) => p.id == product.id);
      expect(returned.isAvailable, isTrue);
    });
  });

  group('Interface e Widget Tests (Conformidade de Acesso e Telas)', () {
    testWidgets('Tela 0: Login & Cadastro renderiza formulário, papéis e LGPD', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const MaterialApp(
            home: LoginRegisterScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('IHL CIRCULAR'), findsOneWidget);
      expect(find.text('Instituto Horizonte Livre • Mogi das Cruzes'), findsOneWidget);
      expect(find.textContaining('Usuário Comum'), findsWidgets);
      expect(find.textContaining('Administrador'), findsWidgets);
      expect(find.text('ENTRAR'), findsOneWidget);
      expect(find.textContaining('Avaliação de Banca'), findsNothing);
    });

    testWidgets('Tela 1.2: DonateScreen inicializa sem erros de Dropdown / tela vermelha', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const MaterialApp(
            home: DonateScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ciclo Solidário de Doações'), findsOneWidget);
      expect(find.text('Agendar Entrega de Doação'), findsOneWidget);
      expect(find.text('📅 AGENDAR ENTREGA PRESENCIAL'), findsOneWidget);
    });

    testWidgets('Segurança: AdminDashboardScreen bloqueia usuário comum com Acesso Não Autorizado', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      authProvider.switchDemoUser(UserRole.comum);
      expect(authProvider.isAdmin, isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Acesso Não Autorizado'), findsOneWidget);
      expect(find.text('Painel Administrativo IHL'), findsNothing);
    });

    testWidgets('AdminDashboardScreen: Botão de Sair desconecta e vai para LoginRegisterScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      authProvider.switchDemoUser(UserRole.admin);
      expect(authProvider.isAdmin, isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Painel Administrativo IHL'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(authProvider.isAuthenticated, isFalse);
      expect(find.byType(LoginRegisterScreen), findsOneWidget);
    });

    testWidgets('Inicialização: App inicia sempre na Tela de Login', (WidgetTester tester) async {
      await tester.pumpWidget(const IhlCircularApp());
      await tester.pump();

      expect(find.byType(LoginRegisterScreen), findsOneWidget);
    });

    testWidgets('Responsividade: DonateScreen renderiza em tela estreita (360px) sem overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      authProvider.switchDemoUser(UserRole.comum);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DonateScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ciclo Solidário de Doações'), findsOneWidget);
      expect(find.text('Agendar Entrega de Doação'), findsOneWidget);
      expect(find.text('📅 AGENDAR ENTREGA PRESENCIAL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsividade: ProfileScreen renderiza em tela estreita (360px) sem overflow nos botões', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      authProvider.switchDemoUser(UserRole.comum);
      final appProvider = AppProvider();

      // Reservar um produto para testar a lista com botões de detalhes e cancelamento
      final products = appProvider.filteredProducts;
      if (products.isNotEmpty && authProvider.currentUser != null) {
        await appProvider.reserveItem(
          productId: products.first.id,
          user: authProvider.currentUser!,
        );
      }

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Governança & Privacidade (LGPD)'), findsOneWidget);
      expect(find.text('Excluir Minha Conta (LGPD Art. 18)'), findsOneWidget);
      expect(find.text('Sair do Aplicativo'), findsOneWidget);
      expect(tester.takeException(), isNull);

      appProvider.dispose();
    });

    testWidgets('Responsividade: AdminDonationsScreen renderiza em tela estreita (360px) sem overflow em Pendentes e Todos', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      authProvider.switchDemoUser(UserRole.admin);
      final appProvider = AppProvider();

      // Agenda uma doação pendente
      if (authProvider.currentUser != null) {
        await appProvider.scheduleDonation(
          user: authProvider.currentUser!,
          title: 'Lote de Roupas de Inverno',
          description: 'Casacos e blusas de frio em ótimo estado de conservação.',
          category: DonationCategory.brecho,
          scheduledDate: DateTime.now().add(const Duration(days: 2)),
          scheduledTimeSlot: '09:00 - 10:30',
          imageUrl: 'https://sample.com/img.jpg',
        );
      }

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminDonationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Aba 0: Pendentes
      expect(find.text('Pendentes'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Aba 2: Todos
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      appProvider.dispose();
    });
  });
}
