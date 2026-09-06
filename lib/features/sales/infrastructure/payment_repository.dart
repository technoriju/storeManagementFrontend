import 'package:drift/drift.dart';
import 'package:frontend/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class PaymentRepository {
  final AppDatabase _db;

  PaymentRepository(this._db);

  Future<List<PaymentMethod>> getActivePaymentMethods() async {
    return await (_db.select(_db.paymentMethods)
          ..where((tbl) => tbl.isActive.equals(true)))
        .get();
  }

  Future<void> seedDefaultPaymentMethods() async {
    final existing = await _db.select(_db.paymentMethods).get();
    if (existing.isEmpty) {
      final defaultMethods = ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Other'];
      for (var method in defaultMethods) {
        final id =
            uuid.v4(); // Assuming uuid is available or just let db generate
        await _db
            .into(_db.paymentMethods)
            .insert(PaymentMethodsCompanion.insert(
              id: Value(id),
              name: method,
              isActive: const Value(true),
              isDefault: Value(method == 'Cash'),
            ));
      }
    }
  }

  Future<void> recordPayment(PaymentsCompanion payment) async {
    await _db.into(_db.payments).insert(payment);

    await _db.into(_db.syncQueues).insert(SyncQueuesCompanion.insert(
          entityType: 'Payment',
          entityId: payment.id.value,
          operation: 'INSERT',
          payload: '{}',
          deviceId: 'local',
        ));
  }
}
