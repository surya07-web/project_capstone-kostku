import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/tenant_provider.dart';

import 'payment_my_list_screen.dart';
import 'tenant_profile_screen.dart';

class DashboardTenantScreen extends StatefulWidget {
  const DashboardTenantScreen({super.key});

  @override
  State<DashboardTenantScreen> createState() => _DashboardTenantScreenState();
}

class _DashboardTenantScreenState extends State<DashboardTenantScreen> {
  static const primaryColor = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<TenantProvider>().fetchTenants();
      await context.read<PaymentProvider>().fetchMyPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Consumer2<TenantProvider, PaymentProvider>(
        builder: (context, tenantProv, paymentProv, _) {
          if (tenantProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final auth = context.read<AuthProvider>();
          final email = auth.session?.user.email ?? '';

          // 🔑 FIX UTAMA: HANYA TENANT AKTIF
          final myTenant =
              tenantProv.tenants
                  .where((t) => t.userEmail == email && t.checkOutDate == null)
                  .isNotEmpty
              ? tenantProv.tenants.firstWhere(
                  (t) => t.userEmail == email && t.checkOutDate == null,
                )
              : null;

          // ===============================
          // BELUM PUNYA KAMAR
          // ===============================
          if (myTenant == null) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: primaryColor,
                title: const Text('Dashboard Penyewa'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                    },
                  ),
                ],
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Anda belum memiliki kamar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silakan hubungi pemilik kost\nuntuk mendapatkan kamar.',
                        style: TextStyle(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        onPressed: () {
                          context.read<AuthProvider>().logout();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final bool isActive = myTenant.checkOutDate == null;
          final currentPayment = paymentProv.payments.isNotEmpty
              ? paymentProv.payments.first
              : null;

          // ===============================
          // DASHBOARD NORMAL
          // ===============================
          return ListView(
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8E85FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat datang 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
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
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PrimaryButton(
                      icon: Icons.person,
                      label: 'Profil Saya',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TenantProfileScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    _InfoCard(
                      icon: Icons.home,
                      title: 'Informasi Kamar',
                      children: [
                        _infoTile('Nomor', myTenant.roomNumber ?? '-'),
                        _infoTile('Masuk', _formatDate(myTenant.checkInDate)),
                        _statusBadge(isActive),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (isActive)
                      _DangerButton(
                        icon: Icons.logout,
                        label: 'Checkout Kamar',
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Konfirmasi Checkout'),
                              content: const Text(
                                'Yakin ingin checkout dari kamar?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Checkout'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          await context.read<TenantProvider>().checkoutTenant(
                            tenantId: myTenant.id!,
                            roomId: myTenant.roomId!,
                          );

                          await context.read<TenantProvider>().fetchTenants();

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checkout berhasil dilakukan'),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    _InfoCard(
                      icon: Icons.payments,
                      title: 'Tagihan Bulan Ini',
                      children: currentPayment == null
                          ? [const Text('Tidak ada tagihan')]
                          : [
                              _infoTile('Bulan', currentPayment['month']),
                              _infoTile(
                                'Jumlah',
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(currentPayment['amount']),
                              ),
                              _paymentStatus(
                                currentPayment['status'] == 'paid',
                              ),
                            ],
                    ),

                    const SizedBox(height: 24),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Lihat Semua Pembayaran'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentMyListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===============================
  // HELPERS
  // ===============================
  static Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static Widget _statusBadge(bool isActive) {
    return Align(
      alignment: Alignment.centerRight,
      child: Chip(
        label: Text(isActive ? 'AKTIF' : 'CHECKOUT'),
        backgroundColor: isActive
            ? Colors.green.shade100
            : Colors.grey.shade300,
        labelStyle: TextStyle(
          color: isActive ? Colors.green : Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _paymentStatus(bool paid) {
    return Align(
      alignment: Alignment.centerRight,
      child: Chip(
        label: Text(paid ? 'LUNAS' : 'BELUM LUNAS'),
        backgroundColor: paid ? Colors.green.shade100 : Colors.orange.shade100,
        labelStyle: TextStyle(
          color: paid ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is DateTime) {
      return '${date.day}-${date.month}-${date.year}';
    }
    return date.toString();
  }
}

// ===============================
// COMPONENTS
// ===============================
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _DashboardTenantScreenState.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: _DashboardTenantScreenState.primaryColor,
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onTap,
    );
  }
}

class _DangerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DangerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onTap,
    );
  }
}
