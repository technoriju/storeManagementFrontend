import 'dart:async';

abstract class IRepository<T> {
  Future<T?> findById(String id);
  Future<List<T>> findAll({int? limit, int? offset});
  Future<T> create(T item);
  Future<T> update(String id, T item);
  Future<void> softDelete(String id);

  // Sync Support
  Future<List<T>> findSince(DateTime timestamp);
}
