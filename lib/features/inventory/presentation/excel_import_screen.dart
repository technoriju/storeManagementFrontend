import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../application/excel_import_service.dart';

class ExcelImportScreen extends ConsumerStatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  ConsumerState<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends ConsumerState<ExcelImportScreen> {
  int _currentStep = 0;
  bool _isUploading = false;
  bool _isImporting = false;

  List<Map<String, dynamic>> _parsedData = [];
  List<Map<String, dynamic>> _errorRows = [];
  String? _selectedFileName;

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() {
      _isUploading = true;
      _selectedFileName = result.files.single.name;
    });

    try {
      final service = ref.read(excelImportServiceProvider);
      final data = await service.parseExcelFile(result.files.single.path!);

      setState(() {
        _parsedData = data['valid'];
        _errorRows = data['errors'];
        _currentStep = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse file: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _confirmImport() async {
    setState(() => _isImporting = true);

    try {
      final service = ref.read(excelImportServiceProvider);
      await service.importData(_parsedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully imported ${_parsedData.length} products!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
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
        controlsBuilder: (context, details) =>
            const SizedBox.shrink(), // hide default controls
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
          if (_selectedFileName != null) ...[
            const SizedBox(height: 8),
            Text('Selected: $_selectedFileName',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
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
          // Show error details if needed
        ],
        Text('Valid Rows: ${_parsedData.length}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _parsedData.length,
            itemBuilder: (context, index) {
              final row = _parsedData[index];
              return ListTile(
                title: Text(row['Product Name']?.toString() ?? ''),
                subtitle: Text(
                    'Code: ${row['Product Code']} | Base Unit: ${row['Unit']}'),
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
              onPressed: () => setState(() {
                _currentStep = 0;
                _selectedFileName = null;
                _parsedData.clear();
                _errorRows.clear();
              }),
              child: const Text('Re-upload File'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: _parsedData.isEmpty
                  ? null
                  : () => setState(() => _currentStep = 2),
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
          Text('Ready to import ${_parsedData.length} valid products.'),
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
