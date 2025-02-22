import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PrinterService {
  static const double THERMAL_PAPER_WIDTH = 80 * PdfPageFormat.mm;
  static const double MARGIN = 2 * PdfPageFormat.mm;

  // Get list of available printers
  static Future<List<Printer>> getAvailablePrinters() async {
    try {
      final printers = await Printing.listPrinters();
      // Filter for thermal printers if needed
      return printers.where((printer) {
        final name = printer.name.toLowerCase();
        return name.contains('thermal') || 
               name.contains('receipt') || 
               name.contains('pos') ||
               name.contains('cash');
      }).toList();
    } catch (e) {
      debugPrint('Error getting printers: $e');
      return [];
    }
  }

  // Print directly to a specific printer
  static Future<bool> printToPrinter(Printer printer, Uint8List bytes, String documentName) async {
    try {
      final result = await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => bytes,
        format: PdfPageFormat(
          THERMAL_PAPER_WIDTH,
          double.infinity,
          marginLeft: MARGIN,
          marginRight: MARGIN,
          marginTop: MARGIN,
          marginBottom: MARGIN * 4, // Extra margin at bottom for clean cut
        ),
        name: documentName,
        usePrinterSettings: true, // Use printer's default settings
      );
      return result;
    } catch (e) {
      debugPrint('Error printing to printer: $e');
      return false;
    }
  }
}
