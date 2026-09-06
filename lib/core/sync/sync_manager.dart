import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

enum SyncStatus {
  idle,
  syncing,
  error,
  offline,
  pending
}

final syncManagerProvider = StateNotifierProvider<SyncManagerNotifier, SyncStatus>((ref) {
  final db = ref.read(appDatabaseProvider);
  final apiClient = ref.read(apiClientProvider);
  final storage = ref.read(secureStorageProvider);
  return SyncManagerNotifier(db, apiClient, storage);
});

// Assuming a provider for db
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase(); // You should manage this properly in your real app
});

class SyncManagerNotifier extends StateNotifier<SyncStatus> {
  final AppDatabase db;
  final ApiClient apiClient;
  final SecureStorageService storage;
  Timer? _syncTimer;
  Timer? _connectivityTimer;
  bool _isOnline = false;
  bool _isSyncing = false;

  SyncManagerNotifier(this.db, this.apiClient, this.storage) : super(SyncStatus.idle) {
    _initConnectivityCheck();
  }

  void _initConnectivityCheck() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final wasOnline = _isOnline;
      _isOnline = await _checkInternetConnection();
      
      if (!_isOnline) {
        if (state != SyncStatus.offline) {
          state = SyncStatus.offline;
        }
      } else {
        if (!wasOnline) {
          // Came online, trigger sync
          if (state == SyncStatus.offline) {
             state = SyncStatus.pending;
          }
          startSync();
        }
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      if (kIsWeb) return true; // simplified for web
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> startSync() async {
    if (_isSyncing || !_isOnline) return;
    _isSyncing = true;
    state = SyncStatus.syncing;

    try {
      await _pushChanges();
      await _pullChanges();
      state = SyncStatus.idle;
    } catch (e) {
      debugPrint('Sync failed: $e');
      state = SyncStatus.error;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> triggerManualSync() async {
    await startSync();
  }

  Future<void> _pushChanges() async {
    final pendingItems = await (db.select(db.syncQueues)
      ..where((t) => t.status.equals('PENDING') | t.status.equals('FAILED'))
      ..where((t) => t.retryCount.isSmallerThanValue(5))
      ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.asc)]))
      .get();

    if (pendingItems.isEmpty) return;

    for (final item in pendingItems) {
      try {
        await db.update(db.syncQueues).replace(item.copyWith(status: 'SYNCING'));
        
        // Idempotent operation based on entity_type, entity_id, operation, device_id, etc.
        final payload = jsonDecode(item.payload);
        
        final response = await apiClient.dio.post('/api/sync/push', data: {
          'id': item.id,
          'entityType': item.entityType,
          'entityId': item.entityId,
          'operation': item.operation,
          'payload': payload,
          'deviceId': item.deviceId,
          'createdAt': item.createdAt.toIso8601String(),
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
           await db.delete(db.syncQueues).delete(item);
        }
      } catch (e) {
        // Handle error and increment retry count
        final newRetryCount = item.retryCount + 1;
        await db.update(db.syncQueues).replace(item.copyWith(
          status: 'FAILED',
          retryCount: newRetryCount,
          lastError: drift.Value(e.toString()),
        ));
      }
    }
  }

  Future<void> _pullChanges() async {
    final lastSyncStr = await storage.getToken('last_sync_timestamp');
    DateTime? lastSync;
    if (lastSyncStr != null) {
       lastSync = DateTime.tryParse(lastSyncStr);
    }
    
    final deviceId = await storage.getToken('device_id') ?? 'unknown_device';

    final response = await apiClient.dio.get('/api/sync/pull', queryParameters: {
      'lastSync': lastSync?.toIso8601String() ?? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      'deviceId': deviceId,
    });

    if (response.statusCode == 200) {
      final List<dynamic> changes = response.data['changes'];
      final newSyncCursor = response.data['newSyncCursor'];

      if (changes.isNotEmpty) {
        await db.transaction(() async {
          for (final change in changes) {
            await _applyRemoteChange(change);
          }
        });
      }

      await storage.saveToken('last_sync_timestamp', newSyncCursor);
    }
  }

  Future<void> _applyRemoteChange(Map<String, dynamic> change) async {
    final entityType = change['entityType'];
    final entityId = change['entityId'];
    final operation = change['operation'];
    final payload = change['payload'];
    final serverVersion = change['version'] ?? 1;

    // Based on entityType, target the correct table. Example for Products:
    if (entityType == 'PRODUCT') {
       if (operation == 'DELETE') {
         await (db.delete(db.products)..where((t) => t.id.equals(entityId))).go();
       } else {
         // Create or Update. Assuming payload contains full product data.
         // In a real implementation we parse the payload and insert/replace.
         // We also check local version to handle conflict. Server wins in this phase.
         // Implementation detail omitted for brevity - this demonstrates the architecture.
         debugPrint('Applying $operation to $entityType: $entityId');
       }
    }
  }

  void addToOutbox(String entityType, String entityId, String operation, Map<String, dynamic> payload, String deviceId) async {
    final syncItem = SyncQueuesCompanion.insert(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: jsonEncode(payload),
      deviceId: deviceId,
    );
    await db.into(db.syncQueues).insert(syncItem);
    
    // Attempt sync immediately if online
    if (_isOnline) {
      state = SyncStatus.pending;
      startSync();
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
