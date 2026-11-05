import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ihl_circular/models/user_model.dart';
import 'package:ihl_circular/providers/app_provider.dart';
import 'package:ihl_circular/providers/auth_provider.dart';
import 'package:ihl_circular/screens/admin/admin_cashier_screen.dart';
import 'package:ihl_circular/screens/admin/admin_dashboard_screen.dart';
import 'package:ihl_circular/screens/admin/admin_statistics_screen.dart';
import 'package:ihl_circular/screens/common/vitrine_screen.dart';
import 'package:ihl_circular/theme/app_theme.dart';

void main() {
  group('3. Testes de Segurança - IHL Circular', () {
    testWidgets('3.1 Controle de Acesso Baseado em Papéis (RBAC): Usuário Comum bloqueado de telas Admin', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      authProvider.switchDemoUser(UserRole.comum); // Papel Comum
      final appProvider = AppProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appProvider),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pump();

      // Confirma que a tela exibe o bloqueio de "Acesso Não Autorizado"
      expect(find.text('Acesso Não Autorizado'), findsOneWidget);
      expect(find.text('Painel Administrativo IHL'), findsNothing);

      appProvider.dispose();
    });

    test('3.2 Proteção LGPD: Validação estrita de aceite de termos e dados mínimos', () async {
      final authProvider = AuthProvider();

      // Tentativa de registrar sem aceitar os termos
      final success = await authProvider.register(
        name: 'Invasor Teste',
        email: 'invasor@teste.com',
        phone: '(11) 90000-0000',
        role: UserRole.comum,
        termsAccepted: false,
      );
      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('LGPD'));
    });

    test('3.3 Integridade de Estoque: Tentativa de reservar produto inexistente', () async {
      final appProvider = AppProvider();
      final user = UserModel(
        id: 'usr_sec_test',
        name: 'Tester',
        email: 'sec@ihl.org.br',
        phone: '(11) 99999-9999',
        role: UserRole.comum,
        termsAccepted: true,
        termsAcceptedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await appProvider.reserveItem(productId: 'prod_inexistente_999', user: user);
      expect(appProvider.getUserActiveReservations(user.id), isEmpty);
      appProvider.dispose();
    });
  });

  group('4. Testes de Desempenho e Stress - IHL Circular', () {
    test('4.1 Latência de Busca Dinâmica em Estoque Expandido (< 50ms)', () {
      final appProvider = AppProvider();

      // Mede o tempo de resposta da busca e filtragem
      final stopwatch = Stopwatch()..start();
      appProvider.setSearchQuery('retalhos');
      final searchResults = appProvider.filteredProducts;
      stopwatch.stop();

      expect(searchResults.isNotEmpty, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Responde instantaneamente (< 50ms)
      appProvider.dispose();
    });

    test('4.2 Ciclo de Varredura de Reservas Expiradas (Performance do Ticker)', () {
      final appProvider = AppProvider();
      final stopwatch = Stopwatch()..start();
      
      // Executa varredura de manutenção
      final freed = appProvider.liberarReservasExpiradas();
      stopwatch.stop();

      expect(freed, greaterThanOrEqualTo(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(20)); // Varredura ultra-rápida em RAM
      appProvider.dispose();
    });
  });

  group('5. Testes de Compatibilidade e Viewports Responsivos', () {
    testWidgets('5.1 Compatibilidade Tela Estreita (360x640 - Smartphone Compacto Android): VitrineScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      authProvider.switchDemoUser(UserRole.comum);
      final appProvider = AppProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const VitrineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Instituto Horizonte Livre (IHL)'), findsOneWidget);
      expect(tester.takeException(), isNull); // Garante ausência de RenderFlex overflow
      appProvider.dispose();
    });

    testWidgets('5.2 Compatibilidade Tela Média (412x915 - Smartphone Moderno): AdminCashierScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      authProvider.switchDemoUser(UserRole.admin);
      final appProvider = AppProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminCashierScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Guichê de Reservas & Baixa'), findsOneWidget);
      expect(tester.takeException(), isNull);
      appProvider.dispose();
    });

    testWidgets('5.3 Compatibilidade Tablet/Web (800x1280 - Formato Amplo): AdminStatisticsScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      authProvider.switchDemoUser(UserRole.admin);
      final appProvider = AppProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminStatisticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estatísticas & Faturamento'), findsOneWidget);
      expect(tester.takeException(), isNull);
      appProvider.dispose();
    });
  });
}
