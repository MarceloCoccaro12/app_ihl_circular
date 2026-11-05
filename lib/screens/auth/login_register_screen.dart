// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lgpd_terms_dialog.dart';
import '../common/main_navigation_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool _isRegisterMode = false;
  final _formKey = GlobalKey<FormState>();

  UserRole _selectedRole = UserRole.comum;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'mariana.souza@email.com';
    _passwordController.text = '123456';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    if (_isRegisterMode) {
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.darkRed,
            content: Text(
              '⚠️ É obrigatório aceitar os Termos de Privacidade e Proteção de Dados (LGPD).',
            ),
          ),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.darkRed,
            content: Text('As senhas não coincidem. Digite novamente.'),
          ),
        );
        return;
      }

      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        termsAccepted: _termsAccepted,
      );

      if (success && mounted) {
        _navigateAfterAuth();
      }
    } else {
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        expectedRole: _selectedRole,
      );

      if (success && mounted) {
        _navigateAfterAuth();
      }
    }
  }

  void _navigateAfterAuth() {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Redefinição de Senha'),
          ],
        ),
        content: Text(
          email.isNotEmpty
              ? 'Enviamos um link seguro de redefinição de senha para o e-mail: $email.\n\nVerifique sua caixa de entrada.'
              : 'Por favor, informe seu e-mail no campo correspondente para enviarmos as instruções de redefinição de senha.',
          style: const TextStyle(fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK, Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logotipo e Slogan do Instituto Horizonte Livre (IHL)
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withAlpha(70),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.recycling,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'IHL CIRCULAR',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Instituto Horizonte Livre • Mogi das Cruzes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.circularGreen,
                    ),
                  ),

                  const SizedBox(height: 2),

                  const Text(
                    'Economia Circular & Brechó Beneficente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Card de Formulário
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRegisterMode
                                  ? 'Cadastre-se na Plataforma'
                                  : 'Acesso ao Aplicativo',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isRegisterMode
                                  ? 'Preencha seus dados cadastrais (Governança LGPD)'
                                  : 'Selecione seu perfil e faça login',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // SELETOR DE PERFIL VIA RADIOBUTTONS
                            const Text(
                              'Selecione seu Perfil:',
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
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedRole = UserRole.comum;
                                        if (!_isRegisterMode) {
                                          _emailController.text =
                                              'mariana.souza@email.com';
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == UserRole.comum
                                            ? const Color(0xFFEFF6FF)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _selectedRole == UserRole.comum
                                              ? AppTheme.accentBlue
                                              : AppTheme.borderColor,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<UserRole>(
                                            value: UserRole.comum,
                                            groupValue: _selectedRole,
                                            activeColor: AppTheme.accentBlue,
                                            onChanged: (val) {
                                              setState(() {
                                                _selectedRole = val!;
                                                if (!_isRegisterMode) {
                                                  _emailController.text =
                                                      'mariana.souza@email.com';
                                                }
                                              });
                                            },
                                          ),
                                          const Expanded(
                                            child: Text(
                                              'Usuário Comum\n(Doador/Comprador)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedRole = UserRole.admin;
                                        if (!_isRegisterMode) {
                                          _emailController.text =
                                              'admin@ihl.org.br';
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == UserRole.admin
                                            ? const Color(0xFFEFF6FF)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _selectedRole == UserRole.admin
                                              ? AppTheme.accentBlue
                                              : AppTheme.borderColor,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<UserRole>(
                                            value: UserRole.admin,
                                            groupValue: _selectedRole,
                                            activeColor: AppTheme.accentBlue,
                                            onChanged: (val) {
                                              setState(() {
                                                _selectedRole = val!;
                                                if (!_isRegisterMode) {
                                                  _emailController.text =
                                                      'admin@ihl.org.br';
                                                }
                                              });
                                            },
                                          ),
                                          const Expanded(
                                            child: Text(
                                              'Administrador\n(Monitor IHL)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Formulário Expansível de Cadastro
                            if (_isRegisterMode) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome Completo *',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Informe seu nome completo';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Celular com DDD *',
                                  hintText: '(11) 98765-4321',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Informe seu celular com DDD';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                            ],

                            // E-mail
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'E-mail *',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (val) {
                                if (val == null || !val.contains('@')) {
                                  return 'Informe um e-mail válido';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            // Senha
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Senha *',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.length < 4) {
                                  return 'Senha de no mínimo 4 caracteres';
                                }
                                return null;
                              },
                            ),

                            // Confirmação de Senha no Cadastro
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirmar Senha *',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null ||
                                      val != _passwordController.text) {
                                    return 'As senhas não coincidem';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            // Mensagem de Erro
                            if (authProvider.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppTheme.darkRed,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authProvider.errorMessage!,
                                        style: const TextStyle(
                                          color: AppTheme.darkRed,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // CHECKBOX OBRIGATÓRIO LGPD NO CADASTRO
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _termsAccepted,
                                    activeColor: AppTheme.circularGreen,
                                    onChanged: (val) {
                                      setState(() {
                                        _termsAccepted = val ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          const Text(
                                            'Aceito os ',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    const LgpdTermsDialog(),
                                              );
                                            },
                                            child: const Text(
                                              'Termos de Privacidade e Proteção de Dados (LGPD)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.accentBlue,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Link: Esqueceu a senha?
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _handleForgotPassword,
                                  child: const Text(
                                    'Esqueceu a senha?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.accentBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // Botão Principal: [ ENTRAR ] ou [ FINALIZAR CADASTRO ]
                            ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedRole == UserRole.admin
                                    ? AppTheme.primaryBlue
                                    : AppTheme.circularGreen,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isRegisterMode
                                          ? 'FINALIZAR CADASTRO'
                                          : 'ENTRAR',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 12),

                            // Link [Cadastre-se Aqui] / [Já possui conta?]
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isRegisterMode = !_isRegisterMode;
                                    authProvider.clearError();
                                  });
                                },
                                child: Text(
                                  _isRegisterMode
                                      ? 'Já possui conta? Faça login aqui'
                                      : 'Cadastre-se Aqui',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.accentBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
