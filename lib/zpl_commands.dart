import 'dart:convert';
import 'dart:typed_data';

/// ZPL (Zebra Programming Language) command generator for Zebra label printers
class ZplCommands {
  final StringBuffer _commands = StringBuffer();

  /// Start a new label format
  ZplCommands startFormat() {
    _commands.write('^XA');
    return this;
  }

  /// End the label format and print
  ZplCommands endFormat() {
    _commands.write('^XZ');
    return this;
  }

  /// Set label home position
  /// x, y: position in dots (typically 203 or 300 dpi)
  ZplCommands labelHome(int x, int y) {
    _commands.write('^LH$x,$y');
    return this;
  }

  /// Set field origin (position for next element)
  /// x, y: position in dots
  ZplCommands fieldOrigin(int x, int y) {
    _commands.write('^FO$x,$y');
    return this;
  }

  /// Set font
  /// font: A-Z (built-in fonts, A=default)
  /// height: font height in dots
  /// width: font width in dots (0=auto)
  ZplCommands font(String font, int height, [int width = 0]) {
    _commands.write('^A${font.toUpperCase()}N,$height,$width');
    return this;
  }

  /// Set scalable font
  /// font: 0 or font name
  /// height: height in dots
  /// width: width in dots
  ZplCommands scalableFont(String font, int height, int width) {
    _commands.write('^A$font,$height,$width');
    return this;
  }

  /// Field data - the actual content to print
  ZplCommands fieldData(String data) {
    _commands.write('^FD$data^FS');
    return this;
  }

  /// Print text at position
  ZplCommands text(
    int x,
    int y,
    String font,
    int height,
    String content, [
    int width = 0,
  ]) {
    fieldOrigin(x, y);
    this.font(font, height, width);
    fieldData(content);
    return this;
  }

  /// Field block for text wrapping
  /// width: maximum width in dots
  /// maxLines: maximum number of lines
  /// lineSpacing: space between lines
  /// alignment: L=left, C=center, R=right, J=justified
  ZplCommands fieldBlock(
    int width,
    int maxLines,
    int lineSpacing,
    String alignment,
  ) {
    _commands.write(
      '^FB$width,$maxLines,$lineSpacing,${alignment.toUpperCase()},0',
    );
    return this;
  }

  /// Print wrapped text block
  ZplCommands textBlock(
    int x,
    int y,
    String font,
    int height,
    int width,
    String content, {
    String alignment = 'L',
    int maxLines = 10,
  }) {
    fieldOrigin(x, y);
    this.font(font, height);
    fieldBlock(width, maxLines, 0, alignment);
    fieldData(content);
    return this;
  }

  /// Draw a graphic box (rectangle or line)
  /// width: box width in dots
  /// height: box height in dots
  /// thickness: border thickness
  /// color: B=black, W=white
  /// rounding: corner rounding (0-8)
  ZplCommands graphicBox(
    int x,
    int y,
    int width,
    int height,
    int thickness, [
    String color = 'B',
    int rounding = 0,
  ]) {
    fieldOrigin(x, y);
    _commands.write('^GB$width,$height,$thickness,$color,$rounding^FS');
    return this;
  }

  /// Draw horizontal line
  ZplCommands horizontalLine(int x, int y, int width, int thickness) {
    return graphicBox(x, y, width, thickness, thickness);
  }

  /// Draw vertical line
  ZplCommands verticalLine(int x, int y, int height, int thickness) {
    return graphicBox(x, y, thickness, height, thickness);
  }

  /// Print Code 128 barcode
  /// x, y: position
  /// height: barcode height in dots
  /// printText: show human readable text (Y/N)
  /// textAbove: text above barcode (Y/N)
  ZplCommands barcode128(
    int x,
    int y,
    String data, {
    int height = 100,
    bool printText = true,
    bool textAbove = false,
  }) {
    fieldOrigin(x, y);
    _commands.write(
      '^BCN,$height,${printText ? 'Y' : 'N'},${textAbove ? 'Y' : 'N'},N',
    );
    fieldData(data);
    return this;
  }

  /// Print Code 39 barcode
  ZplCommands barcode39(
    int x,
    int y,
    String data, {
    int height = 100,
    bool printText = true,
  }) {
    fieldOrigin(x, y);
    _commands.write('^B3N,N,$height,${printText ? 'Y' : 'N'},N');
    fieldData(data);
    return this;
  }

  /// Print EAN-13 barcode
  ZplCommands barcodeEan13(
    int x,
    int y,
    String data, {
    int height = 100,
    bool printText = true,
  }) {
    fieldOrigin(x, y);
    _commands.write('^BEN,$height,${printText ? 'Y' : 'N'},N');
    fieldData(data);
    return this;
  }

  /// Print QR code
  /// x, y: position
  /// data: content to encode
  /// size: magnification (1-10)
  /// errorCorrection: H=high, Q=quartile, M=medium, L=low
  ZplCommands qrCode(
    int x,
    int y,
    String data, {
    int size = 4,
    String errorCorrection = 'Q',
  }) {
    fieldOrigin(x, y);
    _commands.write('^BQN,2,$size');
    fieldData('${errorCorrection}A,$data');
    return this;
  }

  /// Print DataMatrix code
  ZplCommands dataMatrix(int x, int y, String data, {int size = 4}) {
    fieldOrigin(x, y);
    _commands.write('^BXN,$size,200');
    fieldData(data);
    return this;
  }

  /// Set print quantity
  ZplCommands printQuantity(
    int quantity, [
    int pauseCount = 0,
    int replicates = 0,
  ]) {
    _commands.write('^PQ$quantity,$pauseCount,$replicates,N');
    return this;
  }

  /// Set media darkness (print density)
  /// darkness: 0-30 (default ~15)
  ZplCommands mediaDarkness(int darkness) {
    _commands.write('~SD${darkness.clamp(0, 30).toString().padLeft(2, '0')}');
    return this;
  }

  /// Set print speed
  /// speed: 2-14 (depends on printer model)
  ZplCommands printSpeed(int speed) {
    _commands.write('^PR$speed,$speed,$speed');
    return this;
  }

  /// Set label width in dots
  ZplCommands labelWidth(int width) {
    _commands.write('^PW$width');
    return this;
  }

  /// Set label length in dots
  ZplCommands labelLength(int length) {
    _commands.write('^LL$length');
    return this;
  }

  /// Set media type
  /// type: T=thermal transfer, D=direct thermal
  ZplCommands mediaType(String type) {
    _commands.write('^MT${type.toUpperCase()}');
    return this;
  }

  /// Reverse print area (white on black)
  ZplCommands fieldReversePrint() {
    _commands.write('^FR');
    return this;
  }

  /// Comment (not printed)
  ZplCommands comment(String text) {
    _commands.write('^FX$text');
    return this;
  }

  /// Get the ZPL commands as bytes
  Uint8List getBytes() {
    return Uint8List.fromList(utf8.encode(_commands.toString()));
  }

  /// Get raw ZPL string
  String getZpl() {
    return _commands.toString();
  }

  /// Clear commands
  void clear() {
    _commands.clear();
  }

  // ============ Pre-built Label Templates ============

  /// Sample shipping label
  static Uint8List sampleShippingLabel() {
    return ZplCommands()
        .startFormat()
        .labelWidth(812) // 4 inch at 203 dpi
        .labelLength(1218) // 6 inch
        .comment('Shipping Label')
        // Company header
        .text(50, 50, 'A', 50, 'ACME SHIPPING CO.')
        .horizontalLine(50, 120, 712, 3)
        // From address
        .text(50, 150, 'A', 28, 'FROM:')
        .text(50, 190, 'A', 24, 'John Doe')
        .text(50, 220, 'A', 24, '123 Sender Street')
        .text(50, 250, 'A', 24, 'New York, NY 10001')
        // To address
        .horizontalLine(50, 300, 712, 2)
        .text(50, 330, 'A', 35, 'SHIP TO:')
        .text(50, 380, 'A', 40, 'Jane Smith')
        .text(50, 430, 'A', 32, '456 Receiver Avenue')
        .text(50, 475, 'A', 32, 'Los Angeles, CA 90001')
        .text(50, 520, 'A', 32, 'United States')
        // Barcode
        .horizontalLine(50, 580, 712, 2)
        .barcode128(
          150,
          620,
          '1Z999AA10123456784',
          height: 120,
          printText: true,
        )
        // QR code
        .qrCode(
          550,
          800,
          'https://track.example.com/1Z999AA10123456784',
          size: 5,
        )
        // Tracking info
        .text(50, 820, 'A', 24, 'TRACKING #:')
        .text(50, 855, 'A', 28, '1Z999AA10123456784')
        // Service type
        .graphicBox(50, 920, 250, 60, 2)
        .text(70, 935, 'A', 35, 'PRIORITY')
        // Weight
        .text(350, 935, 'A', 28, 'Weight: 2.5 lbs')
        // Date
        .text(
          50,
          1000,
          'A',
          20,
          'Ship Date: ${DateTime.now().toString().substring(0, 10)}',
        )
        .printQuantity(1)
        .endFormat()
        .getBytes();
  }

  /// Sample product label
  static Uint8List sampleProductLabel() {
    return ZplCommands()
        .startFormat()
        .labelWidth(406) // 2 inch at 203 dpi
        .labelLength(609) // 3 inch
        .comment('Product Label')
        // Product name
        .text(20, 30, 'A', 35, 'Widget Pro X')
        // SKU
        .text(20, 80, 'A', 24, 'SKU: WPX-12345')
        // Price
        .graphicBox(20, 120, 180, 60, 2)
        .text(40, 135, 'A', 40, '\$29.99')
        // Barcode
        .barcode128(20, 200, 'WPX12345', height: 80, printText: true)
        // QR code
        .qrCode(250, 120, 'https://example.com/product/WPX12345', size: 4)
        // Description
        .textBlock(
          20,
          320,
          'A',
          20,
          366,
          'Premium quality widget with advanced features. Made in USA.',
          maxLines: 3,
        )
        .printQuantity(1)
        .endFormat()
        .getBytes();
  }

  /// Sample inventory label
  static Uint8List sampleInventoryLabel() {
    return ZplCommands()
        .startFormat()
        .labelWidth(406) // 2 inch
        .labelLength(203) // 1 inch
        .comment('Inventory Label')
        // Location
        .text(10, 10, 'A', 28, 'LOC: A1-B2-C3')
        // Item code barcode
        .barcode128(10, 50, 'INV-2024-001234', height: 50, printText: true)
        // Quantity
        .text(280, 10, 'A', 24, 'QTY: 100')
        .printQuantity(1)
        .endFormat()
        .getBytes();
  }

  /// Sample asset tag
  static Uint8List sampleAssetTag() {
    return ZplCommands()
        .startFormat()
        .labelWidth(406) // 2 inch
        .labelLength(305) // 1.5 inch
        .comment('Asset Tag')
        // Company logo area (placeholder box)
        .graphicBox(20, 15, 80, 40, 2)
        .text(35, 25, 'A', 25, 'CO')
        // Asset number
        .text(120, 20, 'A', 35, 'ASSET TAG')
        // Barcode
        .barcode128(20, 70, 'AST-2024-00001', height: 60, printText: true)
        // DataMatrix for redundancy
        .dataMatrix(300, 70, 'AST-2024-00001', size: 4)
        // Property notice
        .text(20, 160, 'A', 18, 'Property of ACME Corp.')
        .printQuantity(1)
        .endFormat()
        .getBytes();
  }

  /// Custom label builder helper
  static ZplCommands create({int widthDots = 406, int heightDots = 305}) {
    return ZplCommands()
        .startFormat()
        .labelWidth(widthDots)
        .labelLength(heightDots);
  }

  /// Set field orientation for rotated text
  /// rotation: N=normal, R=90°, I=180°, B=270°
  ZplCommands fieldOrientation(String rotation) {
    _commands.write('^FW${rotation.toUpperCase()}');
    return this;
  }

  /// Rotated text at position
  ZplCommands rotatedText(
    int x,
    int y,
    String font,
    int height,
    String content,
    String rotation, [
    int width = 0,
  ]) {
    fieldOrigin(x, y);
    _commands.write('^A${font.toUpperCase()}$rotation,$height,$width');
    fieldData(content);
    return this;
  }

  /// Sushi California Roll label (1.75" x 12" at 203 dpi)
  /// Width: 355 dots, Height: 2436 dots
  static Uint8List sushiCaliforniaRollLabel({
    String productName = 'SUSHI - CALIFORNIA ROLL',
    String price = '\$9.99',
    String netWeight = '8.5 oz (241 g)',
    String bestByDate = '22 Jul 2025 | 10:30AM',
    String processedOn = '',
    String barcode = '096859',
    int calories = 250,
  }) {
    final zpl = ZplCommands();

    // Label dimensions: 1.75" x 12" at 203 dpi
    const int labelWidth = 355; // 1.75 inches
    const int labelHeight = 2436; // 12 inches

    zpl.startFormat().labelWidth(labelWidth).labelLength(labelHeight);

    // ============ LEFT SECTION - Nutrition Facts (Rotated 90°) ============
    // Green background box for nutrition section
    zpl.graphicBox(0, 0, 80, labelHeight, 80, 'B', 0);

    // Nutrition Facts header (rotated)
    zpl.rotatedText(65, 50, 'A', 18, 'Nutrition', 'R');
    zpl.rotatedText(45, 50, 'A', 18, 'Facts', 'R');

    // Calories
    zpl.rotatedText(65, 180, 'A', 16, 'Calories', 'R');
    zpl.rotatedText(40, 180, 'A', 35, calories.toString(), 'R');

    // ============ CENTER SECTION - Product Info ============
    // "Made Fresh Daily" header
    zpl.text(90, 30, 'A', 20, 'Made Fresh Daily');

    // Product name - main title
    zpl.text(90, 60, 'A', 28, productName);

    // Ready to Eat
    zpl.text(90, 100, 'A', 16, 'Ready To Eat');
    zpl.graphicBox(180, 95, 60, 25, 2); // Party logo placeholder
    zpl.text(185, 100, 'A', 14, 'PARTY');

    // Net weight
    zpl.text(250, 100, 'A', 14, 'Net Wt: $netWeight');

    // Horizontal line separator
    zpl.horizontalLine(90, 130, 260, 1);

    // Roll ingredients
    zpl.text(90, 140, 'A', 14, 'ROLL: IMITATION CRAB, AVOCADO,');
    zpl.text(90, 158, 'A', 14, 'CUCUMBER, ROASTED SEAWEED,');
    zpl.text(90, 176, 'A', 14, 'SEASONED RICE, SESAME SEEDS.');

    // Topping
    zpl.text(90, 200, 'A', 12, 'TOPPING: IMITATION CRAB SALAD,');
    zpl.text(90, 215, 'A', 12, 'FRIED ONION, SPICY SAUCE, TEMPURA');
    zpl.text(90, 230, 'A', 12, 'CRUNCH, JAPANESE CHILI POWDER');
    zpl.text(90, 245, 'A', 12, 'MIXED, GREEN ONION');

    // Allergen badges row 1
    zpl.graphicBox(90, 268, 70, 18, 1, 'B', 2);
    zpl.text(93, 272, 'A', 12, 'NO MSG');

    zpl.graphicBox(165, 268, 80, 18, 1, 'B', 2);
    zpl.text(168, 272, 'A', 12, 'NO SUGAR');

    zpl.graphicBox(250, 268, 95, 18, 1, 'B', 2);
    zpl.text(253, 272, 'A', 12, 'NO MAYO');

    // Allergen badges row 2
    zpl.graphicBox(90, 290, 80, 18, 1, 'B', 2);
    zpl.text(93, 294, 'A', 12, 'DAIRY-FREE');

    zpl.graphicBox(175, 290, 75, 18, 1, 'B', 2);
    zpl.text(178, 294, 'A', 12, 'NUT-FREE');

    zpl.graphicBox(255, 290, 90, 18, 1, 'B', 2);
    zpl.text(258, 294, 'A', 12, 'PEANUT-FREE');

    // Allergy Warning section
    zpl.horizontalLine(90, 315, 260, 1);
    zpl.text(90, 320, 'A', 12, 'ALLERGY WARNING');
    zpl.text(90, 335, 'A', 10, 'CONTAIN:');

    // Allergen icons
    zpl.graphicBox(140, 332, 35, 14, 1);
    zpl.text(143, 335, 'A', 10, 'MILK');

    zpl.graphicBox(180, 332, 35, 14, 1);
    zpl.text(183, 335, 'A', 10, 'EGGS');

    zpl.graphicBox(220, 332, 55, 14, 1);
    zpl.text(223, 335, 'A', 10, 'RAWFISH');

    zpl.graphicBox(280, 332, 65, 14, 1);
    zpl.text(283, 335, 'A', 10, 'SHELLFISH');

    // ============ RIGHT-CENTER - Price & Dates ============
    // Price - large and prominent
    zpl.fieldOrigin(250, 30);
    zpl.font('A', 45);
    zpl.fieldData(price);

    // Processed On
    zpl.text(250, 140, 'A', 14, 'Processed On');
    if (processedOn.isNotEmpty) {
      zpl.text(250, 158, 'A', 12, processedOn);
    }

    // Best if Use By
    zpl.text(250, 180, 'A', 14, 'Best if Use By');
    zpl.text(250, 198, 'A', 16, bestByDate);

    // Perishable box
    zpl.graphicBox(250, 220, 95, 45, 2, 'B', 0);
    zpl.text(255, 225, 'A', 14, 'PERISHABLE:');
    zpl.text(265, 242, 'A', 16, 'KEEP');
    zpl.text(255, 258, 'A', 12, 'REFRIGERATED');

    // ============ FAR RIGHT - Barcode & Ingredients (Rotated) ============
    // Barcode (rotated 90°)
    zpl.fieldOrigin(340, 50);
    zpl._commands.write('^BCR,80,Y,N,N');
    zpl.fieldData(barcode);

    // Ingredients text (rotated 90° - running along the length)
    zpl.rotatedText(
      340,
      200,
      'A',
      10,
      'Ingredients: IMITATION CRAB (Surimi, Water,',
      'R',
    );
    zpl.rotatedText(
      330,
      200,
      'A',
      10,
      'Starch, Sugar, Sorbitol, Salt), AVOCADO,',
      'R',
    );
    zpl.rotatedText(
      320,
      200,
      'A',
      10,
      'CUCUMBER, ROASTED SEAWEED, SEASONED RICE',
      'R',
    );
    zpl.rotatedText(
      310,
      200,
      'A',
      10,
      '(Rice, Water, Rice Vinegar, Sugar, Salt),',
      'R',
    );
    zpl.rotatedText(
      300,
      200,
      'A',
      10,
      'SESAME SEEDS, SPICY MAYO, TEMPURA CRUNCH.',
      'R',
    );

    zpl.printQuantity(1).endFormat();

    return zpl.getBytes();
  }
}
