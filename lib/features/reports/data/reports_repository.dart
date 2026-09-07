import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class ReportsRepository {
  final AppDatabase db;

  ReportsRepository(this.db);

  // Example: Daily Sales Report
  Future<List<Map<String, dynamic>>> getDailySales(
      DateTime startDate, DateTime endDate) async {
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();

    const query = '''
      SELECT date(sale_date) as date, SUM(grand_total) as total_sales, COUNT(id) as total_invoices 
      FROM sales 
      WHERE sale_date >= ? AND sale_date <= ? AND status = 'COMPLETED'
      GROUP BY date(sale_date)
      ORDER BY date(sale_date) DESC
    ''';

    final result = await db.customSelect(query, variables: [
      Variable.withString(start),
      Variable.withString(end)
    ]).get();
    return result.map((e) => e.data).toList();
  }

  // Example: Top Products
  Future<List<Map<String, dynamic>>> getTopProducts(
      DateTime startDate, DateTime endDate) async {
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();

    const query = '''
      SELECT p.name, sum(si.quantity) as qty_sold, sum(si.total) as total_amount
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      JOIN products p ON p.id = si.product_id
      WHERE s.sale_date >= ? AND s.sale_date <= ? AND s.status = 'COMPLETED'
      GROUP BY p.id, p.name
      ORDER BY qty_sold DESC
      LIMIT 20
    ''';

    final result = await db.customSelect(query, variables: [
      Variable.withString(start),
      Variable.withString(end)
    ]).get();
    return result.map((e) => e.data).toList();
  }

  // Low Stock
  Future<List<Map<String, dynamic>>> getLowStock() async {
    const query = '''
      SELECT p.name, p.low_stock_level, sum(sb.quantity) as current_stock
      FROM stock_balances sb
      JOIN products p ON p.id = sb.product_id
      GROUP BY p.id, p.name, p.low_stock_level
      HAVING current_stock <= p.low_stock_level
    ''';

    final result = await db.customSelect(query).get();
    return result.map((e) => e.data).toList();
  }

  // Customer Outstanding
  Future<List<Map<String, dynamic>>> getCustomerOutstanding() async {
    const query = '''
      SELECT c.name, c.phone, c.email, 
             sum(cl.amount * CASE WHEN cl.type = 'DEBIT' THEN 1 ELSE -1 END) as outstanding_balance
      FROM customer_ledgers cl
      JOIN customers c ON c.id = cl.customer_id
      GROUP BY c.id, c.name, c.phone, c.email
      HAVING outstanding_balance > 0
    ''';

    final result = await db.customSelect(query).get();
    return result.map((e) => e.data).toList();
  }
}
