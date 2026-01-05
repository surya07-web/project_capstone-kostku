import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tenant.dart';
import '../../providers/tenant_provider.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TenantProvider>().fetchTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenantProv = context.watch<TenantProvider>();

    final Tenant currentTenant = tenantProv.tenants.firstWhere(
      (t) => t.id == widget.tenant.id,
      orElse: () => widget.tenant,
    );

    final bool isCheckedOut = currentTenant.checkOutDate != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Penyewa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================
            // INFO PENYEWA
            // =====================
            _infoTile(
              'Email',
              currentTenant.userEmail?.isNotEmpty == true
                  ? currentTenant.userEmail!
                  : 'Tidak tersedia',
            ),
            _infoTile('Kamar', currentTenant.roomNumber ?? '-'),
            _infoTile('Tanggal Masuk', _formatDate(currentTenant.checkInDate)),
            _infoTile(
              'Tanggal Keluar',
              _formatDate(currentTenant.checkOutDate),
            ),

            _infoTile('Status', isCheckedOut ? 'Nonaktif (Checkout)' : 'Aktif'),

            const SizedBox(height: 12),

            // =====================
            // STATUS BADGE
            // =====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCheckedOut
                    ? Colors.grey.shade200
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCheckedOut
                    ? 'Penyewa telah melakukan checkout.'
                    : 'Penyewa masih aktif menempati kamar.',
                style: TextStyle(
                  color: isCheckedOut ? Colors.black54 : Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // =====================
            // KONTAK DARURAT
            // =====================
            const Text(
              'Kontak Darurat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _infoTile(
              'Nama',
              currentTenant.emergencyName?.isNotEmpty == true
                  ? currentTenant.emergencyName!
                  : '-',
            ),
            _infoTile(
              'Telepon',
              currentTenant.emergencyPhone?.isNotEmpty == true
                  ? currentTenant.emergencyPhone!
                  : '-',
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // =====================
            // KTP PENYEWA
            // =====================
            const Text(
              'KTP Penyewa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            currentTenant.ktpUrl == null
                ? const Text('KTP belum diupload')
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      currentTenant.ktpUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // =====================
  // UTIL
  // =====================
  String _formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is String) return date;
    if (date is DateTime) {
      return '${date.day}-${date.month}-${date.year}';
    }
    return date.toString();
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 5, child: Text(value)),
        ],
      ),
    );
  }
}
