import '../core/database_helper.dart';
import '../models/store_settings.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<StoreSettings?> getSettings() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('settings', limit: 1);
    if (maps.isEmpty) return null;
    return StoreSettings.fromMap(maps.first);
  }

  Future<int> saveSettings(StoreSettings settings) async {
    final db = await _dbHelper.database;
    // Clear old settings first, maintaining a single row for local configuration
    await db.delete('settings');
    return await db.insert('settings', settings.toMap());
  }

  Future<int> updateSettings(StoreSettings settings) async {
    final db = await _dbHelper.database;
    return await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }
}
