import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AdminDonationsScreen extends StatefulWidget {
  const AdminDonationsScreen({super.key});

  @override
  State<AdminDonationsScreen> createState() => _AdminDonationsScreenState();
}

class _AdminDonationsScreenState extends State<AdminDonationsScreen> {
  int _selectedFilter = 0; // 0: Pendentes, 1: Recebidos, 2: Todos

  void _handleReceiveDonation(
      BuildContext context, DonationScheduleModel donation) async {
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Receber Doação?'),
        content: Text(
          'Confirmar o recebimento físico de "${donation.title}" doado(a) por ${donation.donorName} na sede do IHL?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.circularGreen,
              minimumSize: const Size(0, 38),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar Recebimento'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await app.markDonationReceived(
        donationId: donation.id,
        adminId: auth.currentUser?.id ?? 'admin_balcao',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.circularGreen,
            content: Text(
              'Doação de ${donation.donorName} recebida e baixada com sucesso!',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allDonations = app.allDonations;
    final dateFormat = DateFormat('dd/MM/yyyy');

    final filteredDonations = allDonations.where((d) {
      if (_selectedFilter == 0) return d.isScheduled;
      if (_selectedFilter == 1) return d.isReceived;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Agendamentos de Doações'),
      ),
      body: Column(
        children: [
          // FILTRO POR STATUS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Pendentes'),
                        ),
                        icon: Icon(Icons.schedule, size: 16),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Recebidos'),
                        ),
                        icon: Icon(Icons.check_circle_outline, size: 16),
                      ),
                      ButtonSegment(
                        value: 2,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Todos'),
                        ),
                      ),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (set) {
                      setState(() => _selectedFilter = set.first);
                    },
                  ),
                ),
              ],
            ),
          ),

          // LISTA DE DOAÇÕES
          Expanded(
            child: filteredDonations.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum agendamento encontrado nesta categoria.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDonations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final don = filteredDonations[index];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: don.isReceived
                                ? AppTheme.circularGreen.withAlpha(60)
                                : AppTheme.borderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${don.category.iconEmoji} ${don.category.label}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: don.isReceived
                                        ? AppTheme.lightGreen
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    don.isReceived
                                        ? '✔️ RECEBIDO'
                                        : '⏳ AGENDADO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: don.isReceived
                                          ? AppTheme.circularGreen
                                          : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              don.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              don.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 16, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Doador: ${don.donorName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    size: 16, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Contato: ${don.donorPhone} • ${don.donorEmail}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.event,
                                    size: 16, color: AppTheme.primaryBlue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Data Prevista: ${dateFormat.format(don.scheduledDate)} (${don.scheduledTimeSlot})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),

                            // BOTÃO [✔️ Marcar como Recebido e Dar Baixa]
                            if (don.isScheduled) ...[
                              const SizedBox(height: 14),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.circularGreen,
                                  minimumSize: const Size(double.infinity, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () =>
                                    _handleReceiveDonation(context, don),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '✔️ Marcar como Recebido e Dar Baixa',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
