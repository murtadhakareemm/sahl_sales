import 'dart:convert';

class InvoiceItem {
  final String id;
  final String invoiceId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double itemTotal;
  final Map<String, dynamic> selectedAttributes; // Selected size, color, serial etc.
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;

  InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.itemTotal,
    required this.selectedAttributes,
    this.isSynced = false,
    this.isDeleted = false,
    required this.updatedAt,
  });

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? itemTotal,
    Map<String, dynamic>? selectedAttributes,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      itemTotal: itemTotal ?? this.itemTotal,
      selectedAttributes: selectedAttributes ?? this.selectedAttributes,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'item_total': itemTotal,
      'selected_attributes': jsonEncode(selectedAttributes),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedAttrs = {};
    if (map['selected_attributes'] != null && map['selected_attributes'].toString().isNotEmpty) {
      try {
        parsedAttrs = Map<String, dynamic>.from(jsonDecode(map['selected_attributes']));
      } catch (e) {
        parsedAttrs = {};
      }
    }
    return InvoiceItem(
      id: map['id'] ?? '',
      invoiceId: map['invoice_id'] ?? '',
      productId: map['product_id'] ?? '',
      productName: map['product_name'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      itemTotal: (map['item_total'] as num?)?.toDouble() ?? 0.0,
      selectedAttributes: parsedAttrs,
      isSynced: (map['is_synced'] ?? 0) == 1,
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }
}
