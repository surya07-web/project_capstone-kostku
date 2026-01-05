import 'package:supabase_flutter/supabase_flutter.dart';

class TenantService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ➕ ADD TENANT
  /// return tenantId (dipakai untuk upload KTP)
  Future<String> addTenant({
    required String userEmail,
    required String roomId,
    required String emergencyContact,
  }) async {
    // 🔍 ambil user_id dari auth.users via RPC
    final userId = await _supabase.rpc(
      'get_user_id_by_email',
      params: {'email_input': userEmail},
    );

    if (userId == null) {
      throw Exception('User dengan email tersebut tidak ditemukan');
    }

    // ➕ insert tenant & ambil id
    final tenant = await _supabase
        .from('tenants')
        .insert({
          'user_id': userId,
          'room_id': roomId,
          'check_in_date': DateTime.now().toIso8601String(),
          'emergency_contact': emergencyContact,
        })
        .select()
        .single();

    final tenantId = tenant['id'] as String;

    // 🔁 update status kamar
    await _supabase
        .from('rooms')
        .update({'status': 'occupied'})
        .eq('id', roomId);

    return tenantId;
  }
}
