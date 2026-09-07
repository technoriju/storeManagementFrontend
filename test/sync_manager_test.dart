import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/database/app_database.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/sync/sync_manager.dart';
import 'package:frontend/core/storage/secure_storage.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  late AppDatabase db;
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late MockSecureStorage mockStorage;
  late SyncManagerNotifier syncManager;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockDio = MockDio();
    mockApiClient = MockApiClient();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    mockStorage = MockSecureStorage();
    when(() => mockStorage.getToken(any())).thenAnswer((_) async => null);
    when(() => mockStorage.saveToken(any(), any())).thenAnswer((_) async => {});

    syncManager = SyncManagerNotifier(db, mockApiClient, mockStorage);
  });

  tearDown(() async {
    await db.close();
    syncManager.dispose();
  });

  test('offline create', () async {
    syncManager.addToOutbox('PRODUCT', 'prod_1', 'CREATE', {'name': 'Test'}, 'dev_1');
    final outbox = await db.select(db.syncQueues).get();
    expect(outbox.length, 1);
    expect(outbox.first.operation, 'CREATE');
    expect(outbox.first.status, 'PENDING');
  });

  test('offline update', () async {
    syncManager.addToOutbox('PRODUCT', 'prod_1', 'UPDATE', {'name': 'Test 2'}, 'dev_1');
    final outbox = await db.select(db.syncQueues).get();
    expect(outbox.length, 1);
    expect(outbox.first.operation, 'UPDATE');
  });

  test('offline delete', () async {
    syncManager.addToOutbox('PRODUCT', 'prod_1', 'DELETE', {}, 'dev_1');
    final outbox = await db.select(db.syncQueues).get();
    expect(outbox.length, 1);
    expect(outbox.first.operation, 'DELETE');
  });

  test('online sync and duplicate request handling', () async {
    // Add to outbox
    syncManager.addToOutbox('PRODUCT', 'prod_1', 'CREATE', {'name': 'Test'}, 'dev_1');
    
    // Mock successful push
    when(() => mockDio.post(any(), data: any(named: 'data')))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 200));
        
    // Mock successful pull
    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 200, data: {
          'changes': [], 'newSyncCursor': '2026-01-01T00:00:00Z'
        }));

    await syncManager.triggerManualSync();

    final outbox = await db.select(db.syncQueues).get();
    expect(outbox.isEmpty, true); // It should be processed and removed
    
    // Verify duplicate requests logic (idempotency)
    verify(() => mockDio.post('/api/sync/push', data: any(named: 'data'))).called(1);
  });
  
  test('retry on network failure', () async {
    syncManager.addToOutbox('PRODUCT', 'prod_1', 'CREATE', {'name': 'Test'}, 'dev_1');
    
    when(() => mockDio.post(any(), data: any(named: 'data')))
        .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    await syncManager.triggerManualSync();

    final outbox = await db.select(db.syncQueues).get();
    expect(outbox.length, 1);
    expect(outbox.first.status, 'FAILED');
    expect(outbox.first.retryCount, 1);
  });
  
  test('conflict simulation', () async {
     // Usually conflict is thrown by server (409 Conflict)
     syncManager.addToOutbox('PRODUCT', 'prod_1', 'UPDATE', {'name': 'Test'}, 'dev_1');
     
     when(() => mockDio.post(any(), data: any(named: 'data')))
        .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''), 
            response: Response(requestOptions: RequestOptions(path: ''), statusCode: 409)));

     await syncManager.triggerManualSync();
     
     final outbox = await db.select(db.syncQueues).get();
     expect(outbox.length, 1); // Should fail and wait or resolve
     expect(outbox.first.status, 'FAILED');
  });
  
  test('partial sync simulation', () async {
    // 2 items, 1 succeeds, 1 fails
    syncManager.addToOutbox('PRODUCT', 'prod_1', 'CREATE', {'name': 'Test'}, 'dev_1');
    syncManager.addToOutbox('PRODUCT', 'prod_2', 'CREATE', {'name': 'Test'}, 'dev_1');
    
    int callCount = 0;
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) return Response(requestOptions: RequestOptions(path: ''), statusCode: 200);
      throw DioException(requestOptions: RequestOptions(path: ''));
    });
    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 200, data: {
          'changes': [], 'newSyncCursor': '2026-01-01T00:00:00Z'
        }));

    await syncManager.triggerManualSync();
    
    final outbox = await db.select(db.syncQueues).get();
    expect(outbox.length, 1); // Only the failed one remains
    expect(outbox.first.entityId, 'prod_2');
  });
}
