import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LgpdTermsDialog extends StatelessWidget {
  const LgpdTermsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: AppTheme.primaryBlue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Termos de Privacidade & LGPD',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'O Instituto Horizonte Livre (IHL) cumpre integralmente as diretrizes da Lei Geral de Proteção de Dados (Lei nº 13.709/2018 - LGPD).',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Coleta Restrita de Dados',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Para viabilizar as reservas de brechó/artesanato e agendamentos de doações presenciais em nossa sede em Mogi das Cruzes, coletamos unicamente: (a) Nome Completo, (b) E-mail e (c) Número de Celular/WhatsApp.',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 10),
              const Text(
                '2. Finalidade e Não Compartilhamento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Seus dados são utilizados exclusivamente para identificar quem reservou itens no balcão e gerenciar entregas de doações. Seus dados NUNCA serão vendidos, alugados ou compartilhados com terceiros com fins comerciais.',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 10),
              const Text(
                '3. Direito de Exclusão Imediata (Art. 18 LGPD)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Você tem o direito de solicitar a exclusão total e imediata dos seus dados a qualquer momento através do botão nativo "Excluir Minha Conta" disponível na aba de perfil do aplicativo.',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 10),
              const Text(
                '4. Segurança e Transparência',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'O IHL Circular opera sem cobranças online ou custódia de dados bancários/cartões. Todo o fluxo financeiro é realizado presencialmente na sede.',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Compreendi e Fechar'),
        ),
      ],
    );
  }
}
