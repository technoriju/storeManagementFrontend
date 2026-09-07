import 'dart:typed_data';

enum PrintPaperSize { mm58, mm80, a4, a5, custom }

abstract class PrinterService {
  /// Connects to a printer if necessary
  Future<bool> connect({String? printerAddress});

  /// Prints a PDF document (standard printers)
  Future<void> printPdf(Uint8List pdfBytes);

  /// Prints ESC/POS raw commands (thermal printers)
  Future<void> printEscPos(List<int> bytes);

  /// Disconnects the printer
  Future<void> disconnect();

  /// Show print preview (primarily for PDF)
  Future<void> showPrintPreview(Uint8List pdfBytes, String documentName);
}
