import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/payment_provider.dart';
import '../../utils/payment_pdf.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  static const Color blue = Color(0xFF2F6FED);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<PaymentProvider>().fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PaymentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // =====================
      // APP BAR
      // =====================
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        title: const Text('Pembayaran'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: prov.payments.isEmpty
                ? null
                : () async {
                    final pdfData = prov.payments.map((p) {
                      final tenant = p['tenants'];
                      return {
                        'user_email': tenant?['user_email'] ?? '-',
                        'room_number': tenant?['rooms']?['number'] ?? '-',
                        'month': p['month'],
                        'amount': p['amount'],
                        'status': p['status'],
                      };
                    }).toList();

                    await generatePaymentPdf(payments: pdfData);
                  },
          ),
        ],
      ),

      // =====================
      // BODY
      // =====================
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.payments.isEmpty
          ? const Center(child: Text('Belum ada pembayaran'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prov.payments.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> p = prov.payments[index];
                final bool isPaid = p['status'] == 'paid';

                final tenant = p['tenants'];
                final roomNumber = tenant?['rooms']?['number'] ?? '-';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =====================
                      // ICON
                      // =====================
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isPaid
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        child: Icon(
                          Icons.payments,
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // =====================
                      // INFO
                      // =====================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant?['user_email'] ?? '-',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kamar $roomNumber • ${p['month']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${(p['amount'] as num).toInt()}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =====================
                      // STATUS / ACTION
                      // =====================
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPaid ? 'LUNAS' : 'BELUM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPaid ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!isPaid)
                            SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: blue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  await prov.markAsPaid(p['id']);
                                },
                                child: const Text(
                                  'Tandai',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
