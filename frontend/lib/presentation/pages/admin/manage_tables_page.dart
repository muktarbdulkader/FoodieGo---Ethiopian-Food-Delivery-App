import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/models/table.dart';
import '../../widgets/loading_widget.dart';
import '../../../core/utils/download_helper.dart';

class ManageTablesPage extends StatefulWidget {
  const ManageTablesPage({super.key});

  @override
  State<ManageTablesPage> createState() => _ManageTablesPageState();
}

class _ManageTablesPageState extends State<ManageTablesPage> {
  final TableRepository _tableRepo = TableRepository();
  List<TableModel> _tables = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // CRITICAL: Set admin session type FIRST
    StorageUtils.setSessionType(SessionType.admin);
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tables = await _tableRepo.getAllTables();
      if (mounted) {
        setState(() {
          _tables = tables;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCreateTableDialog() async {
    final tableNumberController = TextEditingController();
    final capacityController = TextEditingController(text: '4');
    final locationController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Table'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tableNumberController,
                decoration: const InputDecoration(
                  labelText: 'Table Number *',
                  hintText: 'e.g., T01',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Number of seats',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Window side',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tableNumberController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter table number')),
                );
                return;
              }

              try {
                await _tableRepo.createTable(
                  tableNumber: tableNumberController.text,
                  capacity: int.tryParse(capacityController.text) ?? 4,
                  location: locationController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadTables();
    }
  }

  Future<void> _showBulkCreateDialog() async {
    final countController = TextEditingController(text: '10');
    final prefixController = TextEditingController(text: 'T');
    final capacityController = TextEditingController(text: '4');
    final locationController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Create Tables'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: countController,
                decoration: const InputDecoration(
                  labelText: 'Number of Tables *',
                  hintText: 'e.g., 10',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: prefixController,
                decoration: const InputDecoration(
                  labelText: 'Table Prefix',
                  hintText: 'e.g., T (creates T01, T02...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Default Capacity',
                  hintText: 'Number of seats',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Main hall',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final count = int.tryParse(countController.text);
              if (count == null || count < 1 || count > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid count (1-100)')),
                );
                return;
              }

              try {
                await _tableRepo.bulkCreateTables(
                  count: count,
                  prefix: prefixController.text,
                  capacity: int.tryParse(capacityController.text) ?? 4,
                  location: locationController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadTables();
    }
  }

  Future<void> _downloadQRCode(TableModel table) async {
    try {
      // Validate QR code data
      if (table.qrCodeData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR code data is missing. Please refresh the table list.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
      
      // Create a GlobalKey for the QR code widget
      final qrKey = GlobalKey();
      
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Generating QR code...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Create QR code widget
      final qrWidget = RepaintBoundary(
        key: qrKey,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Table ${table.tableNumber}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: table.qrCodeData,
                  version: QrVersions.auto,
                  size: 300,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Scan to order from your table',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
      
      // Render the widget offscreen
      final renderObject = RenderRepaintBoundary();
      final pipelineOwner = PipelineOwner();
      final buildOwner = BuildOwner(focusManager: FocusManager());
      
      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: renderObject,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: qrWidget,
        ),
      ).attachToRenderTree(buildOwner);
      
      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();
      
      pipelineOwner.rootNode = renderObject;
      renderObject.attach(pipelineOwner);
      
      // Set size
      renderObject.layout(const BoxConstraints(
        minWidth: 500,
        maxWidth: 500,
        minHeight: 600,
        maxHeight: 600,
      ));
      
      // Convert to image
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      // Download file (works on web, throws on mobile)
      try {
        downloadFile(bytes, 'table-${table.tableNumber}-qr.png');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR code for Table ${table.tableNumber} downloaded!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } on UnimplementedError {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download is only available on web. Use screenshot instead.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading QR code: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showQRCode(TableModel table) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Table ${table.tableNumber}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: QrImageView(
                  data: table.qrCodeData,
                  version: QrVersions.auto,
                  size: 250,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Scan this QR code to order',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _downloadQRCode(table);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: table.qrCodeData));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR data copied to clipboard'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Data'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTable(TableModel table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Are you sure you want to delete ${table.tableNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _tableRepo.deleteTable(table.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Table deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _loadTables();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tables'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTables,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading tables...')
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppTheme.errorColor),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTables,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tables.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.table_restaurant,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No tables yet'),
                          const SizedBox(height: 8),
                          const Text(
                            'Create tables to generate QR codes',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showBulkCreateDialog,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Create Tables'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTables,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tables.length,
                        itemBuilder: (context, index) {
                          final table = _tables[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: table.isActive
                                      ? AppTheme.primaryColor
                                          .withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    table.tableNumber,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: table.isActive
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                'Table ${table.tableNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Capacity: ${table.capacity} people'),
                                  if (table.location.isNotEmpty)
                                    Text('Location: ${table.location}'),
                                  if (table.currentSession?.isOccupied == true)
                                    const Text(
                                      'Currently occupied',
                                      style: TextStyle(
                                        color: AppTheme.warningColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.qr_code),
                                    color: AppTheme.primaryColor,
                                    onPressed: () => _showQRCode(table),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: AppTheme.errorColor,
                                    onPressed: () => _deleteTable(table),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: _tables.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'bulk',
                  onPressed: _showBulkCreateDialog,
                  backgroundColor: AppTheme.secondaryColor,
                  child: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'single',
                  onPressed: _showCreateTableDialog,
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : null,
    );
  }
}
