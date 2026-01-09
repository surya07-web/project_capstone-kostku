import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class PaymentProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  /// Dipakai di semua screen
  List<Map<String, dynamic>> payments = [];

  // ==========================
  // GENERATE PAYMENT OTOMATIS
  // ==========================
  Future<void> generatePaymentForTenant({required String tenantId}) async {
    isLoading = true;
    notifyListeners();

    try {
      // Ambil harga kamar dari relasi rooms
      final tenant = await _supabase
          .from('tenants')
          .select('room_id, rooms(price)')
          .eq('id', tenantId)
          .single();

      final int price = tenant['rooms']['price'];

      final String month = DateTime.now().toIso8601String().substring(
        0,
        7,
      ); // YYYY-MM

      // Cek apakah payment bulan ini sudah ada
      final existing = await _supabase
          .from('payments')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('month', month);

      if (existing.isNotEmpty) return;

      await _supabase.from('payments').insert({
        'tenant_id': tenantId,
        'month': month,
        'amount': price,
        'status': 'unpaid',
      });
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // MARK AS PAID (OWNER)
  // ==========================
  Future<void> markAsPaid(String paymentId) async {
    isLoading = true;
    notifyListeners();

    await _supabase
        .from('payments')
        .update({
          'status': 'paid',
          'paid_date': DateTime.now().toIso8601String(),
        })
        .eq('id', paymentId);

    //
    await fetchPayments();

    isLoading = false;
    notifyListeners();
  }

  // ===================================================
  // ========== UPLOAD BUKTI PEMBAYARAN (TENANT)
  // ===================================================

  XFile? receiptFile;

  Future<void> pickReceipt() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (file != null) {
      receiptFile = file;
      notifyListeners();
    }
  }

  Future<void> uploadReceipt({required String paymentId}) async {
    if (receiptFile == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final bytes = await receiptFile!.readAsBytes();
      final path = '$paymentId/receipt.jpg';

      await _supabase.storage
          .from('payment_receipts')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      await _supabase
          .from('payments')
          .update({'receipt_photo': path})
          .eq('id', paymentId);

      receiptFile = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> getReceiptUrl(String path) async {
    return await _supabase.storage
        .from('payment_receipts')
        .createSignedUrl(path, 60 * 60);
  }

  // ==========================
  // PAYMENT MILIK TENANT
  // ==========================
  Future<void> fetchMyPayments() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        payments = [];
        return;
      }

      final tenant = await _supabase
          .from('tenants')
          .select('id')
          .eq('user_email', user.email!)
          .maybeSingle();

      if (tenant == null) {
        payments = [];
        return;
      }

      final res = await _supabase
          .from('payments')
          .select()
          .eq('tenant_id', tenant['id'])
          .order('month', ascending: false);

      payments = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('fetchMyPayments error: $e');
      payments = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // SEMUA PAYMENT (OWNER)
  // ==========================
  Future<void> fetchPayments() async {
    isLoading = true;
    notifyListeners();

    try {
      //
      final res = await _supabase
          .from('payments')
          .select('''
        id,
        month,
        amount,
        status,
        paid_date,
        tenant_id,
        tenants (
          user_email,
          room_id
        )
      ''')
          .order('month', ascending: false);

      payments = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('fetchPayments error: $e');
      payments = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // AMBIL NOMOR KAMAR (HELPER)
  // ==========================
  Future<String?> getRoomNumber(String roomId) async {
    final res = await _supabase
        .from('rooms')
        .select('number')
        .eq('id', roomId)
        .maybeSingle();

    return res?['number'];
  }

  // ==========================
  // RIWAYAT TERBARU PEMBAYARAN
  // ==========================
  List<Map<String, dynamic>> get latestPaymentHistories {
    final paidPayments = payments
        .where((p) => p['status'] == 'paid' && p['paid_date'] != null)
        .toList();

    paidPayments.sort((a, b) {
      final aDate = DateTime.parse(a['paid_date']);
      final bDate = DateTime.parse(b['paid_date']);
      return bDate.compareTo(aDate);
    });

    return paidPayments.take(5).toList(); // ambil 5 terbaru
  }

  // ==========================
  // FORMAT DATA RIWAYAT UNTUK DASHBOARD
  // ==========================
  Future<Map<String, String>> buildHistoryData(
    Map<String, dynamic> payment,
  ) async {
    final tenant = payment['tenants'];
    final roomId = tenant?['room_id'];

    String roomLabel = 'Kamar';
    if (roomId != null) {
      final roomNumber = await getRoomNumber(roomId);
      if (roomNumber != null) {
        roomLabel = 'Kamar $roomNumber';
      }
    }

    return {
      'name': tenant?['user_email'] ?? 'Penyewa',
      'room': roomLabel,
      'activity': 'Melakukan pembayaran',
      'time': _timeAgo(payment['paid_date']),
    };
  }

  // ==========================
  // TIME AGO HELPER
  // ==========================
  String _timeAgo(String dateTime) {
    final date = DateTime.parse(dateTime);
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }
}
