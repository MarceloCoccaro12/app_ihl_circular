import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/ihl_repository.dart';

class AuthProvider extends ChangeNotifier {
  final IhlRepository _repository = IhlRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCommon => _currentUser?.isCommon ?? true;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Alternador Rápido de Perfil (Facilitador de Avaliação de Banca / Diretoria)
  void switchDemoUser(UserRole role) {
    final users = _repository.getUsers();
    if (role == UserRole.admin) {
      _currentUser = users.firstWhere(
        (u) => u.role == UserRole.admin,
        orElse: () => users.first,
      );
    } else {
      _currentUser = users.firstWhere(
        (u) => u.role == UserRole.comum,
        orElse: () => users.first,
      );
    }
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final user = _repository.findUserByEmail(email);
      if (user == null) {
        _errorMessage = 'Usuário não encontrado. Verifique o e-mail ou cadastre-se.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (user.role != expectedRole) {
        _errorMessage =
            'Este e-mail está cadastrado como ${user.role == UserRole.admin ? "Administrador" : "Usuário Comum"}. Ajuste o seletor de perfil.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required bool termsAccepted,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final newUser = _repository.registerUser(
        name: name,
        email: email,
        phone: phone,
        role: role,
        termsAccepted: termsAccepted,
      );

      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Governança LGPD: Exclusão Imediata de Conta com Remoção dos Dados Pessoais
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    final userId = _currentUser!.id;
    _repository.deleteUserAccount(userId);

    _currentUser = null;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
