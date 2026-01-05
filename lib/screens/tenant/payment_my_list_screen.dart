import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/payment_provider.dart';

class PaymentMyListScreen extends StatefulWidget {
  const PaymentMyListScreen({super.key});

  @override
  State<PaymentMyListScreen> createState() => _PaymentMyListScreenState();
}

class _PaymentMyListScreenState extends State<PaymentMyListScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<PaymentProvider>().fetchMyPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentProv = context.watch<PaymentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Saya')),
      body: paymentProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentProv.payments.isEmpty
          ? const Center(child: Text('Belum ada data pembayaran'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: paymentProv.payments.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> p = paymentProv.payments[index];

                final bool isPaid = p['status'] == 'paid';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      isPaid ? Icons.check_circle : Icons.schedule,
                      color: isPaid ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      'Bulan ${p['month']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(p['amount']),
                        ),
                        const SizedBox(height: 4),
                        Text('Status: ${isPaid ? 'Lunas' : 'Belum Lunas'}'),
                        if (p['paid_date'] != null)
                          Text(
                            'Dibayar: ${_formatDate(p['paid_date'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is String) return date;
    if (date is DateTime) {
      return '${date.day}-${date.month}-${date.year}';
    }
    return date.toString();
  }
}
