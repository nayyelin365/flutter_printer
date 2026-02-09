import 'dart:convert';
import 'dart:typed_data';

/// ESC/POS command generator for thermal receipt printers
class EscPosCommands {
  // ESC/POS Command Constants
  static const int esc = 0x1B;
  static const int gs = 0x1D;
  static const int fs = 0x1C;
  static const int lf = 0x0A;
  static const int cr = 0x0D;
  static const int ht = 0x09;
  static const int ff = 0x0C;

  final List<int> _buffer = [];

  /// Initialize printer
  EscPosCommands init() {
    _buffer.addAll([esc, 0x40]); // ESC @
    return this;
  }

  /// Add line feed
  EscPosCommands lineFeed([int lines = 1]) {
    for (int i = 0; i < lines; i++) {
      _buffer.add(lf);
    }
    return this;
  }

  /// Set text alignment
  /// 0 = Left, 1 = Center, 2 = Right
  EscPosCommands setAlign(PrintAlign align) {
    _buffer.addAll([esc, 0x61, align.value]);
    return this;
  }

  /// Set text size
  /// width: 1-8, height: 1-8
  EscPosCommands setTextSize({int width = 1, int height = 1}) {
    int w = (width - 1).clamp(0, 7);
    int h = (height - 1).clamp(0, 7);
    _buffer.addAll([gs, 0x21, (w << 4) | h]);
    return this;
  }

  /// Set bold mode
  EscPosCommands setBold(bool enabled) {
    _buffer.addAll([esc, 0x45, enabled ? 1 : 0]);
    return this;
  }

  /// Set underline mode
  /// 0 = Off, 1 = Single line, 2 = Double line
  EscPosCommands setUnderline(int mode) {
    _buffer.addAll([esc, 0x2D, mode.clamp(0, 2)]);
    return this;
  }

  /// Print text
  EscPosCommands text(String text) {
    _buffer.addAll(latin1.encode(text));
    return this;
  }

  /// Print text with line feed
  EscPosCommands textLine(String text) {
    return this.text(text).lineFeed();
  }

  /// Print a horizontal line
  EscPosCommands horizontalLine({int charCount = 32, String char = '-'}) {
    return textLine(char * charCount);
  }

  /// Print two columns (left and right aligned)
  EscPosCommands twoColumns(String left, String right, {int width = 32}) {
    int spaces = width - left.length - right.length;
    if (spaces < 1) spaces = 1;
    return textLine('$left${' ' * spaces}$right');
  }

  /// Print barcode (Code 128)
  EscPosCommands barcodeCode128(String data, {int height = 80, int width = 2}) {
    // Set barcode height
    _buffer.addAll([gs, 0x68, height]);
    // Set barcode width
    _buffer.addAll([gs, 0x77, width.clamp(2, 6)]);
    // Print HRI below barcode
    _buffer.addAll([gs, 0x48, 2]);
    // Print Code 128
    _buffer.addAll([gs, 0x6B, 73, data.length + 2, 0x7B, 0x42]);
    _buffer.addAll(latin1.encode(data));
    return lineFeed();
  }

  /// Print QR code
  EscPosCommands qrCode(String data, {int size = 6}) {
    // QR Code model
    _buffer.addAll([gs, 0x28, 0x6B, 4, 0, 49, 65, 50, 0]);
    // QR Code size
    _buffer.addAll([gs, 0x28, 0x6B, 3, 0, 49, 67, size.clamp(1, 16)]);
    // QR Code error correction level (L)
    _buffer.addAll([gs, 0x28, 0x6B, 3, 0, 49, 69, 48]);
    // Store QR Code data
    int len = data.length + 3;
    int pL = len % 256;
    int pH = len ~/ 256;
    _buffer.addAll([gs, 0x28, 0x6B, pL, pH, 49, 80, 48]);
    _buffer.addAll(latin1.encode(data));
    // Print QR Code
    _buffer.addAll([gs, 0x28, 0x6B, 3, 0, 49, 81, 48]);
    return lineFeed();
  }

  /// Cut paper (full cut)
  EscPosCommands cutPaper() {
    _buffer.addAll([gs, 0x56, 0x00]);
    return this;
  }

  /// Cut paper (partial cut)
  EscPosCommands cutPaperPartial() {
    _buffer.addAll([gs, 0x56, 0x01]);
    return this;
  }

  /// Feed and cut paper
  EscPosCommands feedAndCut({int lines = 3}) {
    return lineFeed(lines).cutPaper();
  }

  /// Open cash drawer
  EscPosCommands openCashDrawer() {
    _buffer.addAll([esc, 0x70, 0x00, 0x19, 0xFA]);
    return this;
  }

  /// Reset text formatting
  EscPosCommands resetFormatting() {
    setTextSize();
    setBold(false);
    setUnderline(0);
    setAlign(PrintAlign.left);
    return this;
  }

  /// Get the command bytes
  Uint8List getBytes() {
    return Uint8List.fromList(_buffer);
  }

  /// Clear the buffer
  void clear() {
    _buffer.clear();
  }

  /// Create a sample receipt
  static Uint8List sampleReceipt() {
    final cmd = EscPosCommands()
        .init()
        .setAlign(PrintAlign.center)
        .setTextSize(width: 2, height: 2)
        .setBold(true)
        .textLine('STORE NAME')
        .resetFormatting()
        .setAlign(PrintAlign.center)
        .textLine('123 Main Street')
        .textLine('City, State 12345')
        .textLine('Tel: (555) 123-4567')
        .lineFeed()
        .horizontalLine()
        .setAlign(PrintAlign.left)
        .twoColumns('Item 1', '\$10.00')
        .twoColumns('Item 2', '\$15.50')
        .twoColumns('Item 3', '\$8.25')
        .horizontalLine()
        .setBold(true)
        .twoColumns('TOTAL', '\$33.75')
        .resetFormatting()
        .lineFeed()
        .setAlign(PrintAlign.center)
        .textLine('Thank you for shopping!')
        .lineFeed()
        .qrCode('https://example.com/receipt/12345')
        .feedAndCut();

    return cmd.getBytes();
  }
}

enum PrintAlign {
  left(0),
  center(1),
  right(2);

  const PrintAlign(this.value);
  final int value;
}
