import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String barcode;
  final double costPrice;
  final double retailPrice;
  final double wholesalePrice;
  final double stockQuantity;
  final double lowStockLimit;
  final Map<String, dynamic> dynamicAttributes; // sizes, colors, serial number, karat etc.
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.costPrice,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.stockQuantity,
    required this.lowStockLimit,
    required this.dynamicAttributes,
    this.isSynced = false,
    this.isDeleted = false,
    required this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    double? costPrice,
    double? retailPrice,
    double? wholesalePrice,
    double? stockQuantity,
    double? lowStockLimit,
    Map<String, dynamic>? dynamicAttributes,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockLimit: lowStockLimit ?? this.lowStockLimit,
      dynamicAttributes: dynamicAttributes ?? this.dynamicAttributes,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'cost_price': costPrice,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'stock_quantity': stockQuantity,
      'low_stock_limit': lowStockLimit,
      'dynamic_attributes': jsonEncode(dynamicAttributes),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedAttrs = {};
    if (map['dynamic_attributes'] != null && map['dynamic_attributes'].toString().isNotEmpty) {
      try {
        parsedAttrs = Map<String, dynamic>.from(jsonDecode(map['dynamic_attributes']));
      } catch (e) {
        parsedAttrs = {};
      }
    }
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      retailPrice: (map['retail_price'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      lowStockLimit: (map['low_stock_limit'] as num?)?.toDouble() ?? 0.0,
      dynamicAttributes: parsedAttrs,
      isSynced: (map['is_synced'] ?? 0) == 1,
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }

  // Helpers to fetch specific parameters safely
  List<String> get sizes {
    if (dynamicAttributes.containsKey('sizes')) {
      return List<String>.from(dynamicAttributes['sizes']);
    }
    return [];
  }

  List<String> get colors {
    if (dynamicAttributes.containsKey('colors')) {
      return List<String>.from(dynamicAttributes['colors']);
    }
    return [];
  }
}
