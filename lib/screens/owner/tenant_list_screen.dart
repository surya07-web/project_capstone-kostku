import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/tenant_provider.dart';
import '../../providers/room_provider.dart';
import '../../models/tenant.dart';
import 'tenant_detail_screen.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  static const Color blue = Color(0xFF2F6FED);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TenantProvider>().fetchTenants();
      context.read<RoomProvider>().fetchRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenantProv = context.watch<TenantProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // =====================
      // HEADER
      // =====================
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        title: const Text('Data Penyewa'),
      ),

      body: tenantProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tenantProv.tenants.isEmpty
          ? const Center(child: Text('Belum ada penyewa'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tenantProv.tenants.length,
              itemBuilder: (context, index) {
                final Tenant t = tenantProv.tenants[index];
                final bool hasRoom = t.roomNumber != null;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TenantDetailScreen(tenant: t),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // =====================
                        // AVATAR
                        // =====================
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: blue.withOpacity(0.15),
                          child: const Icon(
                            Icons.person,
                            color: blue,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 14),

                        // =====================
                        // INFO PENYEWA
                        // =====================
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.userEmail ?? 'User tidak diketahui',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasRoom
                                    ? 'Kamar ${t.roomNumber}'
                                    : 'Belum ada kamar',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Masuk: ${t.checkInDate ?? '-'}',
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // =====================
                        // STATUS + ARROW
                        // =====================
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      // =====================
      // FAB
      // =====================
      floatingActionButton: FloatingActionButton(
        backgroundColor: blue,
        child: const Icon(Icons.add),
        onPressed: () => _showAddTenantDialog(context),
      ),
    );
  }

  // =====================
  // ADD TENANT DIALOG
  // =====================
  void _showAddTenantDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final emergencyCtrl = TextEditingController();
    String? selectedRoomId;

    final rooms = context
        .read<RoomProvider>()
        .rooms
        .where((r) => r.status == 'available')
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Penyewa'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Penyewa'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  hint: const Text('Pilih Kamar'),
                  items: rooms
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.id,
                          child: Text('Kamar ${r.number}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedRoomId = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailCtrl.text.isEmpty || selectedRoomId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email & kamar wajib diisi')),
                  );
                  return;
                }

                await context.read<TenantProvider>().addTenant(
                  userEmail: emailCtrl.text.trim(),
                  roomId: selectedRoomId!,
                  emergencyContact: emergencyCtrl.text,
                );

                if (!context.mounted) return;
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Penyewa berhasil ditambahkan')),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
