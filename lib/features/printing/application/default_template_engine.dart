import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../domain/models.dart';
import '../domain/printer_service.dart';
import 'template_engine.dart';

class DefaultInvoiceTemplateEngine implements InvoiceTemplateEngine {
  @override
  Future<Uint8List> generatePdf(InvoiceData invoice, StoreConfig config, PrintPaperSize paperSize) async {
    final pdf = pw.Document();
    
    PdfPageFormat format;
    switch (paperSize) {
      case PrintPaperSize.a4:
        format = PdfPageFormat.a4;
        break;
      case PrintPaperSize.a5:
        format = PdfPageFormat.a5;
        break;
      case PrintPaperSize.mm80:
        format = PdfPageFormat.roll80;
        break;
      case PrintPaperSize.mm58:
        format = PdfPageFormat.roll57;
        break;
      default:
        format = PdfPageFormat.a4;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(config),
              pw.SizedBox(height: 10),
              _buildCustomerInfo(invoice),
              pw.SizedBox(height: 10),
              _buildInvoiceDetails(invoice),
              pw.SizedBox(height: 10),
              _buildItemsTable(invoice),
              pw.SizedBox(height: 10),
              _buildTotals(invoice),
              pw.SizedBox(height: 10),
              _buildPayments(invoice),
              pw.SizedBox(height: 20),
              _buildFooter(config, invoice),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(StoreConfig config) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (config.logoBytes != null)
          pw.Container(
            height: 60,
            child: pw.Image(pw.MemoryImage(config.logoBytes!)),
          ),
        pw.SizedBox(height: 5),
        pw.Text(config.businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text(config.address),
        pw.Text('Phone: ${config.phone}'),
        if (config.gstin.isNotEmpty) pw.Text('GSTIN: ${config.gstin}'),
        pw.SizedBox(height: 5),
        pw.Text(config.invoiceHeader, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(InvoiceData invoice) {
    if (invoice.customerName == null) return pw.SizedBox.shrink();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Customer: ${invoice.customerName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (invoice.customerPhone != null) pw.Text('Phone: ${invoice.customerPhone}'),
        if (invoice.customerAddress != null) pw.Text('Address: ${invoice.customerAddress}'),
        if (invoice.customerGstin != null) pw.Text('GSTIN: ${invoice.customerGstin}'),
      ],
    );
  }

  pw.Widget _buildInvoiceDetails(InvoiceData invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Invoice #: ${invoice.invoiceNumber}'),
        pw.Text('Date: ${invoice.date.toLocal().toString().split(' ')[0]}'),
      ],
    );
  }

  pw.Widget _buildItemsTable(InvoiceData invoice) {
    final headers = ['Item', 'Qty', 'Rate', 'Total'];
    if (invoice.isGstInvoice) {
      headers.insert(3, 'GST');
    }

    final data = invoice.items.map((item) {
      final row = [
        item.name,
        item.quantity.toStringAsFixed(2),
        item.unitPrice.toStringAsFixed(2),
        item.total.toStringAsFixed(2),
      ];
      if (invoice.isGstInvoice) {
        row.insert(3, item.taxAmount.toStringAsFixed(2));
      }
      return row;
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildTotals(InvoiceData invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('Subtotal: ${invoice.subtotal.toStringAsFixed(2)}'),
          if (invoice.discount > 0) pw.Text('Discount: ${invoice.discount.toStringAsFixed(2)}'),
          if (invoice.isGstInvoice) pw.Text('Tax (${invoice.isInclusiveTax ? 'Incl.' : 'Excl.'}): ${invoice.taxAmount.toStringAsFixed(2)}'),
          pw.Divider(),
          pw.Text('Total: ${invoice.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  pw.Widget _buildPayments(InvoiceData invoice) {
    if (invoice.payments.isEmpty) return pw.SizedBox.shrink();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Payments:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...invoice.payments.map((p) => pw.Text('${p.method}: ${p.amount.toStringAsFixed(2)}')),
      ],
    );
  }

  pw.Widget _buildFooter(StoreConfig config, InvoiceData invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (config.signatureBytes != null)
          pw.Container(
            height: 40,
            child: pw.Image(pw.MemoryImage(config.signatureBytes!)),
          ),
        pw.SizedBox(height: 10),
        pw.Text(config.terms, style: pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 10),
        pw.Text(config.footer, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.BarcodeWidget(
          color: PdfColor.fromHex("#000000"),
          barcode: pw.Barcode.code128(),
          data: invoice.invoiceNumber,
          height: 30,
          width: 150,
        ),
      ],
    );
  }

  @override
  Future<List<int>> generateEscPos(InvoiceData invoice, StoreConfig config, PrintPaperSize paperSize) async {
    final profile = await CapabilityProfile.load();
    final paper = paperSize == PrintPaperSize.mm80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);
    
    List<int> bytes = [];

    bytes += generator.text(config.businessName, styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(config.address, styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Phone: ${config.phone}', styles: PosStyles(align: PosAlign.center));
    if (config.gstin.isNotEmpty) {
      bytes += generator.text('GSTIN: ${config.gstin}', styles: PosStyles(align: PosAlign.center));
    }
    bytes += generator.text(config.invoiceHeader, styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.emptyLines(1);

    if (invoice.customerName != null) {
      bytes += generator.text('Customer: ${invoice.customerName}');
      if (invoice.customerPhone != null) bytes += generator.text('Phone: ${invoice.customerPhone}');
      if (invoice.customerGstin != null) bytes += generator.text('GSTIN: ${invoice.customerGstin}');
      bytes += generator.emptyLines(1);
    }

    bytes += generator.text('Invoice #: ${invoice.invoiceNumber}');
    bytes += generator.text('Date: ${invoice.date.toLocal().toString().split(' ')[0]}');
    bytes += generator.emptyLines(1);

    // Items table (simple representation for thermal)
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6, styles: PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(text: 'Rate', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(text: 'Total', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr();

    for (final item in invoice.items) {
      bytes += generator.row([
        PosColumn(text: item.name, width: 6),
        PosColumn(text: item.quantity.toStringAsFixed(1), width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: item.unitPrice.toStringAsFixed(2), width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: item.total.toStringAsFixed(2), width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 8, styles: PosStyles(align: PosAlign.right)),
      PosColumn(text: invoice.subtotal.toStringAsFixed(2), width: 4, styles: PosStyles(align: PosAlign.right)),
    ]);
    if (invoice.discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: invoice.discount.toStringAsFixed(2), width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
    }
    if (invoice.isGstInvoice) {
      bytes += generator.row([
        PosColumn(text: 'Tax:', width: 8, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: invoice.taxAmount.toStringAsFixed(2), width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'Total:', width: 8, styles: PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: invoice.totalAmount.toStringAsFixed(2), width: 4, styles: PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.emptyLines(1);

    for (final p in invoice.payments) {
      bytes += generator.text('${p.method}: ${p.amount.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.right));
    }

    bytes += generator.emptyLines(1);
    bytes += generator.text(config.terms, styles: PosStyles(align: PosAlign.center));
    bytes += generator.text(config.footer, styles: PosStyles(align: PosAlign.center, bold: true));
    
    bytes += generator.emptyLines(1);
    
    // Convert invoice string to barcode bytes (Code128)
    // Note: Esc/Pos plugin might have barcode generation
    try {
      final List<int> barcodeData = invoice.invoiceNumber.codeUnits;
      bytes += generator.barcode(Barcode.code128(barcodeData));
    } catch (e) {
      // In case the barcode format is not supported or needs specific encoding
    }
    
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
