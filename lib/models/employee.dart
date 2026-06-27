class Employee {
  final String id;
  final String name;
  final String phone;
  final String pinCode;
  final String role; // 'manager', 'cashier'
  final bool isActive;
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.pinCode,
    required this.role,
    this.isActive = true,
    this.isSynced = false,
    this.isDeleted = false,
    required this.updatedAt,
  });

  Employee copyWith({
    String? id,
    String? name,
    String? phone,
    String? pinCode,
    String? role,
    bool? isActive,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      pinCode: pinCode ?? this.pinCode,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'pin_code': pinCode,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      pinCode: map['pin_code'] ?? '',
      role: map['role'] ?? 'cashier',
      isActive: (map['is_active'] ?? 1) == 1,
      isSynced: (map['is_synced'] ?? 0) == 1,
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }
}
