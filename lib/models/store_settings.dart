class StoreSettings {
  final String id;
  final String storeName;
  final String storeCategory;
  final String businessType; // 'retail', 'wholesale', 'both'
  final String phone;
  final String address;
  final String receiptHeader;
  final String receiptFooter;
  final String printerMacAddress;
  final String tenantId;
  final bool isSynced;
  final DateTime updatedAt;

  StoreSettings({
    required this.id,
    required this.storeName,
    required this.storeCategory,
    required this.businessType,
    required this.phone,
    required this.address,
    required this.receiptHeader,
    required this.receiptFooter,
    required this.printerMacAddress,
    required this.tenantId,
    this.isSynced = false,
    required this.updatedAt,
  });

  StoreSettings copyWith({
    String? id,
    String? storeName,
    String? storeCategory,
    String? businessType,
    String? phone,
    String? address,
    String? receiptHeader,
    String? receiptFooter,
    String? printerMacAddress,
    String? tenantId,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return StoreSettings(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      storeCategory: storeCategory ?? this.storeCategory,
      businessType: businessType ?? this.businessType,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      printerMacAddress: printerMacAddress ?? this.printerMacAddress,
      tenantId: tenantId ?? this.tenantId,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_name': storeName,
      'store_category': storeCategory,
      'business_type': businessType,
      'phone': phone,
      'address': address,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'printer_mac_address': printerMacAddress,
      'tenant_id': tenantId,
      'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StoreSettings.fromMap(Map<String, dynamic> map) {
    return StoreSettings(
      id: map['id'] ?? '',
      storeName: map['store_name'] ?? '',
      storeCategory: map['store_category'] ?? 'clothing',
      businessType: map['business_type'] ?? 'both',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      receiptHeader: map['receipt_header'] ?? '',
      receiptFooter: map['receipt_footer'] ?? '',
      printerMacAddress: map['printer_mac_address'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      isSynced: (map['is_synced'] ?? 0) == 1,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }
}
