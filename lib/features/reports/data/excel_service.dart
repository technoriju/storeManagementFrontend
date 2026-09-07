import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class ExcelService {
  final AppDatabase db;
  final uuid = const Uuid();

  ExcelService(this.db);

  Future<void> exportProducts() async {
    final products = await db.select(db.products).get();

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Products'];
    excel.setDefaultSheet('Products');

    // Header
    sheetObject.appendRow([
      'Product Code',
      'Name',
      'SKU',
      'Description',
    ]);

    // Data
    for (var product in products) {
      sheetObject.appendRow([
        product.productCode,
        product.name,
        product.sku,
        product.description ?? '',
      ]);
    }

    // Save and Share
    var fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/products_export.xlsx');
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Products Export');
    }
  }

  Future<void> exportToCsv() async {
    final products = await db.select(db.products).get();

    List<List<dynamic>> rows = [];
    rows.add(['Product Code', 'Name', 'SKU', 'Description']);

    for (var product in products) {
      rows.add([
        product.productCode,
        product.name,
        product.sku,
        product.description ?? '',
      ]);
    }

    // using raw string building for simplicity if we don't import the csv package directly,
    // but we can just use simple join
    String csv = rows
        .map((row) => row
            .map((item) => '"${item.toString().replaceAll('"', '""')}"')
            .join(','))
        .join('\n');

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/products_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Products Export CSV');
  }

  Future<void> exportToPdf() async {
    final products = await db.select(db.products).get();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(children: [
            pw.Header(level: 0, child: pw.Text('Products Report')),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Code', 'Name', 'SKU', 'Description'],
                ...products.map(
                  (p) => [p.productCode, p.name, p.sku, p.description ?? '']
                ),
              ],
            ),
          ]);
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/products_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Products PDF Report');
  }

  Future<String> importProducts() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      var file = result.files.single.path!;
      var bytes = File(file).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      int successCount = 0;
      int errorCount = 0;

      // Use transactions for confirmed imports, never partially corrupt
      await db.transaction(() async {
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;
          bool isFirstRow = true;
          for (var row in sheet.rows) {
            if (isFirstRow) {
              isFirstRow = false;
              continue;
            }

            if (row.isEmpty || row[0] == null) continue;

            try {
              final code = row[0]?.value.toString() ?? '';
              final name = row[1]?.value.toString() ?? '';
              final sku = row[2]?.value.toString() ?? '';
              final desc = row[3]?.value.toString() ?? '';

              if (code.isEmpty || name.isEmpty || sku.isEmpty) {
                errorCount++;
                continue;
              }

              // check if product exists
              final existing = await (db.select(db.products)
                    ..where((tbl) => tbl.productCode.equals(code)))
                  .getSingleOrNull();

              if (existing != null) {
                await (db.update(db.products)
                      ..where((tbl) => tbl.id.equals(existing.id)))
                    .write(ProductsCompanion(
                  name: Value(name),
                  sku: Value(sku),
                  description: Value(desc),
                  updatedAt: Value(DateTime.now()),
                ));
              } else {
                await db.into(db.products).insert(ProductsCompanion.insert(
                      id: Value(uuid.v4()),
                      productCode: code,
                      name: name,
                      sku: sku,
                      description: Value(desc),
                      taxType: const Value('GST'),
                      baseUnitId:
                          'default', // Ideally this should be matched with existing units
                    ));
              }
              successCount++;
            } catch (e) {
              errorCount++;
            }
          }
        }
      });
      return 'Imported $successCount products. $errorCount errors.';
    }
    return 'Import cancelled.';
  }
}
