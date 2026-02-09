import 'package:drago_usb_printer/drago_usb_printer.dart';
import 'package:flutter/services.dart';

/// Service for managing USB printer connections and printing
class UsbPrinterService {
  final DragoUsbPrinter _usbPrinter = DragoUsbPrinter();

  Map<String, dynamic>? _connectedDevice;

  /// Get list of connected USB devices
  Future<List<Map<String, dynamic>>> getDeviceList() async {
    try {
      List<Map<String, dynamic>> devices =
          await DragoUsbPrinter.getUSBDeviceList();
      return devices;
    } on PlatformException catch (e) {
      throw PrinterException('Failed to get device list: ${e.message}');
    }
  }

  /// Connect to a USB device
  Future<bool> connect(Map<String, dynamic> device) async {
    try {
      int? vendorId = int.tryParse(device['vendorId']?.toString() ?? '');
      int? productId = int.tryParse(device['productId']?.toString() ?? '');

      if (vendorId == null || productId == null) {
        throw PrinterException('Invalid vendor or product ID');
      }

      bool? connected = await _usbPrinter.connect(vendorId, productId);

      if (connected == true) {
        _connectedDevice = device;
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      throw PrinterException('Failed to connect: ${e.message}');
    }
  }

  /// Disconnect from current device
  Future<bool> disconnect() async {
    try {
      await _usbPrinter.close();
      _connectedDevice = null;
      return true;
    } on PlatformException catch (e) {
      throw PrinterException('Failed to disconnect: ${e.message}');
    }
  }

  /// Check if connected to a device
  bool get isConnected => _connectedDevice != null;

  /// Get currently connected device info
  Map<String, dynamic>? get connectedDevice => _connectedDevice;

  /// Write raw bytes to the printer
  Future<bool> write(Uint8List data) async {
    if (!isConnected) {
      throw PrinterException('No printer connected');
    }

    try {
      bool? success = await _usbPrinter.write(data);
      return success ?? false;
    } on PlatformException catch (e) {
      throw PrinterException('Failed to write: ${e.message}');
    }
  }

  /// Print ESC/POS receipt data
  Future<bool> printEscPos(Uint8List escPosData) async {
    return await write(escPosData);
  }

  /// Print TSPL label data
  Future<bool> printTspl(Uint8List tsplData) async {
    return await write(tsplData);
  }

  /// Print ZPL label data (Zebra printers)
  Future<bool> printZpl(Uint8List zplData) async {
    return await write(zplData);
  }

  /// Get device description
  static String getDeviceDescription(Map<String, dynamic> device) {
    String manufacturer = device['manufacturer'] ?? 'Unknown';
    String productName = device['productName'] ?? 'Unknown';
    String vendorId = device['vendorId']?.toString() ?? 'N/A';
    String productId = device['productId']?.toString() ?? 'N/A';

    return '$manufacturer - $productName (VID: $vendorId, PID: $productId)';
  }

  /// Identify printer type based on common vendor IDs
  static PrinterType identifyPrinterType(Map<String, dynamic> device) {
    String productName = (device['productName'] ?? '').toString().toLowerCase();
    String manufacturer = (device['manufacturer'] ?? '')
        .toString()
        .toLowerCase();

    // Common ESC/POS printer manufacturers
    final escPosKeywords = [
      'epson',
      'star',
      'bixolon',
      'citizen',
      'pos',
      'receipt',
      'thermal',
    ];

    // Zebra printers (ZPL language)
    final zplKeywords = ['zebra', 'zpl', 'zd', 'zt', 'zq', 'zc', 'zxp'];

    // Common TSPL label printer manufacturers
    final tsplKeywords = ['tsc', 'label', 'godex', 'argox', 'sato'];

    String combined = '$productName $manufacturer';

    // Check for Zebra printers first (ZPL)
    for (String keyword in zplKeywords) {
      if (combined.contains(keyword)) {
        return PrinterType.zpl;
      }
    }

    for (String keyword in tsplKeywords) {
      if (combined.contains(keyword)) {
        return PrinterType.tspl;
      }
    }

    for (String keyword in escPosKeywords) {
      if (combined.contains(keyword)) {
        return PrinterType.escPos;
      }
    }

    return PrinterType.unknown;
  }
}

/// Printer type enumeration
enum PrinterType { escPos, tspl, zpl, unknown }

/// Custom exception for printer operations
class PrinterException implements Exception {
  final String message;

  PrinterException(this.message);

  @override
  String toString() => 'PrinterException: $message';
}
