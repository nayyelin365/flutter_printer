import 'package:flutter/material.dart';

import '../usb_printer_service.dart';
import '../zpl_commands.dart';

class ZplPrinterScreen extends StatefulWidget {
  const ZplPrinterScreen({super.key});

  @override
  State<ZplPrinterScreen> createState() => _ZplPrinterScreenState();
}

class _ZplPrinterScreenState extends State<ZplPrinterScreen> {
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

  Future<void> _printLabel(String labelType) async {
    if (!_printerService.isConnected) {
      _showError('No printer connected');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final labelData = switch (labelType) {
        'shipping' => ZplCommands.sampleShippingLabel(),
        'product' => ZplCommands.sampleProductLabel(),
        'inventory' => ZplCommands.sampleInventoryLabel(),
        'asset' => ZplCommands.sampleAssetTag(),
        _ => ZplCommands.sampleProductLabel(),
      };

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

  Future<void> _printSushiLabel() async {
    if (!_printerService.isConnected) {
      _showError('No printer connected');
      return;
    }

    setState(() => _isLoading = true);

    try {
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
        title: const Text('ZPL Label Printer (Zebra)'),
        backgroundColor: Colors.orange.shade100,
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
                    Icons.qr_code_2,
                    color: isConnected ? Colors.green : Colors.orange,
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
              onPressed: () => _printLabel('shipping'),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Print Shipping Label'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange.shade50,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _printLabel('product'),
              icon: const Icon(Icons.inventory_2),
              label: const Text('Print Product Label'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange.shade50,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _printLabel('inventory'),
              icon: const Icon(Icons.warehouse),
              label: const Text('Print Inventory Label'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange.shade50,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _printLabel('asset'),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Print Asset Tag'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange.shade50,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _printSushiLabel,
              icon: const Icon(Icons.restaurant),
              label: const Text('Print Sushi Label'),
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
