import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_item.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ReceiptWidget {
  static Future<void> showReceiptDialog({
    required BuildContext context,
    required String orderReference,
    required List<Map<String, dynamic>> orderItems,
    required String cashierName,
    required double subtotal,
    required double tax,
    required double total,
  }) async {
    final pdf = await buildPdf(orderReference, orderItems, total);
    final bytes = await pdf.save();

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: Container(
            width: 350,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo Image
                        Container(
                          height: 60,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/ng.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox.shrink(); // Hide if image fails to load
                            },
                          ),
                        ),
                        // Date and Order Number
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('MM/dd/yyyy HH:mm:ss').format(DateTime.now()),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Order $orderReference',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Address and Contact
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Text(
                                'Airport Road Km4, Mogadishu Somalia',
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Ph: Premier Wallet ID:683960 Email: Edahab',
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Cashier Info
                        Text(
                          'Served by $cashierName',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'CASHIER COPY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Order Items Table
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Product',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Qty',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Rate',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Total',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              ...orderItems.map((item) => Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item['name'].toString(),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item['quantity'].toString(),
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '\$${item['price'].toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              )),
                              const Divider(),
                              // Totals
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:'),
                                  Text('\$${subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tax (5%):'),
                                  Text('\$${tax.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '\$${total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Thank you for dining with us!',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Follow us on social media @ndesoo',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'REPRINT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.print, color: Colors.white),
                          label: const Text('Print', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            await Printing.layoutPdf(
                              onLayout: (_) => bytes,
                              format: PdfPageFormat.roll80,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text('Download', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final directory = await getApplicationDocumentsDirectory();
                            final file = File('${directory.path}/receipt_$orderReference.pdf');
                            await file.writeAsBytes(bytes);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Receipt saved to ${file.path}'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  static Future<pw.Document> buildPdf(String orderId, List<Map<String, dynamic>> items, double total) async {
    final pdf = pw.Document();
    
    try {
      final ByteData logoBytes = await rootBundle.load('assets/images/ng.jpg');
      final Uint8List logoUint8List = logoBytes.buffer.asUint8List();
      final pw.ImageProvider logo = pw.MemoryImage(logoUint8List);

      // Helper function to build receipt content
      pw.Widget buildReceiptContent({required bool isKitchenCopy, required double subtotal, required double tax}) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Date and Order number
            pw.Text(
              DateFormat('MM/dd/yyyy HH:mm:ss').format(DateTime.now()),
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Order $orderId',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 10),

            // Logo
            pw.Image(logo, width: 100, height: 50),
            pw.SizedBox(height: 10),

            // Address and contact info (only for cashier copy)
            if (!isKitchenCopy) ...[
              pw.Text(
                'Airport Road Km4, Mogadishu Somalia',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Ph: Premier Wallet ID:683960 Email: Edahab',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                '*1234*0702311*5#',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 10),
            ],

            // Copy type indicator
            pw.Text(
              isKitchenCopy ? 'KITCHEN COPY' : 'CASHIER COPY',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Order items
            ...items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      item['name'],
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    '\$${item['price'].toStringAsFixed(2)} × ${item['quantity']}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            )).toList(),
            
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 5),

            // Subtotal
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Subtotal:',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),

            // Tax
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Tax (5%):',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '\$${tax.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),

            // Total
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        );
      }

      // Calculate subtotal and tax
      double subtotal = items.fold(0.0, (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int));
      double tax = subtotal * 0.05; // 5% tax rate

      // Add page with both copies
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) {
            return pw.Column(
              children: [
                // Cashier copy
                buildReceiptContent(isKitchenCopy: false, subtotal: subtotal, tax: tax),
                pw.SizedBox(height: 20),

                // Cutting line
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '- Cut Here -',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '- - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Kitchen copy
                buildReceiptContent(isKitchenCopy: true, subtotal: subtotal, tax: tax),
              ],
            );
          },
        ),
      );

      return pdf;
    } catch (e) {
      print('Error generating receipt: $e');
      throw Exception('Failed to generate receipt: $e');
    }
  }
}
