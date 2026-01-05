import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/payment_provider.dart';

import 'room_list_screen.dart';
import 'tenant_list_screen.dart';
import 'payment_list_screen.dart';

class DashboardOwnerScreen extends StatefulWidget {
  const DashboardOwnerScreen({super.key});

  @override
  State<DashboardOwnerScreen> createState() => _DashboardOwnerScreenState();
}

class _DashboardOwnerScreenState extends State<DashboardOwnerScreen> {
  static const Color blue = Color(0xFF2F6FED);
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboardContent(context),
      const RoomListScreen(),
      const TenantListScreen(),
      const PaymentListScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: pages[_currentIndex],

      // =====================
      // 🔽 BOTTOM NAV BAR
      // =====================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room_outlined),
            activeIcon: Icon(Icons.meeting_room),
            label: 'Kamar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Penyewa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Pembayaran',
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DASHBOARD CONTENT
  // =====================================================
  Widget _dashboardContent(BuildContext context) {
    final roomProv = context.watch<RoomProvider>();
    final paymentProv = context.watch<PaymentProvider>();

    final totalRooms = roomProv.rooms.length;
    final occupiedRooms = roomProv.rooms
        .where((r) => r.status == 'occupied')
        .length;
    final availableRooms = totalRooms - occupiedRooms;

    final totalIncome = paymentProv.payments
        .where((p) => p['status'] == 'paid')
        .fold<int>(0, (sum, p) => sum + (p['amount'] as int));

    final histories = paymentProv.latestPaymentHistories;

    return SingleChildScrollView(
      child: Column(
        children: [
          // =========================
          // 🔵 HEADER + STAT
          // =========================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 28),
            decoration: const BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pemilik Kost',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () {
                        context.read<AuthProvider>().logout();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55, // 🔑 CARD LEBIH KECIL
                  children: [
                    _StatCard(
                      title: 'Total Kamar',
                      value: totalRooms.toString(),
                      icon: Icons.home,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Terisi',
                      value: occupiedRooms.toString(),
                      icon: Icons.lock,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'Tersedia',
                      value: availableRooms.toString(),
                      icon: Icons.meeting_room,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'Pendapatan',
                      value: 'Rp ${_rupiah(totalIncome)}',
                      icon: Icons.trending_up,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // =========================
          // 👤 RIWAYAT TERBARU PENYEWA
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Terbaru Penyewa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                if (histories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Belum ada riwayat pembayaran',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: histories.length,
                    itemBuilder: (context, index) {
                      final payment = histories[index];

                      return FutureBuilder<Map<String, String>>(
                        future: paymentProv.buildHistoryData(payment),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }

                          final h = snapshot.data!;
                          return _TenantHistoryTile(
                            name: h['name']!,
                            room: h['room']!,
                            activity: h['activity']!,
                            time: h['time']!,
                            icon: Icons.payments,
                            color: Colors.green,
                          );
                        },
                      );
                    },
                  ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _rupiah(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buffer.write(s[s.length - 1 - i]);
      if ((i + 1) % 3 == 0 && i != s.length - 1) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}

// =========================
// STAT CARD (LEBIH KECIL)
// =========================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14), // sedikit lebih lega
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON
          CircleAvatar(
            radius: 18, // 🔼 dari 16 → 18
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              icon,
              size: 18, // 🔼 icon lebih jelas
              color: color,
            ),
          ),

          const SizedBox(height: 10),

          // TITLE
          Text(
            title,
            style: const TextStyle(
              fontSize: 14, // 🔼 dari 12 → 14
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          // VALUE
          Text(
            value,
            style: const TextStyle(
              fontSize: 22, // 🔥 dari 16 → 22
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// RIWAYAT PENYEWA TILE
// =========================
class _TenantHistoryTile extends StatelessWidget {
  final String name;
  final String room;
  final String activity;
  final String time;
  final IconData icon;
  final Color color;

  const _TenantHistoryTile({
    required this.name,
    required this.room,
    required this.activity,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name • $room',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
