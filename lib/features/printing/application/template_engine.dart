import 'dart:typed_data';
import '../domain/models.dart';
import '../domain/printer_service.dart';

abstract class InvoiceTemplateEngine {
  /// Generates PDF bytes for standard printing (A4, A5, Custom PDF)
  Future<Uint8List> generatePdf(
      InvoiceData invoice, StoreConfig config, PrintPaperSize paperSize);

  /// Generates ESC/POS bytes for thermal printing (58mm, 80mm)
  Future<List<int>> generateEscPos(
      InvoiceData invoice, StoreConfig config, PrintPaperSize paperSize);
}
