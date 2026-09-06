import 'package:flutter/material.dart';
import 'dart:async';

class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  int _currentStep = 0;
  bool _isUploading = false;
  bool _isParsing = false;
  bool _isImporting = false;
  
  List<Map<String, dynamic>> _parsedData = [];
  List<Map<String, dynamic>> _errorRows = [];

  void _uploadFile() async {
    setState(() => _isUploading = true);
    // Mock upload and parse
    await Future.delayed(const Duration(seconds: 2));
    
    _parsedData = [
      {
        'Product Code': 'P001',
        'Product Name': 'Item 1',
        'Category': 'Cat A',
        'Brand': 'Brand A',
        'Base Unit': 'PCS',
        'Purchase Price': 100,
        'Retail Price': 150,
      },
      {
        'Product Code': 'P002',
        'Product Name': 'Item 2',
        'Category': 'Cat B',
        'Brand': '', // Error missing brand if required, but let's just make it valid
        'Base Unit': 'PCS',
        'Purchase Price': 200,
        'Retail Price': 250,
      }
    ];

    _errorRows = [
      {
        'row': 3,
        'data': {'Product Code': '', 'Product Name': 'Item 3'},
        'errors': ['Product Code is missing', 'Base Unit is missing']
      }
    ];

    setState(() {
      _isUploading = false;
      _currentStep = 1;
    });
  }

  void _confirmImport() async {
    setState(() => _isImporting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isImporting = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported ${_parsedData.length} products!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Products (Excel)'),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        controlsBuilder: (context, details) => const SizedBox.shrink(), // hide default controls
        steps: [
          Step(
            title: const Text('Upload'),
            content: _buildUploadStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Preview & Validate'),
            content: _buildPreviewStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Import'),
            content: _buildImportStep(),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Upload Product Excel Template (.xlsx)'),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text('Download Template'),
          ),
          const SizedBox(height: 24),
          _isUploading
              ? const CircularProgressIndicator()
              : FilledButton.icon(
                  onPressed: _uploadFile,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Select File'),
                ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorRows.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade50,
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Found ${_errorRows.length} rows with errors. These will be skipped. Please fix them in the file and re-upload if needed.',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Valid Rows: ${_parsedData.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _parsedData.length,
            itemBuilder: (context, index) {
              final row = _parsedData[index];
              return ListTile(
                title: Text(row['Product Name'] ?? ''),
                subtitle: Text('Code: ${row['Product Code']} | Price: ${row['Retail Price']}'),
                leading: const Icon(Icons.check_circle, color: Colors.green),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text('Re-upload File'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text('Proceed to Import'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildImportStep() {
    return Center(
      child: Column(
        children: [
          const Text('Ready to import valid products.'),
          const SizedBox(height: 16),
          _isImporting
              ? const CircularProgressIndicator()
              : FilledButton.icon(
                  onPressed: _confirmImport,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Import'),
                ),
        ],
      ),
    );
  }
}
