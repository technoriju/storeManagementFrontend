import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/local_inventory_repository.dart';

final excelImportServiceProvider = Provider((ref) {
  return ExcelImportService(ref.read(localInventoryRepositoryProvider));
});

class ExcelImportService {
  final LocalInventoryRepository _repository;

  ExcelImportService(this._repository);

  Future<Map<String, dynamic>> parseExcelFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    List<Map<String, dynamic>> parsedData = [];
    List<Map<String, dynamic>> errorRows = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table]!;
      final rows = sheet.rows;
      if (rows.isEmpty) continue;

      final headers = rows.first.map((e) => e?.value.toString() ?? '').toList();

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty ||
            row.every((element) => element == null || element.value == null)) {
          continue;
        }

        Map<String, dynamic> rowData = {};
        for (int j = 0; j < headers.length; j++) {
          if (j < row.length) {
            rowData[headers[j]] = row[j]?.value;
          }
        }

        // Validation logic
        List<String> errors = [];
        if (rowData['Product Code'] == null ||
            rowData['Product Code'].toString().trim().isEmpty) {
          errors.add('Product Code is required');
        }
        if (rowData['Product Name'] == null ||
            rowData['Product Name'].toString().trim().isEmpty) {
          errors.add('Product Name is required');
        }
        if (rowData['Unit'] == null ||
            rowData['Unit'].toString().trim().isEmpty) {
          errors.add('Unit is required');
        }

        if (errors.isNotEmpty) {
          errorRows.add({'row': i + 1, 'data': rowData, 'errors': errors});
        } else {
          parsedData.add(rowData);
        }
      }
      break; // Only parse the first sheet
    }

    return {'valid': parsedData, 'errors': errorRows};
  }

  Future<void> importData(List<Map<String, dynamic>> data) async {
    await _repository.importProducts(data);
  }
}
