import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';

final localInventoryRepositoryProvider = Provider((ref) {
  return LocalInventoryRepository(ref.read(appDatabaseProvider));
});

class LocalInventoryRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  LocalInventoryRepository(this._db);

  Future<void> importProducts(List<Map<String, dynamic>> productsData) async {
    await _db.transaction(() async {
      for (final row in productsData) {
        final productId = _uuid.v4();

        // Ensure Category exists or create it
        String? categoryId;
        if (row['Category'] != null &&
            row['Category'].toString().trim().isNotEmpty) {
          final catName = row['Category'].toString().trim();
          final cat = await (_db.select(_db.categories)
                ..where((t) => t.name.equals(catName)))
              .getSingleOrNull();
          if (cat == null) {
            categoryId = _uuid.v4();
            await _db.into(_db.categories).insert(
                CategoriesCompanion.insert(id: Value(categoryId), name: catName));
          } else {
            categoryId = cat.id;
          }
        }

        // Similar logic for Sub Category and Brand
        String? subCategoryId;
        if (row['Sub Category'] != null &&
            row['Sub Category'].toString().trim().isNotEmpty) {
          final subCatName = row['Sub Category'].toString().trim();
          final subCat = await (_db.select(_db.subCategories)
                ..where((t) => t.name.equals(subCatName)))
              .getSingleOrNull();
          if (subCat == null) {
            subCategoryId = _uuid.v4();
            await _db.into(_db.subCategories).insert(
                SubCategoriesCompanion.insert(
                    id: Value(subCategoryId),
                    categoryId: categoryId ?? '',
                    name: subCatName));
          } else {
            subCategoryId = subCat.id;
          }
        }

        String? brandId;
        if (row['Brand'] != null && row['Brand'].toString().trim().isNotEmpty) {
          final brandName = row['Brand'].toString().trim();
          final brand = await (_db.select(_db.brands)
                ..where((t) => t.name.equals(brandName)))
              .getSingleOrNull();
          if (brand == null) {
            brandId = _uuid.v4();
            await _db
                .into(_db.brands)
                .insert(BrandsCompanion.insert(id: Value(brandId), name: brandName));
          } else {
            brandId = brand.id;
          }
        }

        // Unit logic
        String unitName = row['Unit']?.toString().trim() ?? 'PCS';
        final unit = await (_db.select(_db.units)
              ..where((t) => t.name.equals(unitName)))
            .getSingleOrNull();
        String unitId = unit?.id ?? _uuid.v4();
        if (unit == null) {
          await _db.into(_db.units).insert(UnitsCompanion.insert(
              id: Value(unitId), name: unitName, shortName: unitName));
        }

        final productCode = row['Product Code']?.toString() ?? _uuid.v4();

        final existingProduct = await (_db.select(_db.products)
              ..where((t) => t.productCode.equals(productCode)))
            .getSingleOrNull();
        if (existingProduct != null) {
          // Skip if product code already exists
          continue;
        }

        final skuStr = row['SKU']?.toString() ?? productCode;
        final existingSku = await (_db.select(_db.products)
              ..where((t) => t.sku.equals(skuStr)))
            .getSingleOrNull();
        if (existingSku != null) {
          continue;
        }

        final productCompanion = ProductsCompanion.insert(
          id: Value(productId),
          name: row['Product Name'].toString(),
          productCode: productCode,
          sku: skuStr,
          barcode: Value(row['Barcode']?.toString()),
          description: Value(row['Description']?.toString()),
          categoryId: Value(categoryId),
          subCategoryId: Value(subCategoryId),
          brandId: Value(brandId),
          baseUnitId: unitId,
          hsnCode: Value(row['HSN Code']?.toString()),
          taxType: Value(row['Tax Mode']?.toString() ?? 'GST'),
          batchTracking:
              Value(row['Batch Tracking']?.toString().toLowerCase() == 'yes'),
          expiryTracking:
              Value(row['Expiry Tracking']?.toString().toLowerCase() == 'yes'),
          serialTracking:
              Value(row['Serial Tracking']?.toString().toLowerCase() == 'yes'),
          lowStockLevel:
              Value(double.tryParse(row['Low Stock Level']?.toString() ?? '')),
          reorderLevel:
              Value(double.tryParse(row['Reorder Level']?.toString() ?? '')),
          isActive: Value(row['Active']?.toString().toLowerCase() != 'no'),
        );

        await _db.into(_db.products).insert(productCompanion);

        // Add prices if any
        void insertPrice(String type, String priceKey) async {
          final priceStr = row[priceKey]?.toString();
          if (priceStr != null && double.tryParse(priceStr) != null) {
            await _db.into(_db.productPrices).insert(
                ProductPricesCompanion.insert(
                    id: Value(_uuid.v4()),
                    productId: productId,
                    productUnitId:
                        unitId, // Base unit for now, as we don't have separate unit resolution here yet
                    priceType: type,
                    price: double.parse(priceStr)));
          }
        }

        insertPrice('PURCHASE', 'Purchase Price');
        insertPrice('WHOLESALE', 'Wholesale Price');
        insertPrice('RETAIL', 'Retail Price');
        insertPrice('MRP', 'MRP');

        // Opening Stock if available
        final openingStockStr = row['Opening Stock']?.toString();
        if (openingStockStr != null &&
            double.tryParse(openingStockStr) != null) {
          // Usually requires a warehouse ID. Let's just assume we get default warehouse or null warehouse for now.
          // Or log warning. For simplicity we skip opening stock if warehouse is missing, or assign to first warehouse.
          final warehouse =
              await (_db.select(_db.warehouses)..limit(1)).getSingleOrNull();
          if (warehouse != null) {
            await adjustStock(
                productId: productId,
                warehouseId: warehouse.id,
                unitId: unitId,
                adjustedQty: double.parse(openingStockStr),
                baseQty: double.parse(openingStockStr),
                reason: 'Opening Stock from Import');
          }
        }

        // Add to SyncQueue
        await _db.into(_db.syncQueues).insert(SyncQueuesCompanion.insert(
            entityType: 'PRODUCT',
            entityId: productId,
            operation: 'CREATE',
            payload: jsonEncode({
              'productCode': productCode,
              'name': row['Product Name'].toString()
            }), // placeholder
            deviceId: 'local'));
      }
    });
  }

  Future<void> adjustStock({
    required String productId,
    required String warehouseId,
    required String unitId,
    required double adjustedQty,
    required double baseQty,
    required String reason,
  }) async {
    await _db.transaction(() async {
      final adjId = _uuid.v4();

      // Stock Transaction
      final stockTx = StockTransactionsCompanion.insert(
        id: Value(adjId),
        productId: productId,
        warehouseId: warehouseId,
        transactionType: 'ADJUSTMENT',
        referenceId:
            adjId, // Self-reference or link to a separate adjustment table if created
        unitId: unitId,
        unitQuantity: adjustedQty,
        baseQuantity: baseQty,
      );
      await _db.into(_db.stockTransactions).insert(stockTx);

      // Local stock projection
      await _applyStockBalance(productId, warehouseId, baseQty);

      // Sync Queue
      await _db.into(_db.syncQueues).insert(SyncQueuesCompanion.insert(
            entityType: 'STOCK_ADJUSTMENT',
            entityId: adjId,
            operation: 'CREATE',
            payload: jsonEncode({
              'id': adjId,
              'productId': productId,
              'warehouseId': warehouseId,
              'transactionType': 'ADJUSTMENT',
              'referenceId': adjId,
              'unitId': unitId,
              'unitQuantity': adjustedQty,
              'baseQuantity': baseQty,
            }),
            deviceId: 'local',
          ));
    });
  }

  Future<void> transferStock({
    required String productId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required String unitId,
    required double qty,
    required double baseQty,
  }) async {
    await _db.transaction(() async {
      final transferId = _uuid.v4();
      final outId = _uuid.v4();
      final inId = _uuid.v4();

      // OUT from source
      final txOut = StockTransactionsCompanion.insert(
        id: Value(outId),
        productId: productId,
        warehouseId: fromWarehouseId,
        transactionType: 'TRANSFER_OUT',
        referenceId: transferId,
        unitId: unitId,
        unitQuantity: -qty,
        baseQuantity: -baseQty,
      );
      await _db.into(_db.stockTransactions).insert(txOut);
      await _applyStockBalance(productId, fromWarehouseId, -baseQty);

      // IN to destination
      final txIn = StockTransactionsCompanion.insert(
        id: Value(inId),
        productId: productId,
        warehouseId: toWarehouseId,
        transactionType: 'TRANSFER_IN',
        referenceId: transferId,
        unitId: unitId,
        unitQuantity: qty,
        baseQuantity: baseQty,
      );
      await _db.into(_db.stockTransactions).insert(txIn);
      await _applyStockBalance(productId, toWarehouseId, baseQty);

      // Sync Queue
      await _db.into(_db.syncQueues).insert(SyncQueuesCompanion.insert(
            entityType: 'STOCK_TRANSFER',
            entityId: transferId,
            operation: 'CREATE',
            payload: jsonEncode({
              'out': {
                'id': outId,
                'productId': productId,
                'warehouseId': fromWarehouseId,
                'transactionType': 'TRANSFER_OUT',
                'referenceId': transferId,
                'unitId': unitId,
                'unitQuantity': -qty,
                'baseQuantity': -baseQty,
              },
              'in': {
                'id': inId,
                'productId': productId,
                'warehouseId': toWarehouseId,
                'transactionType': 'TRANSFER_IN',
                'referenceId': transferId,
                'unitId': unitId,
                'unitQuantity': qty,
                'baseQuantity': baseQty,
              }
            }),
            deviceId: 'local',
          ));
    });
  }

  Future<void> _applyStockBalance(
      String productId, String warehouseId, double baseQtyChange) async {
    final query = _db.select(_db.stockBalances)
      ..where((b) =>
          b.productId.equals(productId) & b.warehouseId.equals(warehouseId));

    final existing = await query.getSingleOrNull();
    if (existing != null) {
      await _db.update(_db.stockBalances).replace(existing.copyWith(
            quantity: existing.quantity + baseQtyChange,
            updatedAt: DateTime.now(),
          ));
    } else {
      await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(
            id: Value(_uuid.v4()),
            productId: productId,
            warehouseId: warehouseId,
            quantity: baseQtyChange,
          ));
    }
  }

  // Stock Ledger Query Foundation
  Future<List<StockTransaction>> getStockLedger(String productId,
      {String? warehouseId}) {
    final query = _db.select(_db.stockTransactions)
      ..where((t) => t.productId.equals(productId));
    if (warehouseId != null) {
      query.where((t) => t.warehouseId.equals(warehouseId));
    }
    query.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
    ]);
    return query.get();
  }
}
