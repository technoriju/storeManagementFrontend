import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart'; // To get SyncMixin

const uuid = Uuid();

@DataClassName('Category')
class Categories extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
}

@DataClassName('SubCategory')
class SubCategories extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
}

@DataClassName('Brand')
class Brands extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
}

@DataClassName('Unit')
class Units extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text()();
  TextColumn get shortName => text()();
}

@DataClassName('TaxRate')
class TaxRates extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text()();
  RealColumn get cgstRate => real()();
  RealColumn get sgstRate => real()();
  RealColumn get igstRate => real()();
}

@DataClassName('Product')
@TableIndex(name: 'product_search_idx', columns: {#name, #barcode})
class Products extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get subCategoryId =>
      text().nullable().references(SubCategories, #id)();
  TextColumn get brandId => text().nullable().references(Brands, #id)();
  TextColumn get taxRateId => text().nullable().references(TaxRates, #id)();
  TextColumn get baseUnitId => text().references(Units, #id)();
  TextColumn get defaultPurchaseUnitId => text().nullable()();
  TextColumn get defaultSalesUnitId => text().nullable()();

  TextColumn get name => text()();
  TextColumn get productCode => text().unique()();
  TextColumn get sku => text().unique()();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get description => text().nullable()();
  TextColumn get hsnCode => text().nullable()();

  TextColumn get taxType =>
      text().withDefault(const Constant('GST'))(); // GST or NON_GST
  BoolColumn get isPriceInclusive =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  BoolColumn get batchTracking =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get expiryTracking =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get serialTracking =>
      boolean().withDefault(const Constant(false))();

  RealColumn get lowStockLevel => real().nullable()();
  RealColumn get reorderLevel => real().nullable()();
}

@DataClassName('ProductUnit')
class ProductUnits extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get productId => text().references(Products, #id)();
  TextColumn get unitId => text().references(Units, #id)();
  RealColumn get conversionFactor => real()();
  @override
  List<String> get customConstraints => ['UNIQUE(product_id, unit_id)'];
}

@DataClassName('ProductPrice')
class ProductPrices extends Table with SyncMixin {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get productId => text().references(Products, #id)();
  TextColumn get productUnitId => text().references(ProductUnits, #id)();
  TextColumn get priceType => text()(); // PURCHASE, WHOLESALE, RETAIL, MRP
  RealColumn get price => real()();

  @override
  List<String> get customConstraints =>
      ['UNIQUE(product_id, product_unit_id, price_type)'];
}

@DataClassName('SyncQueue')
class SyncQueues extends Table {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text().clientDefault(() => uuid.v4())();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // CREATE, UPDATE, DELETE
  TextColumn get payload => text()(); // JSON representation of the entity
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(
      const Constant('PENDING'))(); // PENDING, SYNCING, FAILED, COMPLETED
  TextColumn get lastError => text().nullable()();
  TextColumn get deviceId => text()();
}
