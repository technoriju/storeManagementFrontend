import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';

class LocalPurchaseRepository {
  final AppDatabase _db;

  LocalPurchaseRepository(this._db);

  Future<void> completePurchase({
    required PurchasesCompanion purchase,
    required List<PurchaseItemsCompanion> items,
    required String warehouseId,
    // Add payment info if needed
  }) async {
    await _db.transaction(() async {
      // 1. Insert Purchase
      final pId = purchase.id.value;
      await _db.into(_db.purchases).insert(purchase);

      // 2. Insert Purchase Items & Stock
      for (final item in items) {
        await _db.into(_db.purchaseItems).insert(item);

        // Calculate base quantity
        // Wait, we need the conversion factor for the productUnitId
        final productUnit = await (_db.select(_db.productUnits)
              ..where((u) => u.id.equals(item.productUnitId.value)))
            .getSingle();

        final baseQty = item.quantity.value * productUnit.conversionFactor;

        // 3. Stock Transactions
        final stockTx = StockTransactionsCompanion.insert(
          id: uuid.v4(),
          productId: item.productId.value,
          warehouseId: warehouseId,
          transactionType: 'PURCHASE',
          referenceId: pId,
          unitId: productUnit.unitId,
          unitQuantity: item.quantity.value,
          baseQuantity: baseQty,
        );
        await _db.into(_db.stockTransactions).insert(stockTx);

        // 4. Local stock projection
        final balanceQuery = _db.select(_db.stockBalances)
          ..where((b) => b.productId.equals(item.productId.value) & b.warehouseId.equals(warehouseId));
        
        final existingBalance = await balanceQuery.getSingleOrNull();
        if (existingBalance != null) {
          await _db.update(_db.stockBalances).replace(
            existingBalance.copyWith(
              quantity: existingBalance.quantity + baseQty,
              updatedAt: DateTime.now(),
            )
          );
        } else {
          await _db.into(_db.stockBalances).insert(
            StockBalancesCompanion.insert(
              id: uuid.v4(),
              productId: item.productId.value,
              warehouseId: warehouseId,
              quantity: baseQty,
            )
          );
        }
      }

      // 5. Sync queue entry
      final payload = {
        'purchase': purchase.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
      };
      
      await _db.into(_db.syncQueues).insert(
        SyncQueuesCompanion.insert(
          entityType: 'PURCHASE',
          entityId: pId,
          operation: 'CREATE',
          payload: jsonEncode(payload),
          deviceId: 'local', // Or fetch from config
        )
      );
    });
  }

  Future<void> returnPurchase({
    required PurchaseReturnsCompanion purchaseReturn,
    required List<PurchaseItemsCompanion> returnItems, // Using PurchaseItem companion for the items being returned
    required String warehouseId,
  }) async {
    await _db.transaction(() async {
      final prId = purchaseReturn.id.value;
      await _db.into(_db.purchaseReturns).insert(purchaseReturn);

      // We need to reverse stock
      for (final item in returnItems) {
        final productUnit = await (_db.select(_db.productUnits)
              ..where((u) => u.id.equals(item.productUnitId.value)))
            .getSingle();

        final baseQty = item.quantity.value * productUnit.conversionFactor;

        final stockTx = StockTransactionsCompanion.insert(
          id: uuid.v4(),
          productId: item.productId.value,
          warehouseId: warehouseId,
          transactionType: 'PURCHASE_RETURN',
          referenceId: prId,
          unitId: productUnit.unitId,
          unitQuantity: -item.quantity.value,
          baseQuantity: -baseQty,
        );
        await _db.into(_db.stockTransactions).insert(stockTx);

        final balanceQuery = _db.select(_db.stockBalances)
          ..where((b) => b.productId.equals(item.productId.value) & b.warehouseId.equals(warehouseId));
        
        final existingBalance = await balanceQuery.getSingleOrNull();
        if (existingBalance != null) {
          await _db.update(_db.stockBalances).replace(
            existingBalance.copyWith(
              quantity: existingBalance.quantity - baseQty,
              updatedAt: DateTime.now(),
            )
          );
        } else {
          // It's possible stock is negative now, which is allowed in some systems or handled gracefully
          await _db.into(_db.stockBalances).insert(
            StockBalancesCompanion.insert(
              id: uuid.v4(),
              productId: item.productId.value,
              warehouseId: warehouseId,
              quantity: -baseQty,
            )
          );
        }
      }

      final payload = {
        'return': purchaseReturn.toJson(),
        'items': returnItems.map((e) => e.toJson()).toList(),
      };
      
      await _db.into(_db.syncQueues).insert(
        SyncQueuesCompanion.insert(
          entityType: 'PURCHASE_RETURN',
          entityId: prId,
          operation: 'CREATE',
          payload: jsonEncode(payload),
          deviceId: 'local',
        )
      );
    });
  }
}
