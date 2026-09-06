import 'dart:typed_data';

import '../../core/utils/tax_engine.dart';
import '../printing/domain/models.dart';
import '../printing/domain/printer_service.dart';
import '../printing/application/template_engine.dart';
import '../../core/database/app_database.dart'; // assuming Drift DB

class BillingService {
  final InvoiceTemplateEngine templateEngine;
  final PrinterService printerService;

  BillingService({
    required this.templateEngine,
    required this.printerService,
  });

  /// Generate an invoice from raw data, calculating taxes via TaxEngine
  InvoiceData generateInvoiceData({
    required String invoiceNumber,
    required DateTime date,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerGstin,
    required List<Map<String, dynamic>> rawItems,
    double discount = 0.0,
    bool isGstInvoice = true,
    bool isInclusiveTax = false,
    List<PaymentDetailData> payments = const [],
  }) {
    List<InvoiceItemData> items = [];
    double subtotal = 0;
    double totalTax = 0;

    for (var raw in rawItems) {
      final name = raw['name'] as String;
      final quantity = (raw['quantity'] as num).toDouble();
      final unitPrice = (raw['unitPrice'] as num).toDouble();
      final itemDiscount = (raw['discount'] as num?)?.toDouble() ?? 0.0;
      final taxRate = isGstInvoice ? ((raw['taxRate'] as num?)?.toDouble() ?? 0.0) : 0.0;
      final hsn = raw['hsn'] as String?;

      final grossAmount = (quantity * unitPrice) - itemDiscount;
      
      double taxAmount = 0;
      if (isGstInvoice) {
        taxAmount = TaxEngine.calculateTax(grossAmount, taxRate, isInclusive: isInclusiveTax);
      }

      final total = isInclusiveTax ? grossAmount : grossAmount + taxAmount;

      items.add(InvoiceItemData(
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
        discount: itemDiscount,
        taxRate: taxRate,
        taxAmount: taxAmount,
        total: total,
        hsn: hsn,
      ));

      subtotal += grossAmount;
      totalTax += taxAmount;
    }

    final totalAmount = isInclusiveTax ? subtotal - discount : subtotal + totalTax - discount;

    return InvoiceData(
      invoiceNumber: invoiceNumber,
      date: date,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerGstin: customerGstin,
      items: items,
      subtotal: subtotal,
      discount: discount,
      taxAmount: totalTax,
      totalAmount: totalAmount,
      isGstInvoice: isGstInvoice,
      isInclusiveTax: isInclusiveTax,
      payments: payments,
    );
  }

  /// Print standard invoice (A4, A5)
  Future<void> printStandardInvoice(InvoiceData invoice, StoreConfig config, {PrintPaperSize paperSize = PrintPaperSize.a4}) async {
    final pdfBytes = await templateEngine.generatePdf(invoice, config, paperSize);
    await printerService.printPdf(pdfBytes);
  }

  /// Print thermal invoice (58mm, 80mm)
  Future<void> printThermalInvoice(InvoiceData invoice, StoreConfig config, {PrintPaperSize paperSize = PrintPaperSize.mm80}) async {
    final bytes = await templateEngine.generateEscPos(invoice, config, paperSize);
    await printerService.printEscPos(bytes);
  }

  /// Preview Invoice PDF
  Future<void> previewInvoice(InvoiceData invoice, StoreConfig config, {PrintPaperSize paperSize = PrintPaperSize.a4}) async {
    final pdfBytes = await templateEngine.generatePdf(invoice, config, paperSize);
    await printerService.showPrintPreview(pdfBytes, 'Invoice_${invoice.invoiceNumber}');
  }
}
