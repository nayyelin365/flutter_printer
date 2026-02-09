import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'escpos_commands.dart';
import 'tspl_commands.dart';
import 'usb_printer_service.dart';
import 'zpl_commands.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USB Printer Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PrinterTestPage(),
    );
  }
}

class PrinterTestPage extends StatefulWidget {
  const PrinterTestPage({super.key});

  @override
  State<PrinterTestPage> createState() => _PrinterTestPageState();
}

class _PrinterTestPageState extends State<PrinterTestPage> {
  final UsbPrinterService _printerService = UsbPrinterService();

  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _selectedDevice;
  bool _isLoading = false;
  String _statusMessage = 'No printer connected';
  PrinterType _selectedPrinterType = PrinterType.escPos;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  Future<void> _refreshDevices() async {
    setState(() => _isLoading = true);

    try {
      final devices = await _printerService.getDeviceList();
      setState(() {
        _devices = devices;
        _statusMessage = 'Found ${devices.length} device(s)';
      });
    } catch (e) {
      _showError('Failed to get devices: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    setState(() => _isLoading = true);

    try {
      final connected = await _printerService.connect(device);
      if (connected) {
        setState(() {
          _selectedDevice = device;
          _statusMessage =
              'Connected to ${UsbPrinterService.getDeviceDescription(device)}';
          _selectedPrinterType = UsbPrinterService.identifyPrinterType(device);
        });
        _showSuccess('Connected successfully!');
      } else {
        _showError('Failed to connect');
      }
    } catch (e) {
      _showError('Connection error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnect() async {
    try {
      await _printerService.disconnect();
      setState(() {
        _selectedDevice = null;
        _statusMessage = 'Disconnected';
      });
    } catch (e) {
      _showError('Disconnect error: $e');
    }
  }

  Future<void> _printEscPosReceipt() async {
    if (!_printerService.isConnected) {
      _showError('No printer connected');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final receiptData = EscPosCommands.sampleReceipt();
      final success = await _printerService.printEscPos(receiptData);

      if (success) {
        _showSuccess('Receipt printed!');
      } else {
        _showError('Print failed');
      }
    } catch (e) {
      _showError('Print error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printTsplLabel(String labelType) async {
    if (!_printerService.isConnected) {
      _showError('No printer connected');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final labelData = labelType == 'shipping'
          ? TsplCommands.sampleShippingLabel()
          : TsplCommands.sampleProductLabel();

      final success = await _printerService.printTspl(labelData);

      if (success) {
        _showSuccess('Label printed!');
      } else {
        _showError('Print failed');
      }
    } catch (e) {
      _showError('Print error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printCustomEscPos() async {
    if (!_printerService.isConnected) {
      _showError('No printer connected');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cmd = EscPosCommands()
          .init()
          .setAlign(PrintAlign.center)
          .setTextSize(width: 2, height: 2)
          .textLine('CUSTOM RECEIPT')
          .resetFormatting()
          .lineFeed()
          .setAlign(PrintAlign.left)
          .textLine('Date: ${DateTime.now().toString().substring(0, 19)}')
          .lineFeed()
          .horizontalLine()
          .twoColumns('Test Item', '\$9.99')
          .horizontalLine()
          .setAlign(PrintAlign.center)
          .qrCode('Custom QR Data')
          .feedAndCut();

      final success = await _printerService.write(cmd.getBytes());

      if (success) {
        _showSuccess('Custom receipt printed!');
      }
    } catch (e) {
      _showError('Print error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printCustomTspl() async {
    if (!_printerService.isConnected) {
      _showError('No printer connected');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Print Sushi California Roll label (1.75" x 12")
      final labelData = TsplCommands.sushiCaliforniaRollLabel(
        productName: 'SUSHI - CALIFORNIA ROLL',
        price: '\$9.99',
        netWeight: '8.5 oz (241 g)',
        bestByDate: '22 Jul 2025 | 10:30AM',
        processedOn: '21 Jul 2025',
        barcode: '096859',
        calories: 250,
      );

      final success = await _printerService.write(labelData);

      if (success) {
        _showSuccess('Sushi label printed!');
      }
    } catch (e) {
      _showError('Print error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printZplLabel(String labelType) async {
    if (!_printerService.isConnected) {
      _showError('No printer connected');
      return;
    }

    setState(() => _isLoading = true);

    try {
      late Uint8List labelData;
      switch (labelType) {
        case 'shipping':
          labelData = ZplCommands.sampleShippingLabel();
          break;
        case 'product':
          labelData = ZplCommands.sampleProductLabel();
          break;
        case 'inventory':
          labelData = ZplCommands.sampleInventoryLabel();
          break;
        case 'asset':
          labelData = ZplCommands.sampleAssetTag();
          break;
        default:
          labelData = ZplCommands.sampleProductLabel();
      }

      final success = await _printerService.printZpl(labelData);

      if (success) {
        _showSuccess('ZPL label printed!');
      } else {
        _showError('Print failed');
      }
    } catch (e) {
      _showError('Print error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printCustomZpl() async {
    if (!_printerService.isConnected) {
      _showError('No printer connected');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Print Sushi California Roll label (1.75" x 12")
      final labelData = ZplCommands.sushiCaliforniaRollLabel(
        productName: 'SUSHI - CALIFORNIA ROLL',
        price: '\$9.99',
        netWeight: '8.5 oz (241 g)',
        bestByDate: '22 Jul 2025 | 10:30AM',
        processedOn: '21 Jul 2025',
        barcode: '096859',
        calories: 250,
      );

      final success = await _printerService.write(labelData);

      if (success) {
        _showSuccess('Sushi label printed!');
      }
    } catch (e) {
      _showError('Print error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Printer Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDevices,
            tooltip: 'Refresh devices',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _printerService.isConnected
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                color: _printerService.isConnected
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_statusMessage)),
                            ],
                          ),
                          if (_printerService.isConnected) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _disconnect,
                              icon: const Icon(Icons.link_off),
                              label: const Text('Disconnect'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade100,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Available Devices',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  if (_devices.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No USB devices found.\nConnect a printer and refresh.',
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final description =
                            UsbPrinterService.getDeviceDescription(device);
                        final printerType =
                            UsbPrinterService.identifyPrinterType(device);
                        final isConnected =
                            _selectedDevice != null &&
                            _selectedDevice!['vendorId'] ==
                                device['vendorId'] &&
                            _selectedDevice!['productId'] ==
                                device['productId'];

                        return Card(
                          color: isConnected ? Colors.green.shade50 : null,
                          child: ListTile(
                            leading: Icon(
                              printerType == PrinterType.escPos
                                  ? Icons.receipt_long
                                  : printerType == PrinterType.tspl
                                  ? Icons.label
                                  : printerType == PrinterType.zpl
                                  ? Icons.qr_code
                                  : Icons.print,
                              color: isConnected ? Colors.green : null,
                            ),
                            title: Text(description),
                            subtitle: Text(
                              'Type: ${printerType.name.toUpperCase()}',
                            ),
                            trailing: isConnected
                                ? const Icon(Icons.check, color: Colors.green)
                                : ElevatedButton(
                                    onPressed: () => _connectToDevice(device),
                                    child: const Text('Connect'),
                                  ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  if (_printerService.isConnected) ...[
                    Text(
                      'Printer Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<PrinterType>(
                      segments: const [
                        ButtonSegment(
                          value: PrinterType.escPos,
                          label: Text('ESC/POS'),
                          icon: Icon(Icons.receipt_long),
                        ),
                        ButtonSegment(
                          value: PrinterType.tspl,
                          label: Text('TSPL'),
                          icon: Icon(Icons.label),
                        ),
                        ButtonSegment(
                          value: PrinterType.zpl,
                          label: Text('ZPL'),
                          icon: Icon(Icons.qr_code),
                        ),
                      ],
                      selected: {_selectedPrinterType},
                      onSelectionChanged: (Set<PrinterType> selected) {
                        setState(() => _selectedPrinterType = selected.first);
                      },
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Print Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    if (_selectedPrinterType == PrinterType.escPos) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Receipt Printing (ESC/POS)',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _printEscPosReceipt,
                                icon: const Icon(Icons.receipt),
                                label: const Text('Print Sample Receipt'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _printCustomEscPos,
                                icon: const Icon(Icons.edit_note),
                                label: const Text('Print Custom Receipt'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_selectedPrinterType == PrinterType.tspl) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Label Printing (TSPL)',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _printTsplLabel('shipping'),
                                icon: const Icon(Icons.local_shipping),
                                label: const Text('Print Shipping Label'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _printTsplLabel('product'),
                                icon: const Icon(Icons.inventory_2),
                                label: const Text('Print Product Label'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _printCustomTspl,
                                icon: const Icon(Icons.restaurant),
                                label: const Text('Print Sushi Label'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_selectedPrinterType == PrinterType.zpl) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Label Printing (ZPL - Zebra)',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _printZplLabel('shipping'),
                                icon: const Icon(Icons.local_shipping),
                                label: const Text('Print Shipping Label'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _printZplLabel('product'),
                                icon: const Icon(Icons.inventory_2),
                                label: const Text('Print Product Label'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _printZplLabel('inventory'),
                                icon: const Icon(Icons.warehouse),
                                label: const Text('Print Inventory Label'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _printZplLabel('asset'),
                                icon: const Icon(Icons.qr_code_2),
                                label: const Text('Print Asset Tag'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _printCustomZpl,
                                icon: const Icon(Icons.restaurant),
                                label: const Text('Print Sushi Label'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
