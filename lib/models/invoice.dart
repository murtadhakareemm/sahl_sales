import 'invoice_item.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final DateTime dateTime;
  final String employeeId;
  final String saleType; // 'retail', 'wholesale'
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod; // 'cash', 'debt'
  final List<InvoiceItem> items; // Not stored directly as raw text in invoices table, but parsed alongside it
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.dateTime,
    required this.employeeId,
    required this.saleType,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    this.items = const [],
    this.isSynced = false,
    this.isDeleted = false,
    required this.updatedAt,
  });

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerName,
    DateTime? dateTime,
    String? employeeId,
    String? saleType,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    double? paidAmount,
    double? changeAmount,
    String? paymentMethod,
    List<InvoiceItem>? items,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      dateTime: dateTime ?? this.dateTime,
      employeeId: employeeId ?? this.employeeId,
      saleType: saleType ?? this.saleType,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'date_time': dateTime.toIso8601String(),
      'employee_id': employeeId,
      'sale_type': saleType,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, {List<InvoiceItem> items = const []}) {
    return Invoice(
      id: map['id'] ?? '',
      invoiceNumber: map['invoice_number'] ?? '',
      customerName: map['customer_name'] ?? '',
      dateTime: map['date_time'] != null 
          ? DateTime.parse(map['date_time']) 
          : DateTime.now(),
      employeeId: map['employee_id'] ?? '',
      saleType: map['sale_type'] ?? 'retail',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] ?? 'cash',
      items: items,
      isSynced: (map['is_synced'] ?? 0) == 1,
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }
}
