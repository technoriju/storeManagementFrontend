import 'package:drift/drift.dart';
import 'app_database.dart';

@DataClassName('Customer')
class Customers extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get gstin => text().nullable()();
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))();
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  IntColumn get paymentTerms => integer().nullable()(); // in days
}

@DataClassName('CustomerLedger')
class CustomerLedgers extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get customerId => text().references(Customers, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get referenceType => text()(); // Sale, Payment, Return, Opening
  TextColumn get referenceId => text()();
  RealColumn get debit => real().withDefault(const Constant(0.0))();
  RealColumn get credit => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
}

@DataClassName('PaymentMethod')
class PaymentMethods extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text()(); // Cash, Card, UPI, Bank Transfer, Other
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

@DataClassName('Payment')
class Payments extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get referenceType => text()(); // Sale, SaleReturn, CustomerPayment
  TextColumn get referenceId => text()();
  TextColumn get paymentMethodId => text().references(PaymentMethods, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get transactionId => text().nullable()(); // For UPI/Card
  TextColumn get notes => text().nullable()();
}

@DataClassName('Sale')
class Sales extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get invoiceNumber => text()();
  TextColumn get customerId => text().nullable().references(Customers, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
  RealColumn get amountPaid => real().withDefault(const Constant(0.0))();
  TextColumn get status => text()(); // Draft, Completed, Cancelled
  TextColumn get paymentStatus => text()(); // Unpaid, Partial, Paid
}

@DataClassName('SaleItem')
class SaleItems extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text()();
  TextColumn get unitId => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real()();
}

@DataClassName('SaleReturn')
class SaleReturns extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get returnNumber => text()();
  TextColumn get saleId => text().references(Sales, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get totalAmount => real()();
  TextColumn get reason => text().nullable()();
}

@DataClassName('SaleReturnItem')
class SaleReturnItems extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get returnId => text().references(SaleReturns, #id)();
  TextColumn get saleItemId => text().references(SaleItems, #id)();
  RealColumn get quantity => real()();
  RealColumn get refundAmount => real()();
}
