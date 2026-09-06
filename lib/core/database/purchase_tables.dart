import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables.dart';

@DataClassName('Supplier')
class Suppliers extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get name => text()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get gstin => text().nullable()();
}

@DataClassName('Purchase')
class Purchases extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get invoiceNumber => text()();
  DateTimeColumn get purchaseDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('COMPLETED'))();
  
  RealColumn get subTotal => real()();
  RealColumn get taxTotal => real()();
  RealColumn get discountTotal => real()();
  RealColumn get otherCharges => real().withDefault(const Constant(0))();
  RealColumn get grandTotal => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get dueAmount => real().withDefault(const Constant(0))();
}

@DataClassName('PurchaseItem')
class PurchaseItems extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get purchaseId => text().references(Purchases, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get productUnitId => text().references(ProductUnits, #id)();
  
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get discount => real()();
  RealColumn get taxAmount => real()();
  RealColumn get total => real()();
}

@DataClassName('PurchaseReturn')
class PurchaseReturns extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get purchaseId => text().references(Purchases, #id)();
  DateTimeColumn get returnDate => dateTime()();
  TextColumn get reason => text().nullable()();
  RealColumn get totalAmount => real()();
}
