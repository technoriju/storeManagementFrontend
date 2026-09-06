import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables.dart';

@DataClassName('Warehouse')
class Warehouses extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get name => text()();
  TextColumn get location => text().nullable()();
}

@DataClassName('StockTransaction')
class StockTransactions extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get warehouseId => text().references(Warehouses, #id)();
  TextColumn get transactionType => text()(); // OPENING, PURCHASE, SALE, RETURN, ADJUSTMENT, TRANSFER
  TextColumn get referenceId => text()(); // Purchase ID, Sale ID, etc.
  
  TextColumn get unitId => text().references(Units, #id)();
  RealColumn get unitQuantity => real()();
  RealColumn get baseQuantity => real()();
}

@DataClassName('StockBalance')
class StockBalances extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get warehouseId => text().references(Warehouses, #id)();
  RealColumn get quantity => real()(); // Always in base unit

  @override
  List<String> get customConstraints => [
    'UNIQUE (product_id, warehouse_id)'
  ];
}
