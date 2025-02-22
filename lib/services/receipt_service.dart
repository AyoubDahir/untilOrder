import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../widgets/thermal_receipt.dart';

class ReceiptService {
  static Future<Uint8List> generateReceiptPdf({
    required List<OrderItem> orderItems,
    required String cashierName,
    required String orderReference,
    required double subtotal,
    required double tax,
    required double total,
  }) async {
    final pdf = pw.Document();
    
    pw.MemoryImage? logoImage;
    try {
      // Load the logo image
      final ByteData logoBytes = await rootBundle.load('assets/images/nguat.jpeg');
      final Uint8List logoData = logoBytes.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoData);
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm, // 80mm width
          double.infinity, // Auto height
          marginLeft: 2 * PdfPageFormat.mm,
          marginRight: 2 * PdfPageFormat.mm,
          marginTop: 2 * PdfPageFormat.mm,
          marginBottom: 8 * PdfPageFormat.mm,
        ),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo and Header
              if (logoImage != null) ...[
                pw.Image(logoImage, width: 40, height: 40),
                pw.SizedBox(height: 2),
              ],
              pw.Text('NGUAT RESTAURANT',
                  style: pw.TextStyle(fontSize: 10, font: pw.Font.helveticaBold())),
              pw.Text('Tel: +252 61 XXX XXXX',
                  style: pw.TextStyle(fontSize: 8)),
              pw.Text('CASHIER COPY',
                  style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold())),
              pw.SizedBox(height: 2),
              
              // Order Info
              pw.Text('Order: $orderReference',
                  style: pw.TextStyle(fontSize: 8)),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 8)),
              pw.Divider(thickness: 0.5),
              
              // Items Header
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('Item',
                        style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold())),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('Qty',
                        style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold()),
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Price',
                        style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold()),
                        textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Total',
                        style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold()),
                        textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5),
              
              // Items
              pw.Container(
                child: pw.Column(
                  children: orderItems.map((item) {
                    final total = item.price * item.quantity;
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(item.name,
                                style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text('${item.quantity}',
                                style: pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('\$${item.price.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.right),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('\$${total.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: ',
                      style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold())),
                  pw.Text('\$${subtotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Tax (5%): ',
                      style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold())),
                  pw.Text('\$${tax.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total: ',
                      style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold())),
                  pw.Text('\$${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 8)),
                ],
              ),
              
              pw.SizedBox(height: 4),
              pw.Text('Thank you for your business!',
                  style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold())),
              pw.Text('Cashier: $cashierName',
                  style: pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }
}
