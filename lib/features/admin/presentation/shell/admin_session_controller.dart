import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';

enum AdminSessionPhase {
  loading,
  login,
  verify,
  password,
  enroll,
  ready,
  error,
  forbidden,
}

class AdminSessionController extends ChangeNotifier {
  static final AdminSessionController instance =
      AdminSessionController._internal();

  final ApiClient api = ApiClient();
  AdminSessionPhase phase = AdminSessionPhase.loading;
  String? errorMessage;
  String? sharedKey;

  AdminSessionController._internal() {
    api.onUnauthorized = () {
      if (phase != AdminSessionPhase.login) {
        phase = AdminSessionPhase.login;
        errorMessage = 'Sessão expirada. Faça login novamente.';
        notifyListeners();
      }
    };
    api.onForbidden = () {
      phase = AdminSessionPhase.forbidden;
      errorMessage = 'Você não tem permissão para acessar esta área.';
      notifyListeners();
    };

    _init();
  }

  Future<void> _init() async {
    await loadSession();
  }

  Future<void> loadSession() async {
    try {
      phase = AdminSessionPhase.loading;
      errorMessage = null;
      notifyListeners();

      await api.fetchCsrf();
      final me = await api.get('/api/admin/auth/me');

      if (me['mustChangePassword'] == true) {
        phase = AdminSessionPhase.password;
      } else if (me['mfaEnabled'] != true) {
        phase = AdminSessionPhase.enroll;
      } else {
        phase = AdminSessionPhase.ready;
      }
    } catch (_) {
      phase = AdminSessionPhase.login;
    }
    notifyListeners();
  }

  void requireLogin() {
    phase = AdminSessionPhase.login;
    errorMessage = null;
    notifyListeners();
  }

  void setPhase(AdminSessionPhase newPhase, {String? error}) {
    phase = newPhase;
    errorMessage = error;
    notifyListeners();
  }

  void setSharedKey(String? key) {
    sharedKey = key;
    notifyListeners();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}

class AdminSessionProvider extends InheritedNotifier<AdminSessionController> {
  const AdminSessionProvider({
    super.key,
    required AdminSessionController super.notifier,
    required super.child,
  });

  static AdminSessionController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdminSessionProvider>()!
        .notifier!;
  }
}
