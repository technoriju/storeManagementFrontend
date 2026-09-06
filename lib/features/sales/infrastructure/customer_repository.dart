import 'package:drift/drift.dart';
import 'package:frontend/core/database/app_database.dart';

class CustomerRepository {
  final AppDatabase _db;

  CustomerRepository(this._db);

  Future<List<Customer>> getAllCustomers() async {
    return await _db.select(_db.customers).get();
  }

  Future<Customer> createCustomer(CustomersCompanion customer) async {
    final id = customer.id.value;
    await _db.into(_db.customers).insert(customer);

    // Insert into sync queue
    await _db.into(_db.syncQueues).insert(SyncQueuesCompanion.insert(
          entityType: 'Customer',
          entityId: id,
          operation: 'INSERT',
          payload: '{}',
          deviceId: 'local',
        ));

    return (await (_db.select(_db.customers)..where((tbl) => tbl.id.equals(id)))
        .getSingle());
  }

  Future<void> addLedgerEntry(CustomerLedgersCompanion entry) async {
    await _db.into(_db.customerLedgers).insert(entry);

    // Insert into sync queue
    await _db.into(_db.syncQueues).insert(SyncQueuesCompanion.insert(
          entityType: 'CustomerLedger',
          entityId: entry.id.value,
          operation: 'INSERT',
          payload: '{}',
          deviceId: 'local',
        ));
  }
}
