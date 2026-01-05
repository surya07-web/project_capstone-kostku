import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool isLoading = true; // 🔑 WAJIB TRUE DI AWAL
  String? role;
  Session? _session;

  Session? get session => _session;
  bool get isLoggedIn => _session != null;

  AuthProvider() {
    _init(); // 🔥 INIT ASYNC
  }

  // ==========================
  // INIT SESSION + ROLE
  // ==========================
  Future<void> _init() async {
    try {
      _session = _supabase.auth.currentSession;

      if (_session != null) {
        final userId = _session!.user.id;
        role = await _authService.getUserRoleById(userId);
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // LOGIN
  // ==========================
  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final userId = await _authService.login(email, password);

      _session = _supabase.auth.currentSession;
      role = await _authService.getUserRoleById(userId);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // REGISTER
  // ==========================
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // LOGOUT
  // ==========================
  Future<void> logout() async {
    await _authService.logout();
    _session = null;
    role = null;
    notifyListeners();
  }
}
