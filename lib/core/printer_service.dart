import 'dart:async';
import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../models/store_settings.dart';
import '../core/app_theme.dart';
import 'package:intl/intl.dart' hide TextDirection;

class PrinterDevice {
  final String name;
  final String address;
  final bool isConnected;

  PrinterDevice({required this.name, required this.address, this.isConnected = false});
}

class PrinterService {
  static final PrinterService instance = PrinterService._init();
  bool _isConnected = false;
  PrinterDevice? _connectedDevice;

  PrinterService._init();

  bool get isConnected => _isConnected;
  PrinterDevice? get connectedDevice => _connectedDevice;

  // Mock list of nearby Bluetooth thermal printers
  Future<List<PrinterDevice>> scanBluetoothPrinters() async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate scan delay
    return [
      PrinterDevice(name: 'XP-58 Thermal Printer (Bluetooth)', address: '00:11:22:33:AA:BB'),
      PrinterDevice(name: 'MTP-II Mobile Printer', address: '44:55:66:77:CC:DD'),
      PrinterDevice(name: 'Rongta RPP02N Receipt Printer', address: '88:99:AA:BB:EE:FF'),
      PrinterDevice(name: 'Zebra IMZ320 Premium', address: 'AA:BB:CC:DD:11:22'),
    ];
  }

  Future<bool> connectToPrinter(PrinterDevice device) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _isConnected = true;
    _connectedDevice = PrinterDevice(name: device.name, address: device.address, isConnected: true);
    return true;
  }

  Future<void> disconnect() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isConnected = false;
    _connectedDevice = null;
  }

  // Formatting currency safely in Iraqi Dinar
  static String formatIQD(double amount) {
    final formatter = NumberFormat("#,###", "ar_IQ");
    return '${formatter.format(amount)} د.ع';
  }

  // Shows a premium receipt preview dialog with a simulated print trigger
  void showPrintPreview(BuildContext context, Invoice invoice, StoreSettings settings) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        final categoryMeta = AppTheme.getMetadata(settings.storeCategory);
        final accentColor = categoryMeta.primaryColor;
        final formDate = DateFormat('yyyy-MM-dd hh:mm a').format(invoice.dateTime);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Receipt Container with torn paper style
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipPath(
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Center(
                          child: Icon(
                            categoryMeta.icon,
                            size: 36,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            settings.storeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (settings.phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              'هاتف: ${settings.phone}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                        const Divider(height: 24, thickness: 1, color: Colors.black12),

                        // Receipt Details
                        _buildReceiptRow('رقم الفاتورة:', invoice.invoiceNumber),
                        _buildReceiptRow('التاريخ:', formDate),
                        _buildReceiptRow('طريقة الدفع:', invoice.paymentMethod == 'cash' ? 'نقدي' : 'آجل'),
                        _buildReceiptRow('نوع البيع:', invoice.saleType == 'wholesale' ? 'جملة' : 'مفرد'),
                        const Divider(height: 24, thickness: 1, color: Colors.black12),

                        // Items List Header
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(flex: 3, child: Text('المادة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87))),
                              Expanded(flex: 1, child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), textAlign: TextAlign.left)),
                            ],
                          ),
                        ),
                        const Divider(height: 12, thickness: 1, color: Colors.black87),

                        // Items list
                        ...invoice.items.map((item) {
                          String attrSummary = '';
                          if (item.selectedAttributes.isNotEmpty) {
                            attrSummary = ' (${item.selectedAttributes.values.join('/')})';
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${item.productName}$attrSummary',
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        item.quantity.toStringAsFixed(0),
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formatIQD(item.unitPrice),
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 24, thickness: 1, color: Colors.black12),

                        // Totals
                        _buildReceiptRow('المجموع الفرعي:', formatIQD(invoice.subtotal)),
                        if (invoice.discount > 0)
                          _buildReceiptRow('الخصم:', '- ${formatIQD(invoice.discount)}', isRed: true),
                        _buildReceiptRow(
                          'المجموع الكلي:',
                          formatIQD(invoice.total),
                          isBold: true,
                          fontSize: 15,
                        ),
                        const Divider(height: 16, thickness: 1, color: Colors.black12),
                        _buildReceiptRow('الواصل (المدفوع):', formatIQD(invoice.paidAmount)),
                        _buildReceiptRow('المتبقي (الباقي):', formatIQD(invoice.changeAmount)),

                        const SizedBox(height: 16),
                        // Barcode Placeholder
                        Center(
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                width: 180,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '||||  |||||  ||||  |||||',
                                    style: TextStyle(letterSpacing: 4, color: Colors.grey[800], fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(invoice.invoiceNumber, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            settings.receiptFooter,
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Torn paper zig-zag bottom simulation
              CustomPaint(
                size: const Size(320, 12),
                painter: ZigZagPainter(),
              ),

              const SizedBox(height: 16),

              // Printing Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isConnected
                                ? 'جاري الطباعة على ${_connectedDevice?.name}...'
                                : 'محاكاة: تم إرسال أمر الطباعة بنجاح بنسق ESC/POS!',
                            style: const TextStyle(fontFamily: 'Tajawal'),
                          ),
                          backgroundColor: accentColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('طباعة الفاتورة', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق المعاينة'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, double fontSize = 12, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isRed ? Colors.red[700] : (isBold ? Colors.black87 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter to draw zig-zag torn paper effect
class ZigZagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    double x = 0;
    double y = 0;
    double width = 8; // width of each tooth
    double height = 8; // height of each tooth

    while (x < size.width) {
      path.lineTo(x + width / 2, y + height);
      path.lineTo(x + width, y);
      x += width;
    }

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
