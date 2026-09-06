import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'connection/connection.dart';

import 'tables.dart';

import 'purchase_tables.dart';
import 'inventory_tables.dart';
import 'sales_tables.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

const uuid = Uuid();

mixin SyncMixin on Table {
  TextColumn get id => text().clientDefault(() => uuid.v4())();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
}

@DataClassName('DummyEntry')
class DummyEntries extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text()();
}

@DriftDatabase(tables: [
  DummyEntries,
  Categories,
  SubCategories,
  Brands,
  Units,
  TaxRates,
  Products,
  ProductUnits,
  ProductPrices,
  SyncQueues,
  Suppliers,
  Purchases,
  PurchaseItems,
  PurchaseReturns,
  Warehouses,
  StockTransactions,
  StockBalances,
  Customers,
  CustomerLedgers,
  PaymentMethods,
  Payments,
  Sales,
  SaleItems,
  SaleReturns,
  SaleReturnItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Implement migrations here
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
