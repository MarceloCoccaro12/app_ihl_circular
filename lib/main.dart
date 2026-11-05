import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_register_screen.dart';
import 'screens/common/main_navigation_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IhlCircularApp());
}

/// Comportamento de rolagem customizado para suportar arrasto lateral com mouse,
/// trackpad e touch em modo desktop, web e telas reduzidas.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class IhlCircularApp extends StatelessWidget {
  const IhlCircularApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'IHL Circular • Instituto Horizonte Livre',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        scrollBehavior: const AppScrollBehavior(),
        home: const RootGate(),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Se não estiver logado, exibe a Tela 0 (Login & Cadastro)
    if (!auth.isAuthenticated) {
      return const LoginRegisterScreen();
    }

    // Se estiver logado como Administrador, abre o Painel Admin
    if (auth.isAdmin) {
      return const AdminDashboardScreen();
    }

    // Se for Usuário Comum, abre o aplicativo com BottomNavigationBar de 3 abas
    return const MainNavigationScreen();
  }
}
