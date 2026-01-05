import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  int totalRooms = 0;
  int occupiedRooms = 0;
  int totalIncome = 0;

  bool isLoading = false;

  Future<void> fetchDashboard() async {
    isLoading = true;
    notifyListeners();

    try {
      // TOTAL KAMAR
      final rooms = await _supabase.from('rooms').select('id');
      totalRooms = rooms.length;

      // KAMAR TERISI
      final occupied = await _supabase
          .from('rooms')
          .select('id')
          .eq('status', 'occupied');
      occupiedRooms = occupied.length;

      // TOTAL PEMASUKAN (LUNAS)
      final payments = await _supabase
          .from('payments')
          .select('amount')
          .eq('status', 'paid');

      totalIncome = payments.fold<int>(
        0,
        (sum, item) => sum + (item['amount'] as int),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
