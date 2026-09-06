import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/tax_engine.dart';
import 'package:frontend/features/billing/application/billing_service.dart';
import 'package:frontend/features/printing/application/default_template_engine.dart';
import 'package:frontend/features/printing/infrastructure/printer_service_impl.dart';

void main() {
  late BillingService billingService;

  setUp(() {
    billingService = BillingService(
      templateEngine: DefaultInvoiceTemplateEngine(),
      printerService: StandardPrinterService(),
    );
  });

  group('TaxEngine Tests', () {
    test('calculateTax - exclusive', () {
      final tax = TaxEngine.calculateTax(100.0, 18.0, isInclusive: false);
      expect(tax, 18.0);
    });

    test('calculateTax - inclusive', () {
      // Amount 118, Rate 18%, Tax should be 18
      final tax = TaxEngine.calculateTax(118.0, 18.0, isInclusive: true);
      expect(tax, closeTo(18.0, 0.001));
    });
  });

  group('BillingService Invoice Generation Tests', () {
    test('Generate GST Invoice (Exclusive)', () {
      final rawItems = [
        {'name': 'Item A', 'quantity': 2, 'unitPrice': 100, 'taxRate': 18}, // 200 + 36 tax = 236
        {'name': 'Item B', 'quantity': 1, 'unitPrice': 50, 'taxRate': 5},   // 50 + 2.5 tax = 52.5
      ];

      final invoice = billingService.generateInvoiceData(
        invoiceNumber: 'INV-100',
        date: DateTime.now(),
        rawItems: rawItems,
        isGstInvoice: true,
        isInclusiveTax: false,
      );

      expect(invoice.isGstInvoice, true);
      expect(invoice.subtotal, 250.0);
      expect(invoice.taxAmount, 38.5); // 36 + 2.5
      expect(invoice.totalAmount, 288.5);
    });

    test('Generate GST Invoice (Inclusive)', () {
      final rawItems = [
        {'name': 'Item A', 'quantity': 2, 'unitPrice': 118, 'taxRate': 18}, // 236 total, tax = 36, base = 200
      ];

      final invoice = billingService.generateInvoiceData(
        invoiceNumber: 'INV-101',
        date: DateTime.now(),
        rawItems: rawItems,
        isGstInvoice: true,
        isInclusiveTax: true,
      );

      expect(invoice.isGstInvoice, true);
      expect(invoice.subtotal, 236.0); // gross
      expect(invoice.taxAmount, closeTo(36.0, 0.001));
      expect(invoice.totalAmount, 236.0); // total is same as subtotal because inclusive
    });

    test('Generate Non-GST Invoice', () {
      final rawItems = [
        {'name': 'Item C', 'quantity': 5, 'unitPrice': 20, 'taxRate': 18}, // 100
      ];

      final invoice = billingService.generateInvoiceData(
        invoiceNumber: 'INV-102',
        date: DateTime.now(),
        rawItems: rawItems,
        isGstInvoice: false, // Override
        isInclusiveTax: false,
      );

      expect(invoice.isGstInvoice, false);
      expect(invoice.subtotal, 100.0);
      expect(invoice.taxAmount, 0.0);
      expect(invoice.totalAmount, 100.0);
    });
  });
}
