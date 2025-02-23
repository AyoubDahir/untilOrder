import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cashier Copy
                  _buildReceiptContent(
                    context: context,
                    orderReference: orderReference,
                    orderItems: orderItems,
                    cashierName: cashierName,
                    subtotal: subtotal,
                    tax: tax,
                    total: total,
                    isKitchenCopy: false,
                  ),
                  const SizedBox(height: 10),
                  // Cutting Line
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        const Text(
                          '- Cut Here -',
                          style: TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '- - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                          style: TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Kitchen Copy
                  _buildReceiptContent(
                    context: context,
                    orderReference: orderReference,
                    orderItems: orderItems,
                    cashierName: cashierName,
                    subtotal: subtotal,
                    tax: tax,
                    total: total,
                    isKitchenCopy: true,
                  ),
                  const SizedBox(height: 10),
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
        ),
      );
    }
  }

  static Widget _buildReceiptContent({
    required BuildContext context,
    required String orderReference,
    required List<Map<String, dynamic>> orderItems,
    required String cashierName,
    required double subtotal,
    required double tax,
    required double total,
    required bool isKitchenCopy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo Image
        const SizedBox(height: 20), 
        Container(
          height: 100,
          width: 200,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/ng.jpg',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
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
        // Address and Contact (only for cashier copy)
        if (!isKitchenCopy)
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
                  'Ph: Premier Wallet ID:683960',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Email: info@nagaadhalls.com',
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
        const SizedBox(height: 18),
        // Order Items Table
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Product',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Qty',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!isKitchenCopy)
                    Expanded(
                      child: Text(
                        'Rate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (!isKitchenCopy)
                    Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
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
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['quantity'].toString(),
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!isKitchenCopy)
                    Expanded(
                      child: Text(
                        '\$${item['price'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (!isKitchenCopy)
                    Expanded(
                      child: Text(
                        '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              )),
              const Divider(),
              if (!isKitchenCopy) ...[
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
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (!isKitchenCopy)
          const Text(
            'Thank you for dining with us!',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  static Future<pw.Document> buildPdf(
    String orderReference,
    List<Map<String, dynamic>> orderItems,
    double total,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Order $orderReference'),
              pw.Divider(),
              ...orderItems.map((item) => pw.Row(
                children: [
                  pw.Text(item['name'].toString()),
                  pw.Spacer(),
                  pw.Text('\$${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                ],
              )),
              pw.Divider(),
              pw.Row(
                children: [
                  pw.Text('Total:'),
                  pw.Spacer(),
                  pw.Text('\$${total.toStringAsFixed(2)}'),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}