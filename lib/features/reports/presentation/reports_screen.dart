import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reports_repository.dart';
import '../data/excel_service.dart';
import '../../../core/database/app_database.dart';

final dbProvider = Provider<AppDatabase>((ref) => AppDatabase());
final reportsRepositoryProvider = Provider<ReportsRepository>(
    (ref) => ReportsRepository(ref.watch(dbProvider)));
final excelServiceProvider =
    Provider<ExcelService>((ref) => ExcelService(ref.watch(dbProvider)));

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Products (Excel)',
            onPressed: () async {
              await ref.read(excelServiceProvider).exportProducts();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export Excel complete.')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Products (CSV)',
            onPressed: () async {
              await ref.read(excelServiceProvider).exportToCsv();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export CSV complete.')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Products (PDF)',
            onPressed: () async {
              await ref.read(excelServiceProvider).exportToPdf();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export PDF complete.')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import Products (Excel)',
            onPressed: () async {
              final result =
                  await ref.read(excelServiceProvider).importProducts();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(result)));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              '⚠️ All reports are generated from local synchronized data and are available offline.',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
          _buildReportCard(
            context,
            'Daily Sales Report',
            Icons.point_of_sale,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const ReportDetailScreen(reportType: 'Daily Sales'))),
          ),
          _buildReportCard(
            context,
            'Top Products',
            Icons.star,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const ReportDetailScreen(reportType: 'Top Products'))),
          ),
          _buildReportCard(
            context,
            'Low Stock Report',
            Icons.warning,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const ReportDetailScreen(reportType: 'Low Stock'))),
          ),
          _buildReportCard(
            context,
            'Customer Outstanding',
            Icons.people,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReportDetailScreen(
                        reportType: 'Customer Outstanding'))),
          ),
          // Additional reports can be added here
        ],
      ),
    );
  }

  Widget _buildReportCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportType;
  const ReportDetailScreen({super.key, required this.reportType});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final repo = ref.read(reportsRepositoryProvider);
    try {
      switch (widget.reportType) {
        case 'Daily Sales':
          _data = await repo.getDailySales(_startDate, _endDate);
          break;
        case 'Top Products':
          _data = await repo.getTopProducts(_startDate, _endDate);
          break;
        case 'Low Stock':
          _data = await repo.getLowStock();
          break;
        case 'Customer Outstanding':
          _data = await repo.getCustomerOutstanding();
          break;
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.reportType)),
      body: Column(
        children: [
          if (widget.reportType == 'Daily Sales' ||
              widget.reportType == 'Top Products')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                          '${_startDate.toString().split(' ')[0]} to ${_endDate.toString().split(' ')[0]}'),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDateRange:
                              DateTimeRange(start: _startDate, end: _endDate),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                          _loadData();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                    ? const Center(
                        child: Text('No data found for this report.'))
                    : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_data.isEmpty) return const SizedBox();

    final columns = _data.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns
              .map((e) => DataColumn(
                  label: Text(e.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold))))
              .toList(),
          rows: _data.map((row) {
            return DataRow(
              cells: columns
                  .map((col) => DataCell(Text(row[col]?.toString() ?? '')))
                  .toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
