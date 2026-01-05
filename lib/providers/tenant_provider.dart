import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tenant.dart';

class TenantProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Tenant> tenants = [];
  bool isLoading = false;

  // ==========================
  // FETCH TENANTS
  // ==========================
  Future<void> fetchTenants() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('tenants')
          .select('''
            id,
            user_id,
            user_email,
            room_id,
            check_in_date,
            check_out_date,

            emergency_name,
            emergency_phone,

            ktp_url,
            ktp_status,
            ktp_verified,

            rooms(number)
          ''')
          .order('check_in_date', ascending: false);

      tenants = (response as List).map((e) => Tenant.fromMap(e)).toList();
    } catch (e) {
      debugPrint('fetchTenants error: $e');
      tenants = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // ADD TENANT (AMAN & BISA PESAN ULANG)
  // ==========================
  Future<void> addTenant({
    required String userEmail,
    required String roomId,
    required String emergencyContact,
  }) async {
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      // 🔴 1️⃣ CEK TENANT AKTIF (WAJIB)
      // 🔴 CEK TENANT AKTIF (VERSI AMAN SEMUA SDK)
      final existingActiveTenant = await _supabase
          .from('tenants')
          .select('id')
          .eq('user_email', userEmail)
          .filter('check_out_date', 'is', null); // ✅ PALING AMAN

      if (existingActiveTenant.isNotEmpty) {
        throw Exception(
          'User ini masih memiliki kamar aktif. Checkout terlebih dahulu.',
        );
      }

      // 2️⃣ ambil user_id dari email
      final userId = await _supabase.rpc(
        'get_user_id_by_email',
        params: {'email_input': userEmail},
      );

      if (userId == null) {
        throw Exception('User dengan email tersebut tidak ditemukan');
      }

      // 3️⃣ ambil harga kamar
      final room = await _supabase
          .from('rooms')
          .select('price')
          .eq('id', roomId)
          .single();

      final int roomPrice = room['price'];

      // 4️⃣ INSERT TENANT BARU
      final tenant = await _supabase
          .from('tenants')
          .insert({
            'user_id': userId,
            'user_email': userEmail,
            'room_id': roomId,
            'check_in_date': DateTime.now().toIso8601String(),
            'emergency_contact': emergencyContact,
          })
          .select()
          .single();

      final String tenantId = tenant['id'];

      // 5️⃣ AUTO CREATE PAYMENT
      final now = DateTime.now();
      final String currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      await _supabase.from('payments').insert({
        'tenant_id': tenantId,
        'month': currentMonth,
        'amount': roomPrice,
        'status': 'unpaid',
      });

      // 6️⃣ UPDATE ROOM STATUS
      await _supabase
          .from('rooms')
          .update({'status': 'occupied'})
          .eq('id', roomId);

      await fetchTenants();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // CHECKOUT TENANT
  // ==========================
  Future<void> checkoutTenant({
    required String tenantId,
    required String roomId,
  }) async {
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      final tenant = await _supabase
          .from('tenants')
          .select('check_out_date')
          .eq('id', tenantId)
          .single();

      if (tenant['check_out_date'] != null) {
        throw Exception('Penyewa sudah checkout');
      }

      // update tenant
      await _supabase
          .from('tenants')
          .update({'check_out_date': DateTime.now().toIso8601String()})
          .eq('id', tenantId);

      // update room
      await _supabase
          .from('rooms')
          .update({'status': 'available'})
          .eq('id', roomId);

      await fetchTenants();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // REQUEST ROOM (OPSIONAL)
  // ==========================
  Future<void> requestRoom({
    required String roomId,
    required String userEmail,
  }) async {
    await _supabase.from('room_requests').insert({
      'room_id': roomId,
      'user_email': userEmail,
      'status': 'pending',
    });
  }
}
