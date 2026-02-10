import 'package:flutter/material.dart';

import '../escpos_commands.dart';
import '../usb_printer_service.dart';

class ReceiptPrinterScreen extends StatefulWidget {
  const ReceiptPrinterScreen({super.key});

  @override
  State<ReceiptPrinterScreen> createState() => _ReceiptPrinterScreenState();
}

class _ReceiptPrinterScreenState extends State<ReceiptPrinterScreen> {
  final UsbPrinterService _printerService = UsbPrinterService();

  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _selectedDevice;
  bool _isLoading = false;
  String _statusMessage = 'No printer connected';

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  @override
  void dispose() {
    _printerService.disconnect();
    super.dispose();
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

  Future<void> _printSampleReceipt() async {
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

  Future<void> _printCustomReceipt() async {
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
        title: const Text('Receipt Printer (ESC/POS)'),
        backgroundColor: Colors.blue.shade100,
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
                  _buildStatusCard(),
                  const SizedBox(height: 16),

                  // Device List
                  _buildDeviceList(),
                  const SizedBox(height: 24),

                  // Print Actions
                  if (_printerService.isConnected) _buildPrintActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
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
    );
  }

  Widget _buildDeviceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              final description = UsbPrinterService.getDeviceDescription(
                device,
              );
              final isConnected =
                  _selectedDevice != null &&
                  _selectedDevice!['vendorId'] == device['vendorId'] &&
                  _selectedDevice!['productId'] == device['productId'];

              return Card(
                color: isConnected ? Colors.green.shade50 : null,
                child: ListTile(
                  leading: Icon(
                    Icons.receipt_long,
                    color: isConnected ? Colors.green : Colors.blue,
                  ),
                  title: Text(description),
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
      ],
    );
  }

  Widget _buildPrintActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Print Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _printSampleReceipt,
              icon: const Icon(Icons.receipt),
              label: const Text('Print Sample Receipt'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _printCustomReceipt,
              icon: const Icon(Icons.edit_note),
              label: const Text('Print Custom Receipt'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
