import '../core/database_helper.dart';
import '../models/employee.dart';

class EmployeeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Employee>> getAllEmployees() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'is_deleted = 0',
    );
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  Future<Employee?> getEmployeeById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  Future<Employee?> getEmployeeByPin(String pin) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'pin_code = ? AND is_active = 1 AND is_deleted = 0',
      whereArgs: [pin],
    );
    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  Future<int> insertEmployee(Employee employee) async {
    final db = await _dbHelper.database;
    return await db.insert('employees', employee.toMap());
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await _dbHelper.database;
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  // Soft delete to support synchronization later
  Future<int> deleteEmployeeSoft(String id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'employees',
      {
        'is_deleted': 1,
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
