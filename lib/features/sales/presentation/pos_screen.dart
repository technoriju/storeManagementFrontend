import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/database/app_database.dart';
import 'package:frontend/features/sales/infrastructure/local_sales_repository.dart';

class PosScreen extends StatefulWidget {
  final LocalSalesRepository repository;

  const PosScreen({super.key, required this.repository});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();

  final List<Product> _cart = [];
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _barcodeFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    super.dispose();
  }



  void _newSale() {
    setState(() {
      _cart.clear();
      _selectedCustomer = null;
    });
    _barcodeFocusNode.requestFocus();
  }

  void _showProductSearch() {
    // Implement product search dialog
  }

  void _showCustomerSelection() {
    // Implement customer selection
  }

  void _showPaymentDialog() {
    // Implement payment dialog
  }

  void _completeSale() {
    // Implement complete sale using repository
  }

  void _onBarcodeScanned(String barcode) async {
    final products = await widget.repository.searchProducts(barcode);
    if (products.isNotEmpty) {
      setState(() {
        _cart.add(products.first);
      });
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.f2): const PosIntent('F2'),
        LogicalKeySet(LogicalKeyboardKey.f3): const PosIntent('F3'),
        LogicalKeySet(LogicalKeyboardKey.f4): const PosIntent('F4'),
        LogicalKeySet(LogicalKeyboardKey.f5): const PosIntent('F5'),
        LogicalKeySet(LogicalKeyboardKey.f8): const PosIntent('F8'),
        LogicalKeySet(LogicalKeyboardKey.f12): const PosIntent('F12'),
        LogicalKeySet(LogicalKeyboardKey.escape): const PosIntent('ESC'),
      },
      actions: {
        PosIntent: CallbackAction<PosIntent>(onInvoke: (PosIntent intent) {
          switch (intent.action) {
            case 'F2':
              _newSale();
              break;
            case 'F3':
              _showProductSearch();
              break;
            case 'F4':
              _showCustomerSelection();
              break;
            case 'F5':
              setState(() {});
              break;
            case 'F8':
              _showPaymentDialog();
              break;
            case 'F12':
              _completeSale();
              break;
            case 'ESC':
              if (Navigator.canPop(context)) Navigator.pop(context);
              break;
          }
          return null;
        }),
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('POS System'),
          actions: [
            IconButton(
                icon: const Icon(Icons.person),
                onPressed: _showCustomerSelection),
            IconButton(
                icon: const Icon(Icons.payment), onPressed: _showPaymentDialog),
          ],
        ),
        body: Row(
          children: [
            // Left Panel: Cart & Barcode
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      focusNode: _barcodeFocusNode,
                      controller: _barcodeController,
                      decoration: InputDecoration(
                          labelText: 'Scan Barcode',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () {
                              // TODO: Implement mobile camera scanner using mobile_scanner or similar
                            },
                          )),
                      onSubmitted: _onBarcodeScanned,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final product = _cart[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text('SKU: ${product.sku}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () {
                              setState(() {
                                _cart.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Right Panel: Actions and Totals
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Customer: ${_selectedCustomer?.name ?? "Walk-in"}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    Text('Total Items: ${_cart.length}'),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _newSale,
                      child: const Text('New Sale (F2)'),
                    ),
                    ElevatedButton(
                      onPressed: _showProductSearch,
                      child: const Text('Product Search (F3)'),
                    ),
                    ElevatedButton(
                      onPressed: _showPaymentDialog,
                      child: const Text('Payment (F8)'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: _completeSale,
                      child: const Text('Complete Sale (F12)'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PosIntent extends Intent {
  final String action;
  const PosIntent(this.action);
}
