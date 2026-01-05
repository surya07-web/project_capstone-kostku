import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

Future<void> generatePaymentPdf({
  required List<Map<String, dynamic>> payments,
}) async {
  final pdf = pw.Document();

  int totalIncome = 0;
  for (final p in payments) {
    if (p['status'] == 'paid') {
      totalIncome += (p['amount'] as num).toInt();
    }
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'LAPORAN PEMBAYARAN KOST',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),

            pw.Table.fromTextArray(
              headers: ['Email', 'Kamar', 'Bulan', 'Jumlah', 'Status'],
              data: payments.map((p) {
                return [
                  p['user_email'],
                  p['room_number'],
                  p['month'],
                  'Rp ${p['amount']}',
                  p['status'],
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              'Total Pemasukan: Rp $totalIncome',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        );
      },
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/laporan_pembayaran.pdf');

  await file.writeAsBytes(await pdf.save());

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}
