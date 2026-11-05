import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final _formKey = GlobalKey<FormState>();

  DonationCategory _selectedCategory = DonationCategory.brecho;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final List<String> _timeSlots = const [
    '09:00 - 10:30',
    '10:30 - 12:00',
    '13:30 - 15:00',
    '15:00 - 16:30',
  ];
  late String _selectedTimeSlot;

  bool _isSubmitting = false;
  String _selectedImagePlaceholder =
      'https://images.unsplash.com/photo-1532453286298-9845b149856b?auto=format&fit=crop&w=600&q=80';

  @override
  void initState() {
    super.initState();
    _selectedTimeSlot = _timeSlots.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();

    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.darkRed,
          content: Text('Faça login para agendar sua doação solidária.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final donation = await app.scheduleDonation(
        user: auth.currentUser!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        scheduledDate: _selectedDate,
        scheduledTimeSlot: _selectedTimeSlot,
        imageUrl: _selectedImagePlaceholder,
      );

      if (mounted) {
        _titleController.clear();
        _descController.clear();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.circularGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entrega Agendada!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obrigado pela sua solidariedade, ${auth.currentUser!.name}! Sua doação de "${donation.title}" foi registrada com sucesso.',
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📅 Data: ${DateFormat('dd/MM/yyyy').format(donation.scheduledDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        '⏰ Horário: ${donation.scheduledTimeSlot}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '📍 Ponto de Entrega: Sede IHL (Rua Cel. Santos Cardoso, 420 - Centro, Mogi das Cruzes - SP)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK, Maravilha!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.darkRed,
            content: Text('Erro ao agendar: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final userDonations = auth.currentUser != null
        ? app.getUserDonations(auth.currentUser!.id)
        : <DonationScheduleModel>[];

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Ciclo de Doações
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volunteer_activism,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ciclo Solidário de Doações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Doe roupas, calçados e materiais em bom estado. As peças abastecem o brechó e oficinas que financiam terapias PcD em Mogi das Cruzes.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // FORMULÁRIO DE AGENDAMENTO
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Agendar Entrega de Doação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Entregas recebidas de segunda a sexta na sede do IHL.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SELETOR DE CATEGORIA (Brechó ou Outros Materiais)
                      const Text(
                        'Categoria da Doação:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('👕 Brechó Solidário'),
                                ),
                              ),
                              selected:
                                  _selectedCategory == DonationCategory.brecho,
                              selectedColor: AppTheme.primaryBlue,
                              labelStyle: TextStyle(
                                color: _selectedCategory == DonationCategory.brecho
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = DonationCategory.brecho;
                                  _selectedImagePlaceholder =
                                      'https://images.unsplash.com/photo-1532453286298-9845b149856b?auto=format&fit=crop&w=600&q=80';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('🪵 Outros Materiais'),
                                ),
                              ),
                              selected: _selectedCategory ==
                                  DonationCategory.materiais,
                              selectedColor: AppTheme.circularGreen,
                              labelStyle: TextStyle(
                                color: _selectedCategory ==
                                        DonationCategory.materiais
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory =
                                      DonationCategory.materiais;
                                  _selectedImagePlaceholder =
                                      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=600&q=80';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Título da doação
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'O que você está doando? *',
                          hintText: 'Ex: 2 sacolas de roupas infantis',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Descreva resumidamente os itens';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Descrição
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Detalhes e Estado de Conservação *',
                          hintText: 'Tamanhos, quantidade aproximada, higienização...',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Informe os detalhes dos itens';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // SELEÇÃO DE DATA E HORÁRIO DE ENTREGA PRESENCIAL
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Data da Entrega:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppTheme.borderColor),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              dateFormat.format(_selectedDate),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.calendar_month,
                                          size: 18,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Faixa de Horário:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _selectedTimeSlot,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: _timeSlots.map((slot) {
                                    return DropdownMenuItem(
                                      value: slot,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          slot,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedTimeSlot = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // BOTÃO DESTACADO: [ 📅 AGENDAR ENTREGA PRESENCIAL ]
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.circularGreen,
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available, color: Colors.white),
                            SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '📅 AGENDAR ENTREGA PRESENCIAL',
                                  style: TextStyle(
                                    fontSize: 14,
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
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // HISTÓRICO DE DOAÇÕES DO USUÁRIO
            const Text(
              'Suas Doações Agendadas:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            if (userDonations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Center(
                  child: Text(
                    'Você ainda não agendou doações. Faça sua primeira doação acima!',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userDonations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final don = userDonations[index];
                  final isReceived = don.isReceived;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isReceived
                            ? AppTheme.circularGreen.withAlpha(60)
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: isReceived
                              ? AppTheme.lightGreen
                              : const Color(0xFFEFF6FF),
                          child: Icon(
                            isReceived ? Icons.check_circle : Icons.schedule,
                            color: isReceived
                                ? AppTheme.circularGreen
                                : AppTheme.accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      don.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isReceived
                                          ? AppTheme.lightGreen
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isReceived
                                          ? '✔️ RECEBIDO NO BALCÃO'
                                          : '⏳ AGENDADO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: isReceived
                                            ? AppTheme.circularGreen
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                don.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '📅 ${dateFormat.format(don.scheduledDate)} • ${don.scheduledTimeSlot}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
