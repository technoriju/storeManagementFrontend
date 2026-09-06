import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data for products
  final List<Map<String, dynamic>> _products = List.generate(
    20,
    (index) => {
      'code': 'PRD-${1000 + index}',
      'name': 'Product ${index + 1}',
      'category': 'Electronics',
      'brand': 'Brand X',
      'stock': (index * 15) % 100,
      'price': 99.99 + (index * 10),
      'active': index % 5 != 0,
    },
  );

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.large.isActive(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Bulk Import',
            onPressed: () => context.go('/inventory/import'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () => context.go('/inventory/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(isDesktop),
          Expanded(
            child: isDesktop ? _buildDataTable() : _buildMobileList(),
          ),
        ],
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => context.go('/inventory/new'),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildFilters(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name, code, sku...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (isDesktop) ...[
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Electronics', child: Text('Electronics')),
                  DropdownMenuItem(
                      value: 'Groceries', child: Text('Groceries')),
                ],
                onChanged: (val) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Brand X', child: Text('Brand X')),
                ],
                onChanged: (val) {},
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list),
              label: const Text('More Filters'),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // Show modal bottom sheet for filters on mobile
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListView(
        children: [
          PaginatedDataTable(
            header: const Text('All Products'),
            columns: const [
              DataColumn(label: Text('Code')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Brand')),
              DataColumn(label: Text('Stock')),
              DataColumn(label: Text('Price (MRP)')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            source: _ProductDataSource(_products),
            rowsPerPage: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(product['name']),
            subtitle: Text('${product['code']} | ${product['category']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${product['price'].toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Stock: ${product['stock']}'),
              ],
            ),
            onTap: () {
              // Edit product
            },
          ),
        );
      },
    );
  }
}

class _ProductDataSource extends DataTableSource {
  final List<Map<String, dynamic>> data;

  _ProductDataSource(this.data);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final row = data[index];
    return DataRow(cells: [
      DataCell(Text(row['code'])),
      DataCell(Text(row['name'])),
      DataCell(Text(row['category'])),
      DataCell(Text(row['brand'])),
      DataCell(Text(row['stock'].toString())),
      DataCell(Text('\$${row['price'].toStringAsFixed(2)}')),
      DataCell(
        Chip(
          label: Text(row['active'] ? 'Active' : 'Inactive'),
          backgroundColor: row['active']
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
        ),
      ),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.delete, size: 20), onPressed: () {}),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
