import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/printer_service.dart';
import '../models/invoice.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  String _searchQuery = '';
  String _paymentFilter = 'all'; // 'all', 'cash', 'debt'

  void _showInvoiceDetails(Invoice invoice, AppState state, BuildContext context) {
    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    final isManager = state.activeEmployee?.role == 'manager';

    showDialog(
      context: context,
      builder: (ctx) {
        final formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(invoice.dateTime);
        final employeeName = state.employees.firstWhere((e) => e.id == invoice.employeeId, orElse: () => state.activeEmployee!).name;

        return AlertDialog(
          title: Text(
            'تفاصيل الفاتورة: ${invoice.invoiceNumber}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDetailRow('التاريخ والوقت:', formattedDate),
                  _buildDetailRow('الزبون:', invoice.customerName),
                  _buildDetailRow('المبيعات بواسطة:', employeeName),
                  _buildDetailRow('طريقة السداد:', invoice.paymentMethod == 'cash' ? 'نقدي' : 'آجل (دين)'),
                  _buildDetailRow('نوع التسعير:', invoice.saleType == 'wholesale' ? 'جملة' : 'مفرد'),
                  const Divider(height: 24),
                  const Text('المواد المباعة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),

                  // Items List Table
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[200]),
                        children: const [
                          Padding(padding: EdgeInsets.all(6), child: Text('المادة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(6), child: Text('الكمية', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Padding(padding: EdgeInsets.all(6), child: Text('المجموع', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.left)),
                        ],
                      ),
                      ...invoice.items.map((item) {
                        final attrs = item.selectedAttributes.values.isNotEmpty
                            ? ' (${item.selectedAttributes.values.join('/')})'
                            : '';
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(6), child: Text('${item.productName}$attrs', style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6), child: Text(item.quantity.toStringAsFixed(0), style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                            Padding(padding: const EdgeInsets.all(6), child: Text(PrinterService.formatIQD(item.itemTotal), style: const TextStyle(fontSize: 11), textAlign: TextAlign.left)),
                          ],
                        );
                      }),
                    ],
                  ),

                  const Divider(height: 24),
                  _buildDetailRow('المجموع الفرعي:', PrinterService.formatIQD(invoice.subtotal)),
                  if (invoice.discount > 0)
                    _buildDetailRow('الخصم:', '- ${PrinterService.formatIQD(invoice.discount)}', isRed: true),
                  _buildDetailRow('الصافي الإجمالي:', PrinterService.formatIQD(invoice.total), isBold: true, fontSize: 14, color: meta.primaryColor),
                  const SizedBox(height: 8),
                  _buildDetailRow('المبلغ المدفوع:', PrinterService.formatIQD(invoice.paidAmount)),
                  _buildDetailRow('الباقي المرجع:', PrinterService.formatIQD(invoice.changeAmount)),
                ],
              ),
            ),
          ),
          actions: [
            // Reprint button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
              onPressed: () {
                Navigator.pop(ctx);
                PrinterService.instance.showPrintPreview(context, invoice, state.settings!);
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('معاينة وطباعة'),
            ),
            // Refund / Cancel button (Only managers can cancel invoices!)
            if (isManager)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () => _confirmRefund(invoice, state, ctx),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('إرجاع وإلغاء'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, double fontSize = 12, bool isRed = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isRed ? Colors.red[700] : (color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRefund(Invoice invoice, AppState state, BuildContext dialogContext) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الفاتورة وإرجاع المواد', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من رغبتك في إلغاء الفاتورة رقم (${invoice.invoiceNumber})؟ سيتم إعادة الكميات المباعة إلى المخازن تلقائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation
              Navigator.pop(dialogContext); // Close details dialog

              final success = await state.refundInvoice(invoice.id);
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إلغاء الفاتورة وإرجاع المواد للمستودع بنجاح')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('فشل إلغاء الفاتورة، يرجى المحاولة لاحقاً')),
                  );
                }
              }
            },
            child: const Text('تأكيد الإرجاع'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    final primary = meta.primaryColor;

    // Filter invoices based on search inputs
    final filtered = state.invoices.where((invoice) {
      final matchesNo = invoice.invoiceNumber.contains(_searchQuery);
      final matchesCust = invoice.customerName.contains(_searchQuery);
      final matchesMethod = _paymentFilter == 'all' || invoice.paymentMethod == _paymentFilter;
      return (matchesNo || matchesCust) && matchesMethod;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'البحث برقم الفاتورة أو اسم الزبون...',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _paymentFilter,
                onChanged: (val) {
                  setState(() {
                    _paymentFilter = val!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('كل الفواتير')),
                  DropdownMenuItem(value: 'cash', child: Text('نقدي فقط')),
                  DropdownMenuItem(value: 'debt', child: Text('آجل (دين)')),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),

          // Invoices list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text('لا توجد فواتير مطابقة للبحث حالياً.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final invoice = filtered[index];
                      final dateFormatted = DateFormat('yyyy/MM/dd HH:mm').format(invoice.dateTime);
                      final isDebt = invoice.paymentMethod == 'debt';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDebt ? Colors.red[50] : Colors.green[50],
                            foregroundColor: isDebt ? Colors.red[800] : Colors.green[800],
                            child: Icon(isDebt ? Icons.history_edu_rounded : Icons.monetization_on_rounded),
                          ),
                          title: Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            'التاريخ: $dateFormatted | الزبون: ${invoice.customerName}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    PrinterService.formatIQD(invoice.total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: primary,
                                    ),
                                  ),
                                  Text(
                                    invoice.paymentMethod == 'cash' ? 'واصل نقداً' : 'بالآجل (دين)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDebt ? Colors.red[700] : Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            ],
                          ),
                          onTap: () => _showInvoiceDetails(invoice, state, context),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
