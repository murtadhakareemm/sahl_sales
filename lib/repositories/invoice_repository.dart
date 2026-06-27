import 'package:sqflite/sqflite.dart';
import '../core/database_helper.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class InvoiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Invoice>> getAllInvoices() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'is_deleted = 0',
      orderBy: 'date_time DESC',
    );

    List<Invoice> invoices = [];
    for (var map in maps) {
      final items = await getInvoiceItems(map['id']);
      invoices.add(Invoice.fromMap(map, items: items));
    }
    return invoices;
  }

  Future<Invoice?> getInvoiceById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final items = await getInvoiceItems(id);
    return Invoice.fromMap(maps.first, items: items);
  }

  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_items',
      where: 'invoice_id = ? AND is_deleted = 0',
      whereArgs: [invoiceId],
    );
    return List.generate(maps.length, (i) => InvoiceItem.fromMap(maps[i]));
  }

  /// Inserts invoice, its items, and updates stock quantities in a single transaction
  Future<bool> insertInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;

    try {
      await db.transaction((txn) async {
        // 1. Insert Invoice
        await txn.insert('invoices', invoice.toMap());

        // 2. Insert Invoice Items & Update Stock
        for (var item in invoice.items) {
          // Insert item
          await txn.insert('invoice_items', item.toMap());

          // Fetch current stock
          final List<Map<String, dynamic>> productMap = await txn.query(
            'products',
            columns: ['stock_quantity'],
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          if (productMap.isNotEmpty) {
            double currentStock = (productMap.first['stock_quantity'] as num).toDouble();
            double newStock = currentStock - item.quantity;

            // Update product stock
            await txn.update(
              'products',
              {
                'stock_quantity': newStock,
                'updated_at': DateTime.now().toIso8601String(),
                'is_synced': 0
              },
              where: 'id = ?',
              whereArgs: [item.productId],
            );
          }
        }
      });
      return true;
    } catch (e) {
      // Transaction will automatically roll back on error
      return false;
    }
  }

  Future<int> getInvoiceCountForDate(String dateStr) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM invoices WHERE date_time LIKE ?",
      ['$dateStr%'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Soft delete invoice and all its items (returns stock back to products)
  Future<bool> deleteInvoiceSoft(String id) async {
    final db = await _dbHelper.database;
    try {
      await db.transaction((txn) async {
        final nowStr = DateTime.now().toIso8601String();

        // 1. Get items to restore stock
        final List<Map<String, dynamic>> itemsMaps = await txn.query(
          'invoice_items',
          where: 'invoice_id = ? AND is_deleted = 0',
          whereArgs: [id],
        );

        for (var itemMap in itemsMaps) {
          final itemId = itemMap['id'];
          final productId = itemMap['product_id'];
          final double quantity = (itemMap['quantity'] as num).toDouble();

          // Mark item as deleted
          await txn.update(
            'invoice_items',
            {'is_deleted': 1, 'updated_at': nowStr, 'is_synced': 0},
            where: 'id = ?',
            whereArgs: [itemId],
          );

          // Restore product stock
          final List<Map<String, dynamic>> productMap = await txn.query(
            'products',
            columns: ['stock_quantity'],
            where: 'id = ?',
            whereArgs: [productId],
          );

          if (productMap.isNotEmpty) {
            double currentStock = (productMap.first['stock_quantity'] as num).toDouble();
            double restoredStock = currentStock + quantity;

            await txn.update(
              'products',
              {
                'stock_quantity': restoredStock,
                'updated_at': nowStr,
                'is_synced': 0
              },
              where: 'id = ?',
              whereArgs: [productId],
            );
          }
        }

        // 2. Mark Invoice as deleted
        await txn.update(
          'invoices',
          {'is_deleted': 1, 'updated_at': nowStr, 'is_synced': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
