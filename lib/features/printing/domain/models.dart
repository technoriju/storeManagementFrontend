import 'dart:typed_data';

class StoreConfig {
  final Uint8List? logoBytes;
  final String businessName;
  final String address;
  final String phone;
  final String gstin;
  final String invoiceHeader;
  final String footer;
  final String terms;
  final Uint8List? signatureBytes;

  const StoreConfig({
    this.logoBytes,
    required this.businessName,
    required this.address,
    required this.phone,
    required this.gstin,
    required this.invoiceHeader,
    required this.footer,
    required this.terms,
    this.signatureBytes,
  });
}

class InvoiceData {
  final String invoiceNumber;
  final DateTime date;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerGstin;

  final List<InvoiceItemData> items;
  final double subtotal;
  final double discount;
  final double taxAmount;
  final double totalAmount;
  
  // Tax breakdown (from tax engine)
  final bool isGstInvoice;
  final bool isInclusiveTax;
  
  final List<PaymentDetailData> payments;

  const InvoiceData({
    required this.invoiceNumber,
    required this.date,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerGstin,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.taxAmount,
    required this.totalAmount,
    required this.isGstInvoice,
    required this.isInclusiveTax,
    required this.payments,
  });
}

class InvoiceItemData {
  final String name;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String? hsn;

  const InvoiceItemData({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    this.hsn,
  });
}

class PaymentDetailData {
  final String method;
  final double amount;
  final String? transactionId;

  const PaymentDetailData({
    required this.method,
    required this.amount,
    this.transactionId,
  });
}
