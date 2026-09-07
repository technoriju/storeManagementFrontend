import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class PurchaseEntryScreen extends StatefulWidget {
  const PurchaseEntryScreen({super.key});

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // ignore: unused_field
  String? _selectedSupplier;
  final TextEditingController _invoiceNoController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  final List<Map<String, dynamic>> _items = [];
  double _subTotal = 0;
  double _taxTotal = 0;
  final double _discountTotal = 0;
  double _grandTotal = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.large.isActive(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase'),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Save logic
            },
            icon: const Icon(Icons.save),
            label: const Text('Save & Complete'),
          ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left - Form and Items
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeaderDetails(),
                const SizedBox(height: 16),
                Expanded(child: _buildItemTable()),
              ],
            ),
          ),
        ),
        // Right - Summary
        Expanded(
          flex: 1,
          child: Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(16.0),
            child: _buildSummary(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHeaderDetails(),
          const SizedBox(height: 16),
          const Divider(),
          const Text('Items',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          _buildMobileItemList(),
          OutlinedButton.icon(
            onPressed: _addItemDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
          const Divider(),
          _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildHeaderDetails() {
    return Form(
      key: _formKey,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                  labelText: 'Supplier', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'SUP-01', child: Text('Acme Corp')),
              ],
              onChanged: (v) => setState(() => _selectedSupplier = v),
            ),
          ),
          SizedBox(
            width: 200,
            child: TextFormField(
              controller: _invoiceNoController,
              decoration: const InputDecoration(
                  labelText: 'Invoice Number', border: OutlineInputBorder()),
            ),
          ),
          SizedBox(
            width: 200,
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _purchaseDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _purchaseDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Purchase Date', border: OutlineInputBorder()),
                child: Text('${_purchaseDate.toLocal()}'.split(' ')[0]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Purchase Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _addItemDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Unit')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('')),
              ],
              rows: _items
                  .map((item) => DataRow(cells: [
                        DataCell(Text(item['productName'])),
                        DataCell(Text(item['unit'])),
                        DataCell(Text(item['qty'].toString())),
                        DataCell(Text(item['price'].toString())),
                        DataCell(Text(item['total'].toString())),
                        DataCell(IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _items.remove(item);
                              _calculateTotals();
                            });
                          },
                        )),
                      ]))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileItemList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final item = _items[i];
        return ListTile(
          title: Text(item['productName']),
          subtitle: Text('${item['qty']} ${item['unit']} @ \$${item['price']}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                _items.removeAt(i);
                _calculateTotals();
              });
            },
          ),
        );
      },
    );
  }

  void _addItemDialog() {
    // Show a dialog to pick product, unit, qty, price
    // Stub implementation
    setState(() {
      _items.add({
        'productId': 'P-01',
        'productName': 'Sample Box',
        'unit': 'BOX',
        'qty': 10,
        'price': 100,
        'total': 1000,
      });
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    _subTotal = _items.fold(0, (sum, item) => sum + item['total']);
    _taxTotal = _subTotal * 0.05; // 5% mock tax
    _grandTotal = _subTotal + _taxTotal - _discountTotal;
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _summaryRow('Subtotal', _subTotal),
        _summaryRow('Tax', _taxTotal),
        _summaryRow('Discount', -_discountTotal),
        const Divider(),
        _summaryRow('Grand Total', _grandTotal, isTotal: true),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: const Text('Complete Purchase'),
        )
      ],
    );
  }

  Widget _summaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 14)),
          Text('\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 14)),
        ],
      ),
    );
  }
}
