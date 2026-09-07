
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../domain/printer_service.dart';

class StandardPrinterService implements PrinterService {
  @override
  Future<bool> connect({String? printerAddress}) async {
    // For standard OS spoolers, connection is handled by the OS.
    return true;
  }

  @override
  Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice',
    );
  }

  @override
  Future<void> printEscPos(List<int> bytes) async {
    // Standard printer service cannot print raw ESC/POS commands unless we use Raw spooling.
    // In a real app, we might use a dedicated plugin to send raw bytes to a Windows printer spooler.
    // For now, this is unsupported in standard OS printing via 'printing' package.
    throw UnimplementedError(
        "ESC/POS raw printing not supported by StandardPrinterService.");
  }

  @override
  Future<void> disconnect() async {
    // Handled by OS
  }

  @override
  Future<void> showPrintPreview(Uint8List pdfBytes, String documentName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: documentName,
    );
  }
}

class NetworkThermalPrinterService implements PrinterService {
  // A real implementation would use dart:io Socket to connect to a network thermal printer
  // e.g. Socket.connect(ip, 9100)

  @override
  Future<bool> connect({String? printerAddress}) async {
    // Mock connection
    return true;
  }

  @override
  Future<void> printPdf(Uint8List pdfBytes) async {
    throw UnimplementedError(
        "Thermal printers do not natively support PDF bytes. Convert to image first.");
  }

  @override
  Future<void> printEscPos(List<int> bytes) async {
    // Mock sending bytes via socket
    debugPrint("Sending ${bytes.length} bytes to thermal printer...");
  }

  @override
  Future<void> disconnect() async {
    // Mock disconnect
  }

  @override
  Future<void> showPrintPreview(Uint8List pdfBytes, String documentName) async {
    // Thermal printers don't do PDF preview directly in this mode.
    throw UnimplementedError(
        "Preview not supported for ESC/POS mode directly.");
  }
}
