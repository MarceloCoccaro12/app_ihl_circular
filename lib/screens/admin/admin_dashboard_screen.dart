import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_product_dialog.dart';
import '../auth/login_register_screen.dart';
import '../common/main_navigation_screen.dart';
import 'admin_donations_screen.dart';
import 'admin_statistics_screen.dart';
import 'admin_cashier_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _handleReleaseExpired(BuildContext context) {
    final app = context.read<AppProvider>();
    final freed = app.liberarReservasExpiradas();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm_off, color: AppTheme.accentBlue),
            SizedBox(width: 8),
            Text('Manutenção de Reservas', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          freed > 0
              ? '✅ $freed item(ns) cuja reserva ultrapassou 168 horas foram liberados e retornaram para a vitrine digital!'
              : 'Nenhuma reserva expirada (> 168h) no momento. Todas as reservas ativas estão dentro do prazo.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openAddProduct(BuildContext context, ProductCategory category) {
    showDialog(
      context: context,
      builder: (_) => AddProductDialog(initialCategory: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();

    // CONTROLE DE ACESSO ESTRITO: Impede acesso não-autorizado à área de administrador
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
            (route) => false,
          );
        }
      });
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppTheme.darkRed,
          title: const Text('Acesso Restrito'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad, size: 64, color: AppTheme.darkRed),
                const SizedBox(height: 16),
                const Text(
                  'Acesso Não Autorizado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta área é restrita exclusivamente a monitores e administradores do IHL.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar para a Área do Usuário'),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final activeReservations = app.allActiveReservations;
    final scheduledDonations =
        app.allDonations.where((d) => d.isScheduled).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Painel Administrativo IHL'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair da Conta Administrador',
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const LoginRegisterScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status do Monitor Responsável
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryBlue.withAlpha(25),
                    child: const Icon(Icons.badge, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.name ?? 'Monitor IHL',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Sede Mogi das Cruzes • Balcão de Atendimento & Estoque',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.circularGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // INDICADORES RÁPIDOS (KPIs)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Arrecadação Total',
                    value: currencyFormat.format(app.totalRevenue),
                    icon: Icons.payments,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Terapias PcD',
                    value: '${app.totalTherapyHours.toStringAsFixed(1)} h',
                    icon: Icons.favorite,
                    color: AppTheme.circularGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Reservas no Balcão',
                    value: '${activeReservations.length} itens',
                    icon: Icons.hourglass_top,
                    color: AppTheme.warningOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Doações Agendadas',
                    value: '$scheduledDonations entregas',
                    icon: Icons.event,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // BOTÕES DE ATALHO PRINCIPAIS (CONFORME ESPECIFICAÇÃO TELA 2)
            const Text(
              'Ações Operacionais de Gestão:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Atalho 1: Notificações e Agendamentos
            _buildActionTile(
              context: context,
              title: '🔔 Notificações e Agendamentos de Doações',
              subtitle:
                  '$scheduledDonations doação(ões) pendente(s) para recebimento no balcão',
              icon: Icons.notifications_active,
              color: AppTheme.accentBlue,
              badgeCount: scheduledDonations,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDonationsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Atalho 2: Gerenciar Reservas & Baixa
            _buildActionTile(
              context: context,
              title: '💳 Gerenciar Reservas & Baixa de Pagamento',
              subtitle:
                  'Guichê presencial: confirmar pagamentos e liberar itens retirados',
              icon: Icons.point_of_sale,
              color: AppTheme.circularGreen,
              badgeCount: activeReservations.length,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminCashierScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Atalho 3: Estatísticas & Faturamento
            _buildActionTile(
              context: context,
              title: '📊 Estatísticas & Faturamento',
              subtitle:
                  'Relatório de vendas por categoria, impacto de terapias e exportação',
              icon: Icons.insights,
              color: AppTheme.primaryBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminStatisticsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // CADASTRO DIRETO DE ESTOQUE POR CATEGORIA (CONFORME ESPECIFICAÇÃO)
            const Text(
              'Entrada Rápida de Estoque por Categoria:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Artesanatos PcD possuem teto obrigatório de R\$ 50,00 e crédito nominal do assistido autor.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildStockButton(
                    context: context,
                    label: '🎨 Artesanato\n(Assistidos)',
                    color: AppTheme.circularGreen,
                    onTap: () =>
                        _openAddProduct(context, ProductCategory.artesanato),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStockButton(
                    context: context,
                    label: '👕 Brechó\n(Garimpo)',
                    color: AppTheme.accentBlue,
                    onTap: () =>
                        _openAddProduct(context, ProductCategory.brecho),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStockButton(
                    context: context,
                    label: '🪵 Outros\nMateriais',
                    color: const Color(0xFFD97706),
                    onTap: () =>
                        _openAddProduct(context, ProductCategory.materiais),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // BOTÃO DE MANUTENÇÃO: [ ⏰ Liberar Reservas Expiradas ]
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.alarm_off,
                          color: AppTheme.warningOrange, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Rotina de Manutenção Automática',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Verifica se há produtos com tempo de reserva esgotado (> 168 horas / 7 dias) e os retorna automaticamente à vitrine para outros compradores.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF78350F),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restore_page_outlined),
                    label: const Text('⏰ Liberar Reservas Expiradas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    onPressed: () => _handleReleaseExpired(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(25),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildStockButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        '+ $label',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
