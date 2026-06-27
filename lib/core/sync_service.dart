import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  HttpServer? _server;
  bool _isRunning = false;
  int _port = 8080;
  int _syncCount = 0;

  bool get isRunning => _isRunning;
  int get port => _port;
  int get syncCount => _syncCount;

  // Get local IP addresses of the machine
  Future<List<String>> getLocalIpAddresses() async {
    List<String> ips = [];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          ips.add(addr.address);
        }
      }
    } catch (e) {
      debugPrint('Error getting IP addresses: $e');
    }
    if (ips.isEmpty) ips.add('127.0.0.1');
    return ips;
  }

  // Start Local HttpServer
  Future<void> startServer(int port, {required VoidCallback onUpdate}) async {
    if (_isRunning) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _port = port;
      _isRunning = true;
      onUpdate();

      _server!.listen((HttpRequest request) async {
        try {
          await _handleRequest(request);
        } catch (e) {
          debugPrint('Error handling request: $e');
          _sendErrorResponse(request, e.toString(), 500);
        }
      });
    } catch (e) {
      _isRunning = false;
      onUpdate();
      rethrow;
    }
  }

  // Stop HttpServer
  Future<void> stopServer({required VoidCallback onUpdate}) async {
    if (!_isRunning) return;
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    onUpdate();
  }

  // Handle incoming HTTP requests on Desktop Host
  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, X-Requested-With');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    final path = request.uri.path;
    if (path == '/api/status' && request.method == 'GET') {
      await _handleStatus(request);
    } else if (path == '/api/products' && request.method == 'GET') {
      await _handleGetProducts(request);
    } else if (path == '/api/sync' && request.method == 'POST') {
      await _handleSync(request);
    } else {
      _sendErrorResponse(request, 'Endpoint not found', 404);
    }
  }

  void _sendErrorResponse(HttpRequest request, String message, int statusCode) {
    try {
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({'success': false, 'error': message}));
      request.response.close();
    } catch (e) {
      debugPrint('Failed to send error response: $e');
    }
  }

  Future<void> _handleStatus(HttpRequest request) async {
    final db = await DatabaseHelper.instance.database;
    final settingsMaps = await db.query('settings');
    
    Map<String, dynamic> settingsData = {};
    if (settingsMaps.isNotEmpty) {
      settingsData = settingsMaps.first;
    }

    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType.json;
    request.response.write(json.encode({
      'success': true,
      'status': 'online',
      'app': 'sahl_sales',
      'store': settingsData['store_name'] ?? 'سهل للمبيعات',
      'category': settingsData['store_category'] ?? 'clothing',
    }));
    await request.response.close();
  }

  Future<void> _handleGetProducts(HttpRequest request) async {
    final db = await DatabaseHelper.instance.database;
    final productsMaps = await db.query('products', where: 'is_deleted = 0');
    
    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType.json;
    request.response.write(json.encode({
      'success': true,
      'products': productsMaps,
    }));
    await request.response.close();
  }

  Future<void> _handleSync(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    final data = json.decode(content) as Map<String, dynamic>;

    final clientInvoices = data['invoices'] as List? ?? [];
    final clientInvoiceItems = data['invoice_items'] as List? ?? [];

    final db = await DatabaseHelper.instance.database;
    List<String> processedInvoiceIds = [];

    await db.transaction((txn) async {
      for (var invMap in clientInvoices) {
        final String invoiceId = invMap['id'];
        
        final existing = await txn.query(
          'invoices',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [invoiceId],
        );
        
        if (existing.isEmpty) {
          await txn.insert('invoices', {
            ...invMap,
            'is_synced': 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          final itemsForInvoice = clientInvoiceItems.where((item) => item['invoice_id'] == invoiceId).toList();
          
          for (var itemMap in itemsForInvoice) {
            await txn.insert('invoice_items', {
              ...itemMap,
              'is_synced': 1,
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            final String productId = itemMap['product_id'];
            final double qty = (itemMap['quantity'] as num).toDouble();

            final List<Map<String, dynamic>> productMap = await txn.query(
              'products',
              columns: ['stock_quantity'],
              where: 'id = ?',
              whereArgs: [productId],
            );

            if (productMap.isNotEmpty) {
              double currentStock = (productMap.first['stock_quantity'] as num).toDouble();
              double newStock = currentStock - qty;

              await txn.update(
                'products',
                {
                  'stock_quantity': newStock,
                  'updated_at': DateTime.now().toIso8601String(),
                  'is_synced': 0,
                },
                where: 'id = ?',
                whereArgs: [productId],
              );
            }
          }
        }
        processedInvoiceIds.add(invoiceId);
      }
    });

    _syncCount++;

    final products = await db.query('products');
    final employees = await db.query('employees');
    final settings = await db.query('settings');

    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType.json;
    request.response.write(json.encode({
      'success': true,
      'synced_invoice_ids': processedInvoiceIds,
      'products': products,
      'employees': employees,
      'settings': settings.isNotEmpty ? settings.first : null,
    }));
    await request.response.close();
  }

  // CLIENT SIDE: Sync local client data with desktop server or remote cloud
  Future<Map<String, dynamic>> syncClientWithServer({
    required String targetUrl,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> unsyncedInvoices = await db.query(
      'invoices',
      where: 'is_synced = 0',
    );

    final List<Map<String, dynamic>> unsyncedItems = await db.query(
      'invoice_items',
      where: 'is_synced = 0',
    );

    String finalUrl = targetUrl.trim();
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'http://$finalUrl';
    }
    if (finalUrl.endsWith('/')) {
      finalUrl = finalUrl.substring(0, finalUrl.length - 1);
    }

    final syncUri = Uri.parse('$finalUrl/api/sync');

    final payload = {
      'invoices': unsyncedInvoices,
      'invoice_items': unsyncedItems,
    };

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    
    try {
      final request = await client.postUrl(syncUri);
      request.headers.contentType = ContentType.json;
      request.write(json.encode(payload));
      
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> result = json.decode(responseBody);

      if (result['success'] == true) {
        final List<dynamic> syncedInvoiceIds = result['synced_invoice_ids'] ?? [];
        final List<dynamic> products = result['products'] ?? [];
        final List<dynamic> employees = result['employees'] ?? [];
        final Map<String, dynamic>? settings = result['settings'];

        await db.transaction((txn) async {
          for (var invId in syncedInvoiceIds) {
            await txn.update(
              'invoices',
              {'is_synced': 1},
              where: 'id = ?',
              whereArgs: [invId],
            );
            await txn.update(
              'invoice_items',
              {'is_synced': 1},
              where: 'invoice_id = ?',
              whereArgs: [invId],
            );
          }

          if (settings != null) {
            await txn.insert(
              'settings',
              {...settings, 'is_synced': 1},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          for (var prodMap in products) {
            await txn.insert(
              'products',
              {...prodMap, 'is_synced': 1},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          for (var empMap in employees) {
            await txn.insert(
              'employees',
              {...empMap, 'is_synced': 1},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });

        return {
          'success': true,
          'syncedCount': syncedInvoiceIds.length,
          'productsCount': products.length,
        };
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'Unknown server error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Connection validation
  Future<bool> testConnection(String targetUrl) async {
    String finalUrl = targetUrl.trim();
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'http://$finalUrl';
    }
    if (finalUrl.endsWith('/')) {
      finalUrl = finalUrl.substring(0, finalUrl.length - 1);
    }

    final uri = Uri.parse('$finalUrl/api/status');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final map = json.decode(body);
        return map['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
