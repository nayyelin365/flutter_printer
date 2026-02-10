import 'dart:convert';
import 'dart:typed_data';

/// TSPL (TSC Printer Language) command generator for label printers
class TsplCommands {
  final List<String> _commands = [];

  /// Set label size in mm
  /// width: label width, height: label height
  TsplCommands size(double widthMm, double heightMm) {
    _commands.add('SIZE $widthMm mm, $heightMm mm');
    return this;
  }

  /// Set gap between labels in mm
  TsplCommands gap(double gapMm, [double offsetMm = 0]) {
    _commands.add('GAP $gapMm mm, $offsetMm mm');
    return this;
  }

  /// Set print speed (1-10)
  TsplCommands speed(int speed) {
    _commands.add('SPEED ${speed.clamp(1, 10)}');
    return this;
  }

  /// Set print density (0-15)
  TsplCommands density(int density) {
    _commands.add('DENSITY ${density.clamp(0, 15)}');
    return this;
  }

  /// Set print direction
  /// direction: 0 = normal, 1 = reversed
  TsplCommands direction(int direction, [int mirror = 0]) {
    _commands.add('DIRECTION ${direction.clamp(0, 1)}, ${mirror.clamp(0, 1)}');
    return this;
  }

  /// Set reference point
  TsplCommands reference(int x, int y) {
    _commands.add('REFERENCE $x, $y');
    return this;
  }

  /// Set offset distance
  TsplCommands offset(double distanceMm) {
    _commands.add('OFFSET $distanceMm mm');
    return this;
  }

  /// Clear image buffer
  TsplCommands cls() {
    _commands.add('CLS');
    return this;
  }

  /// Print text
  /// x, y: position in dots (usually 203 dpi, so 8 dots = 1mm)
  /// font: 1-8 for built-in fonts, or font name
  /// rotation: 0, 90, 180, 270
  /// xMulti, yMulti: magnification (1-10)
  TsplCommands text(
    int x,
    int y,
    String font,
    int rotation,
    int xMulti,
    int yMulti,
    String content,
  ) {
    _commands.add(
      'TEXT $x, $y, "$font", $rotation, $xMulti, $yMulti, "$content"',
    );
    return this;
  }

  /// Print barcode
  /// x, y: position
  /// codeType: 128, 39, 93, EAN13, etc.
  /// height: barcode height in dots
  /// readable: 0 = no text, 1 = text below, 2 = text above, 3 = both
  /// rotation: 0, 90, 180, 270
  /// narrow: narrow bar width
  /// wide: wide bar width
  TsplCommands barcode(
    int x,
    int y,
    String codeType,
    int height,
    int readable,
    int rotation,
    int narrow,
    int wide,
    String content,
  ) {
    _commands.add(
      'BARCODE $x, $y, "$codeType", $height, $readable, $rotation, $narrow, $wide, "$content"',
    );
    return this;
  }

  /// Print Code 128 barcode (simplified)
  TsplCommands barcode128(int x, int y, String content, {int height = 50}) {
    return barcode(x, y, '128', height, 1, 0, 2, 2, content);
  }

  /// Print QR code
  /// x, y: position
  /// eccLevel: L, M, Q, H
  /// cellWidth: module width (1-10)
  /// mode: A = auto, M = manual
  /// rotation: 0, 90, 180, 270
  TsplCommands qrcode(
    int x,
    int y,
    String eccLevel,
    int cellWidth,
    String mode,
    int rotation,
    String content,
  ) {
    _commands.add(
      'QRCODE $x, $y, $eccLevel, $cellWidth, $mode, $rotation, "$content"',
    );
    return this;
  }

  /// Print QR code (simplified)
  TsplCommands qr(int x, int y, String content, {int size = 4}) {
    return qrcode(x, y, 'L', size, 'A', 0, content);
  }

  /// Draw a box
  TsplCommands box(int x, int y, int width, int height, int thickness) {
    _commands.add('BOX $x, $y, ${x + width}, ${y + height}, $thickness');
    return this;
  }

  /// Draw a line
  TsplCommands line(int x1, int y1, int x2, int y2, int thickness) {
    _commands.add('BAR $x1, $y1, ${x2 - x1}, $thickness');
    return this;
  }

  /// Draw horizontal line
  TsplCommands horizontalLine(int x, int y, int length, {int thickness = 2}) {
    _commands.add('BAR $x, $y, $length, $thickness');
    return this;
  }

  /// Draw vertical line
  TsplCommands verticalLine(int x, int y, int length, {int thickness = 2}) {
    _commands.add('BAR $x, $y, $thickness, $length');
    return this;
  }

  /// Print and advance label
  TsplCommands print([int sets = 1, int copies = 1]) {
    _commands.add('PRINT $sets, $copies');
    return this;
  }

  /// Feed labels
  TsplCommands feed(int n) {
    _commands.add('FEED $n');
    return this;
  }

  /// Backfeed labels
  TsplCommands backfeed(int n) {
    _commands.add('BACKFEED $n');
    return this;
  }

  /// Form feed - advance to next label
  TsplCommands formfeed() {
    _commands.add('FORMFEED');
    return this;
  }

  /// Home - feed until gap is detected
  TsplCommands home() {
    _commands.add('HOME');
    return this;
  }

  /// Set cutter
  TsplCommands cut() {
    _commands.add('CUT');
    return this;
  }

  /// Add raw command
  TsplCommands raw(String command) {
    _commands.add(command);
    return this;
  }

  /// Get the command bytes
  Uint8List getBytes() {
    String commandStr = '${_commands.join('\r\n')}\r\n';
    return Uint8List.fromList(utf8.encode(commandStr));
  }

  /// Get commands as string
  String getCommandString() {
    return '${_commands.join('\r\n')}\r\n';
  }

  /// Clear commands
  void clear() {
    _commands.clear();
  }

  /// Helper: Convert mm to dots (at 203 DPI)
  static int mmToDots(double mm, {int dpi = 203}) {
    return (mm * dpi / 25.4).round();
  }

  /// Create a sample shipping label
  static Uint8List sampleShippingLabel() {
    final cmd = TsplCommands()
        .size(100, 60) // 100mm x 60mm label
        .gap(3) // 3mm gap
        .speed(4)
        .density(8)
        .direction(0)
        .cls()
        // Company logo area (placeholder text)
        .text(20, 20, '3', 0, 1, 1, 'ACME SHIPPING')
        // Horizontal line
        .horizontalLine(20, 60, 360)
        // Sender info
        .text(20, 80, '2', 0, 1, 1, 'From: John Doe')
        .text(20, 110, '2', 0, 1, 1, '123 Sender St')
        .text(20, 140, '2', 0, 1, 1, 'New York, NY 10001')
        // Horizontal line
        .horizontalLine(20, 170, 360)
        // Recipient info (larger)
        .text(20, 190, '3', 0, 2, 2, 'TO:')
        .text(20, 240, '3', 0, 1, 1, 'Jane Smith')
        .text(20, 280, '2', 0, 1, 1, '456 Receiver Ave')
        .text(20, 310, '2', 0, 1, 1, 'Los Angeles, CA 90001')
        // Barcode
        .barcode128(20, 360, 'PKG123456789')
        // QR code
        .qr(300, 200, 'https://track.example.com/PKG123456789', size: 5)
        .print(1, 1);

    return cmd.getBytes();
  }

  /// Sushi California Roll label (1.75" x 12" = 44.45mm x 304.8mm)
  /// At 203 DPI: 355 x 2436 dots
  /// NOTE: Many TSC printers have max label length ~100-200mm
  /// This version uses 100mm sections printed as 3 separate labels
  static Uint8List sushiCaliforniaRollLabel({
    String productName = 'SUSHI - CALIFORNIA ROLL',
    String price = '\$9.99',
    String netWeight = '8.5 oz (241 g)',
    String bestByDate = '22 Jul 2025 | 10:30AM',
    String processedOn = '',
    String barcode = '096859',
    int calories = 250,
  }) {
    // Using 100mm max height to avoid printer buffer overflow
    // Original was 304.8mm (12") but most TSC printers max at ~100-200mm
    final cmd = TsplCommands()
        .size(44.45, 100) // 1.75" x ~4" (100mm) - safer for printer buffer
        .gap(2)
        .speed(4)
        .density(10)
        .direction(0)
        .cls();

    // At 203 DPI: 44.45mm = 355 dots width, 100mm = 800 dots height

    // ============ LEFT SECTION - Nutrition Facts (Rotated 90°) ============
    // Green background would need bitmap, using box outline instead
    cmd.box(0, 0, 80, 780, 2);  // Reduced height for 100mm label

    // Nutrition Facts (rotated 90°)
    cmd.text(60, 40, '2', 90, 1, 1, 'Nutrition');
    cmd.text(40, 40, '2', 90, 1, 1, 'Facts');

    // Calories
    cmd.text(60, 180, '1', 90, 1, 1, 'Calories');
    cmd.text(35, 180, '3', 90, 2, 2, calories.toString());

    // ============ CENTER SECTION - Product Info ============
    // "Made Fresh Daily" header
    cmd.text(90, 30, '2', 0, 1, 1, 'Made Fresh Daily');

    // Product name - main title
    cmd.text(90, 60, '3', 0, 1, 1, productName);

    // Ready to Eat & Net Weight
    cmd.text(90, 110, '1', 0, 1, 1, 'Ready To Eat');
    cmd.box(175, 105, 245, 130, 1); // PARTY logo box
    cmd.text(185, 110, '1', 0, 1, 1, 'PARTY');
    cmd.text(260, 110, '1', 0, 1, 1, 'Net Wt: $netWeight');

    // Separator line
    cmd.horizontalLine(90, 140, 260, thickness: 1);

    // Roll ingredients
    cmd.text(90, 150, '1', 0, 1, 1, 'ROLL: IMITATION CRAB, AVOCADO,');
    cmd.text(90, 170, '1', 0, 1, 1, 'CUCUMBER, ROASTED SEAWEED,');
    cmd.text(90, 190, '1', 0, 1, 1, 'SEASONED RICE, SESAME SEEDS.');

    // Topping
    cmd.text(90, 215, '1', 0, 1, 1, 'TOPPING: IMITATION CRAB SALAD,');
    cmd.text(90, 232, '1', 0, 1, 1, 'FRIED ONION, SPICY SAUCE, TEMPURA');
    cmd.text(90, 249, '1', 0, 1, 1, 'CRUNCH, JAPANESE CHILI POWDER');
    cmd.text(90, 266, '1', 0, 1, 1, 'MIXED, GREEN ONION');

    // Allergen badges row 1
    cmd.box(90, 290, 155, 310, 1);
    cmd.text(95, 294, '1', 0, 1, 1, 'NO MSG');

    cmd.box(160, 290, 235, 310, 1);
    cmd.text(165, 294, '1', 0, 1, 1, 'NO SUGAR');

    cmd.box(240, 290, 340, 310, 1);
    cmd.text(245, 294, '1', 0, 1, 1, 'NO MAYO');

    // Allergen badges row 2
    cmd.box(90, 315, 165, 335, 1);
    cmd.text(95, 319, '1', 0, 1, 1, 'DAIRY-FREE');

    cmd.box(170, 315, 240, 335, 1);
    cmd.text(175, 319, '1', 0, 1, 1, 'NUT-FREE');

    cmd.box(245, 315, 340, 335, 1);
    cmd.text(250, 319, '1', 0, 1, 1, 'PEANUT-FREE');

    // Allergy Warning section
    cmd.horizontalLine(90, 345, 260, thickness: 1);
    cmd.text(90, 350, '2', 0, 1, 1, 'ALLERGY WARNING');
    cmd.text(90, 375, '1', 0, 1, 1, 'CONTAIN:');

    // Allergen icons
    cmd.box(140, 372, 175, 388, 1);
    cmd.text(145, 375, '1', 0, 1, 1, 'MILK');

    cmd.box(180, 372, 220, 388, 1);
    cmd.text(185, 375, '1', 0, 1, 1, 'EGGS');

    cmd.box(225, 372, 280, 388, 1);
    cmd.text(230, 375, '1', 0, 1, 1, 'RAWFISH');

    cmd.box(285, 372, 350, 388, 1);
    cmd.text(290, 375, '1', 0, 1, 1, 'SHELLFISH');

    // ============ RIGHT-CENTER - Price & Dates ============
    // Price - large
    cmd.text(250, 30, '4', 0, 2, 2, price);

    // Processed On
    cmd.text(250, 150, '1', 0, 1, 1, 'Processed On');
    if (processedOn.isNotEmpty) {
      cmd.text(250, 170, '1', 0, 1, 1, processedOn);
    }

    // Best if Use By
    cmd.text(250, 195, '1', 0, 1, 1, 'Best if Use By');
    cmd.text(250, 215, '2', 0, 1, 1, bestByDate);

    // Perishable box
    cmd.box(250, 245, 345, 300, 2);
    cmd.text(255, 250, '1', 0, 1, 1, 'PERISHABLE:');
    cmd.text(265, 268, '2', 0, 1, 1, 'KEEP');
    cmd.text(255, 288, '1', 0, 1, 1, 'REFRIGERATED');

    // ============ FAR RIGHT - Barcode & Ingredients (Rotated 90°) ============
    // Barcode (rotated 90°)
    cmd.barcode(340, 50, '128', 80, 1, 90, 2, 2, barcode);

    // Ingredients text (rotated 90°)
    cmd.text(340, 200, '1', 90, 1, 1, 'Ingredients: IMITATION CRAB (Surimi,');
    cmd.text(328, 200, '1', 90, 1, 1, 'Water, Starch, Sugar, Sorbitol, Salt),');
    cmd.text(316, 200, '1', 90, 1, 1, 'AVOCADO, CUCUMBER, ROASTED SEAWEED,');
    cmd.text(304, 200, '1', 90, 1, 1, 'SEASONED RICE (Rice, Water, Vinegar,');
    cmd.text(
      292,
      200,
      '1',
      90,
      1,
      1,
      'Sugar, Salt), SESAME SEEDS, SPICY MAYO.',
    );

    cmd.print(1, 1);

    return cmd.getBytes();
  }
}
