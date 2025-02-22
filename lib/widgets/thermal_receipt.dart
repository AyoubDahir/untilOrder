import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../models/order_item.dart';
import '../services/printer_service.dart';

class ThermalReceipt extends StatefulWidget {
  static const double RECEIPT_WIDTH = 300.0;

  final List<OrderItem> orderItems;
  final String cashierName;
  final String orderReference;
  final double subtotal;
  final double tax;
  final double total;

  const ThermalReceipt({
    Key? key,
    required this.orderItems,
    required this.cashierName,
    required this.orderReference,
    required this.subtotal,
    required this.tax,
    required this.total,
  }) : super(key: key);

  @override
  State<ThermalReceipt> createState() => _ThermalReceiptState();
}

class _ThermalReceiptState extends State<ThermalReceipt> {
  bool _isLoading = false;

  Future<Uint8List> _generatePdfContent() async {
    final pdf = pw.Document();

    // Common header content
    final headerContent = [
      pw.Center(child: pw.Text('Nagaad Cafe', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
      pw.Center(child: pw.Text('Airport Road Km4, Mogadishu')),
      pw.Center(child: pw.Text('Somalia')),
      pw.SizedBox(height: 10),
      pw.Center(child: pw.Text('Premier Wallet ID: 683960')),
      pw.Center(child: pw.Text('Email: info@nagaad.com')),
      pw.SizedBox(height: 10),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
          pw.Text('Order Ref: ${widget.orderReference}'),
        ],
      ),
      pw.Text('Served by: ${widget.cashierName}'),
      pw.SizedBox(height: 10),
      pw.Divider(),
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm, // 80mm width
          double.infinity, // Height will adjust to content
          marginLeft: 2 * PdfPageFormat.mm,
          marginRight: 2 * PdfPageFormat.mm,
          marginTop: 2 * PdfPageFormat.mm,
          marginBottom: 2 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cashier Copy
              ...headerContent,
              pw.Center(
                child: pw.Text(
                  'CASHIER COPY',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              // Column headers
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item')),
                  pw.Expanded(child: pw.Text('Qty', textAlign: pw.TextAlign.right)),
                  pw.Expanded(child: pw.Text('Price', textAlign: pw.TextAlign.right)),
                  pw.Expanded(child: pw.Text('Total', textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Divider(),
              // Items
              ...widget.orderItems.map((item) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.name)),
                      pw.Expanded(child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.right)),
                      pw.Expanded(child: pw.Text('\$${item.price.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                      pw.Expanded(child: pw.Text('\$${item.total.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                ],
              )),
              pw.Divider(),
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text('\$${widget.subtotal.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax (5%):'),
                  pw.Text('\$${widget.tax.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${widget.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for your business!')),
              
              // Cutting line between copies
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Container(
                  width: 70 * PdfPageFormat.mm,
                  child: pw.Stack(
                    children: [
                      pw.Divider(thickness: 1, style: pw.BorderStyle.dashed),
                      pw.Center(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                          color: PdfColors.white,
                          child: pw.Text('✂ Cut Here ✂', style: pw.TextStyle(fontSize: 8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Kitchen Copy
              ...headerContent,
              pw.Center(
                child: pw.Text(
                  'KITCHEN COPY',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              // Column headers for kitchen (simplified)
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item')),
                  pw.Expanded(child: pw.Text('Qty', textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Divider(),
              // Items (simplified for kitchen)
              ...widget.orderItems.map((item) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                ],
              )),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('*** End of Kitchen Order ***')),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _handlePrint(BuildContext context) async {
    try {
      setState(() => _isLoading = true);

      // Get available printers
      final printers = await PrinterService.getAvailablePrinters();
      if (printers.isEmpty) {
        throw Exception('No thermal printers found');
      }

      // Generate receipt
      final pdfData = await _generatePdfContent();

      // Print receipt
      final success = await PrinterService.printToPrinter(
        printers.first,
        pdfData,
        'Order ${widget.orderReference}',
      );

      if (!success) {
        throw Exception('Failed to print receipt');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt printed successfully')),
      );
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing receipt: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 600,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<Uint8List>(
              future: _generatePdfContent(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No receipt data'));
                }

                return PdfPreview(
                  build: (format) => snapshot.data!,
                  initialPageFormat: PdfPageFormat(
                    80 * PdfPageFormat.mm,
                    double.infinity,
                    marginLeft: 2 * PdfPageFormat.mm,
                    marginRight: 2 * PdfPageFormat.mm,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _isLoading ? null : () => _handlePrint(context),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _isLoading
                    ? null
                    : () async {
                        try {
                          final pdfData = await _generatePdfContent();
                          await Printing.sharePdf(
                            bytes: pdfData,
                            filename: 'Receipt_${widget.orderReference}.pdf',
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error downloading: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}