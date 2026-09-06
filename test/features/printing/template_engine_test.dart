import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/printing/application/default_template_engine.dart';
import 'package:frontend/features/printing/domain/models.dart';
import 'package:frontend/features/printing/domain/printer_service.dart';

void main() {
  late DefaultInvoiceTemplateEngine engine;
  late StoreConfig storeConfig;
  late InvoiceData gstInvoice;
  late InvoiceData nonGstInvoice;

  setUp(() {
    engine = DefaultInvoiceTemplateEngine();

    storeConfig = const StoreConfig(
      businessName: 'Super Store',
      address: '123 Main St, City',
      phone: '1234567890',
      gstin: '22AAAAA0000A1Z5',
      invoiceHeader: 'TAX INVOICE',
      footer: 'Thank you for your business!',
      terms: 'Terms and Conditions Apply.',
    );

    final longProductName = 'Super Deluxe Very Long Product Name With Multiple Words Extender Extra';

    gstInvoice = InvoiceData(
      invoiceNumber: 'INV-001',
      date: DateTime.now(),
      customerName: 'John Doe',
      customerPhone: '9876543210',
      items: [
        InvoiceItemData(
          name: longProductName,
          quantity: 2,
          unitPrice: 100,
          discount: 10,
          taxRate: 18,
          taxAmount: 34.2, // (200 - 10) * 0.18
          total: 224.2,
        ),
        InvoiceItemData(
          name: 'Item 2',
          quantity: 1,
          unitPrice: 50,
          discount: 0,
          taxRate: 5,
          taxAmount: 2.5,
          total: 52.5,
        ),
      ],
      subtotal: 250.0,
      discount: 10.0,
      taxAmount: 36.7,
      totalAmount: 276.7,
      isGstInvoice: true,
      isInclusiveTax: false,
      payments: [
        PaymentDetailData(method: 'UPI', amount: 276.7, transactionId: 'TXN123'),
      ],
    );

    nonGstInvoice = InvoiceData(
      invoiceNumber: 'INV-002',
      date: DateTime.now(),
      customerName: 'Jane Smith',
      items: [
        InvoiceItemData(
          name: 'Item 3',
          quantity: 3,
          unitPrice: 20,
          discount: 0,
          taxRate: 0,
          taxAmount: 0,
          total: 60,
        ),
      ],
      subtotal: 60.0,
      discount: 0.0,
      taxAmount: 0.0,
      totalAmount: 60.0,
      isGstInvoice: false,
      isInclusiveTax: false,
      payments: [
        PaymentDetailData(method: 'Cash', amount: 60.0),
      ],
    );
  });

  group('InvoiceTemplateEngine PDF Tests', () {
    test('A4 layout - GST Invoice', () async {
      final pdfBytes = await engine.generatePdf(gstInvoice, storeConfig, PrintPaperSize.a4);
      expect(pdfBytes.isNotEmpty, true);
    });

    test('A4 layout - Non-GST Invoice', () async {
      final pdfBytes = await engine.generatePdf(nonGstInvoice, storeConfig, PrintPaperSize.a4);
      expect(pdfBytes.isNotEmpty, true);
    });

    test('80mm layout - GST Invoice', () async {
      final pdfBytes = await engine.generatePdf(gstInvoice, storeConfig, PrintPaperSize.mm80);
      expect(pdfBytes.isNotEmpty, true);
    });

    test('58mm layout - GST Invoice', () async {
      final pdfBytes = await engine.generatePdf(gstInvoice, storeConfig, PrintPaperSize.mm58);
      expect(pdfBytes.isNotEmpty, true);
    });
  });

  group('InvoiceTemplateEngine ESC/POS Tests', () {
    test('80mm ESC/POS layout', () async {
      final escPosBytes = await engine.generateEscPos(gstInvoice, storeConfig, PrintPaperSize.mm80);
      expect(escPosBytes.isNotEmpty, true);
    });

    test('58mm ESC/POS layout', () async {
      final escPosBytes = await engine.generateEscPos(gstInvoice, storeConfig, PrintPaperSize.mm58);
      expect(escPosBytes.isNotEmpty, true);
    });
  });
}
