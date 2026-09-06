import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';

class LocalInventoryRepository {
  final AppDatabase _db;

  LocalInventoryRepository(this._db);

  Future<void> adjustStock({
    required String productId,
    required String warehouseId,
    required String unitId,
    required double adjustedQty,
    required double baseQty,
    required String reason,
  }) async {
    await _db.transaction(() async {
      final adjId = uuid.v4();

      // Stock Transaction
      final stockTx = StockTransactionsCompanion.insert(
        id: adjId,
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
            payload: jsonEncode(stockTx.toJson()),
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
      final transferId = uuid.v4();

      // OUT from source
      final txOut = StockTransactionsCompanion.insert(
        id: uuid.v4(),
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
        id: uuid.v4(),
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
            payload: jsonEncode({'out': txOut.toJson(), 'in': txIn.toJson()}),
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
            id: uuid.v4(),
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
