import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  void _handleExportReport(BuildContext context) {
    final app = context.read<AppProvider>();
    final reportText = app.generateDirectorReport();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Relatório Gerencial da Diretoria',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: SelectableText(
                reportText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar Relatório Completo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportText));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.circularGreen,
                  content: Text(
                    'Relatório copiado para a área de transferência com sucesso!',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Estatísticas & Faturamento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Relatório',
            onPressed: () => _handleExportReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD DE DESTAQUE: IMPACTO SOCIAL TOTAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ARRECADAÇÃO TOTAL ACUMULADA',
                        style: TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Icon(Icons.volunteer_activism, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormat.format(app.totalRevenue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite,
                            color: Color(0xFF6EE7B7), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${app.totalTherapyHours.toStringAsFixed(1)} Horas de Terapias PcD Cobertas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // BOTÃO DESTACADO: [ 📥 Exportar Relatório para a Diretoria ]
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('📥 Exportar Relatório para a Diretoria'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.circularGreen,
                minimumSize: const Size(double.infinity, 48),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _handleExportReport(context),
            ),

            const SizedBox(height: 24),

            // QUANTIDADE DE PEÇAS VENDIDAS POR CATEGORIA (CONFORME ESPECIFICAÇÃO TELA 2.3)
            const Text(
              'Peças Vendidas por Categoria:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildCategoryStatCard(
                    title: 'Artesanatos PcD',
                    count: app.soldArtisanCount,
                    icon: Icons.palette,
                    color: AppTheme.circularGreen,
                    subtext: 'Teto R\$ 50',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCategoryStatCard(
                    title: 'Brechó Solidário',
                    count: app.soldBrechoCount,
                    icon: Icons.checkroom,
                    color: AppTheme.accentBlue,
                    subtext: 'Moda Circular',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCategoryStatCard(
                    title: 'Outros Materiais',
                    count: app.soldMaterialsCount,
                    icon: Icons.recycling,
                    color: const Color(0xFFD97706),
                    subtext: 'Upcycling',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // HISTÓRICO DE BAIXAS PRESENCIAIS RECENTES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transações no Balcão de Mogi:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${app.totalSoldItems} itens baixados',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lista de transações registradas
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3, // transações padrão do repositório
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  // Demonstração das transações do balcão
                  final sampleTitles = [
                    'Cachecol Artesanal em Lã Merino',
                    'Casaco Sobretudo Preto Vintage',
                    'Banco Rústico de Jardim com Palete',
                  ];
                  final sampleBuyers = [
                    'Mariana Souza',
                    'Mariana Souza',
                    'André Silveira',
                  ];
                  final sampleValues = [50.0, 75.0, 45.0];
                  final sampleMethods = ['PIX IHL', 'Cartão Débito', 'Dinheiro'];

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFD1FAE5),
                      child: const Icon(Icons.check,
                          size: 16, color: AppTheme.circularGreen),
                    ),
                    title: Text(
                      sampleTitles[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Comprador: ${sampleBuyers[index]} • ${sampleMethods[index]}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      currencyFormat.format(sampleValues[index]),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withAlpha(25),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
