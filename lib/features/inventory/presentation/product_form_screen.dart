import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Form states
  bool _isActive = true;
  bool _batchTracking = false;
  bool _expiryTracking = false;
  bool _serialTracking = false;
  String _taxType = 'GST';

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.large.isActive(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Save logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Product saved (queued for offline sync)')),
                );
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: isDesktop ? StepperType.horizontal : StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep += 1);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          onStepTapped: (step) => setState(() => _currentStep = step),
          steps: [
            Step(
              title: const Text('Basic Information'),
              content: _buildBasicInfoFields(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Units & Conversions'),
              content: _buildUnitFields(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Pricing & Tax'),
              content: _buildPricingFields(),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Inventory Settings'),
              content: _buildInventorySettings(),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoFields() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Active'),
          value: _isActive,
          onChanged: (val) => setState(() => _isActive = val),
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Product Code *'),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Product Name *'),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [],
                onChanged: (val) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Sub Category'),
                items: const [],
                onChanged: (val) {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Brand'),
                items: const [],
                onChanged: (val) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'HSN Code'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Barcode'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildUnitFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Configure the units this product can be bought/sold in.'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: 'Base Unit * (e.g. PCS)'),
                items: const [
                  DropdownMenuItem(value: 'PCS', child: Text('PCS')),
                  DropdownMenuItem(value: 'KG', child: Text('KG')),
                ],
                onChanged: (val) {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Purchase Unit'),
                items: const [
                  DropdownMenuItem(value: 'BOX', child: Text('BOX')),
                  DropdownMenuItem(value: 'BAG', child: Text('BAG')),
                ],
                onChanged: (val) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Sale Unit'),
                items: const [
                  DropdownMenuItem(value: 'PCS', child: Text('PCS')),
                  DropdownMenuItem(value: 'PACKET', child: Text('PACKET')),
                ],
                onChanged: (val) {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Unit Conversions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          title: const Text('1 BOX = 24 PCS'),
          trailing:
              IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add Conversion'),
        )
      ],
    );
  }

  Widget _buildPricingFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tax Mode'),
                initialValue: _taxType,
                items: const [
                  DropdownMenuItem(value: 'GST', child: Text('GST')),
                  DropdownMenuItem(value: 'NON_GST', child: Text('NON_GST')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _taxType = val);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'GST Rate %'),
                items: const [
                  DropdownMenuItem(
                      value: '18', child: Text('18% IGST (9% CGST, 9% SGST)')),
                  DropdownMenuItem(
                      value: '5',
                      child: Text('5% IGST (2.5% CGST, 2.5% SGST)')),
                ],
                onChanged: _taxType == 'GST' ? (val) {} : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Prices include GST'),
          value: false,
          onChanged: (val) {},
        ),
        const Divider(),
        const Text('Unit specific pricing (Base Unit: PCS)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Purchase Price'))),
            const SizedBox(width: 8),
            Expanded(
                child: TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Wholesale Price'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Retail Price'))),
            const SizedBox(width: 8),
            Expanded(
                child: TextFormField(
                    decoration: const InputDecoration(labelText: 'MRP'))),
          ],
        ),
      ],
    );
  }

  Widget _buildInventorySettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Batch Tracking'),
          value: _batchTracking,
          onChanged: (val) => setState(() => _batchTracking = val),
        ),
        SwitchListTile(
          title: const Text('Expiry Tracking'),
          value: _expiryTracking,
          onChanged: (val) => setState(() => _expiryTracking = val),
        ),
        SwitchListTile(
          title: const Text('Serial Tracking'),
          value: _serialTracking,
          onChanged: (val) => setState(() => _serialTracking = val),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Low Stock Level'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Reorder Level'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
