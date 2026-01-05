import '../core/constants/supabase_client.dart';

class AuthService {
  // ==========================
  // LOGIN (RETURN USER ID)
  // ==========================
  Future<String> login(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Login gagal');
    }

    return user.id;
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
    final res = await supabase.auth.signUp(email: email, password: password);

    final user = res.user;
    if (user == null) {
      throw Exception('Gagal membuat akun');
    }

    await supabase.from('users').insert({
      'id': user.id,
      'email': email,
      'name': name,
      'role': role,
    });
  }

  // ==========================
  // GET ROLE BY USER ID
  // ==========================
  Future<String> getUserRoleById(String userId) async {
    final data = await supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .single();

    return data['role'];
  }

  // ==========================
  // LOGOUT
  // ==========================
  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}
