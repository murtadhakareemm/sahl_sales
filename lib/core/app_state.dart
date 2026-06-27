import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/store_settings.dart';
import '../models/employee.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../repositories/settings_repository.dart';
import '../repositories/employee_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/invoice_repository.dart';
import 'sync_service.dart';

class CartItem {
  final Product product;
  double quantity;
  final Map<String, dynamic> selectedAttributes;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.selectedAttributes,
  });

  double get unitPrice {
    // If POS is wholesale, use wholesale price, else retail
    return product.retailPrice;
  }

  double getPrice(String saleType) {
    return saleType == 'wholesale' ? product.wholesalePrice : product.retailPrice;
  }

  double total(String saleType) {
    return getPrice(saleType) * quantity;
  }

  String get attributesSummary {
    if (selectedAttributes.isEmpty) return '';
    List<String> parts = [];
    selectedAttributes.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) {
        parts.add('$k: $v');
      }
    });
    return parts.join(', ');
  }

  // A unique key based on product ID and selected attributes, so that same product with different sizes are separate cart items
  String get cartKey {
    final buffer = StringBuffer(product.id);
    selectedAttributes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))
      ..forEach((entry) => buffer.write('_${entry.key}_${entry.value}'));
    return buffer.toString();
  }
}

class CartDraft {
  final String id;
  final List<CartItem> items;
  final DateTime dateTime;
  final String label;
  final String saleType;

  CartDraft({
    required this.id,
    required this.items,
    required this.dateTime,
    required this.label,
    required this.saleType,
  });
}

class AppState extends ChangeNotifier {
  final SettingsRepository _settingsRepo = SettingsRepository();
  final EmployeeRepository _employeeRepo = EmployeeRepository();
  final ProductRepository _productRepo = ProductRepository();
  final InvoiceRepository _invoiceRepo = InvoiceRepository();

  StoreSettings? _settings;
  Employee? _activeEmployee;
  List<Product> _products = [];
  List<Invoice> _invoices = [];
  List<Employee> _employees = [];
  Map<String, CartItem> _cart = {};
  String _currentSaleType = 'retail'; // 'retail' (مفرد) or 'wholesale' (جملة)
  bool _isDarkMode = false;
  bool _isLoading = false;
  bool _initialized = false;
  List<CartDraft> _drafts = [];

  // Sync state
  String _syncMode = 'local'; // 'local' or 'cloud'
  String _desktopHostIp = '192.168.1.100:8080';
  String _cloudServerUrl = 'https://sahl-pos.com/api';
  bool _isLocalServerRunning = false;
  List<String> _localIps = [];
  String _syncStatusMessage = '';
  bool _isSyncing = false;

  // Licensing state
  String _deviceId = '';
  DateTime? _firstInstallDate;
  String _activationSerial = '';
  bool _isLicensed = false;
  bool _isTrialActive = true;
  int _trialTimeLeftHours = 24;
  String _licensePackageType = 'desktop_offline'; // 'desktop_offline', 'mobile_offline', 'connected_sync'

  // Getters
  StoreSettings? get settings => _settings;
  Employee? get activeEmployee => _activeEmployee;
  List<Product> get products => _products;
  List<Invoice> get invoices => _invoices;
  List<Employee> get employees => _employees;
  Map<String, CartItem> get cart => _cart;
  String get currentSaleType => _currentSaleType;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  List<CartDraft> get drafts => _drafts;

  String get syncMode => _syncMode;
  String get desktopHostIp => _desktopHostIp;
  String get cloudServerUrl => _cloudServerUrl;
  bool get isLocalServerRunning => _isLocalServerRunning;
  List<String> get localIps => _localIps;
  String get syncStatusMessage => _syncStatusMessage;
  bool get isSyncing => _isSyncing;

  String get deviceId => _deviceId;
  DateTime? get firstInstallDate => _firstInstallDate;
  String get activationSerial => _activationSerial;
  bool get isLicensed => _isLicensed;
  bool get isTrialActive => _isTrialActive;
  int get trialTimeLeftHours => _trialTimeLeftHours;
  String get licensePackageType => _licensePackageType;

  String get activeThemeCategory => _settings?.storeCategory ?? 'clothing';

  // Double Check Low Stocks
  List<Product> get lowStockProducts {
    return _products.where((p) => p.stockQuantity <= p.lowStockLimit).toList();
  }

  // Load sync config JSON
  Future<void> loadSyncConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sync_config.json');
      if (await file.exists()) {
        final data = json.decode(await file.readAsString());
        _syncMode = data['syncMode'] ?? 'local';
        _desktopHostIp = data['desktopHostIp'] ?? '192.168.1.100:8080';
        _cloudServerUrl = data['cloudServerUrl'] ?? 'https://sahl-pos.com/api';
      }
      _localIps = await SyncService.instance.getLocalIpAddresses();
    } catch (e) {
      debugPrint('Error loading sync config: $e');
    }
  }

  // Save sync settings
  Future<void> saveSyncSettings({required String mode, required String ip, required String cloudUrl}) async {
    _syncMode = mode;
    _desktopHostIp = ip;
    _cloudServerUrl = cloudUrl;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sync_config.json');
      await file.writeAsString(json.encode({
        'syncMode': _syncMode,
        'desktopHostIp': _desktopHostIp,
        'cloudServerUrl': _cloudServerUrl,
      }));
    } catch (e) {
      debugPrint('Error saving sync config: $e');
    }
  }

  // Toggle local sync server
  Future<void> toggleLocalServer(bool start) async {
    if (start) {
      try {
        _syncStatusMessage = 'جاري تشغيل السيرفر المحلي...';
        notifyListeners();
        
        await SyncService.instance.startServer(8080, onUpdate: () {
          _isLocalServerRunning = SyncService.instance.isRunning;
          notifyListeners();
        });
        
        _isLocalServerRunning = true;
        _syncStatusMessage = 'السيرفر المحلي يعمل بنجاح على المنفذ 8080';
      } catch (e) {
        _isLocalServerRunning = false;
        _syncStatusMessage = 'فشل تشغيل السيرفر: $e';
      }
    } else {
      await SyncService.instance.stopServer(onUpdate: () {
        _isLocalServerRunning = SyncService.instance.isRunning;
        notifyListeners();
      });
      _isLocalServerRunning = false;
      _syncStatusMessage = 'تم إيقاف السيرفر المحلي';
    }
    notifyListeners();
  }

  // Trigger sync process
  Future<void> runClientSync() async {
    if (_isSyncing) return;

    // Enforce license package restrictions for cloud synchronization
    if (_syncMode == 'cloud' && _licensePackageType != 'connected_sync') {
      _syncStatusMessage = 'عذراً، باقة التفعيل الحالية لا تدعم المزامنة السحابية. يرجى الترقية للباقة السحابية المشتركة.';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _syncStatusMessage = 'جاري المزامنة مع السيرفر...';
    notifyListeners();

    final targetUrl = _syncMode == 'local' ? _desktopHostIp : _cloudServerUrl;

    try {
      final result = await SyncService.instance.syncClientWithServer(targetUrl: targetUrl);
      if (result['success'] == true) {
        _syncStatusMessage = 'تمت المزامنة بنجاح! تم رفع ${result['syncedCount']} فاتورة وتحديث المنتجات.';
        await loadData();
      } else {
        _syncStatusMessage = 'خطأ في المزامنة: ${result['error']}';
      }
    } catch (e) {
      _syncStatusMessage = 'فشل الاتصال بالسيرفر: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Load and check licensing
  Future<void> checkLicensing() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/license_config.json');
      if (await file.exists()) {
        final data = json.decode(await file.readAsString());
        _deviceId = data['deviceId'] ?? '';
        _firstInstallDate = data['firstInstallDate'] != null ? DateTime.parse(data['firstInstallDate']) : null;
        _activationSerial = data['activationSerial'] ?? '';
        _licensePackageType = data['licensePackageType'] ?? 'desktop_offline';
      }

      if (_deviceId.isEmpty) {
        _deviceId = 'DEV-${const Uuid().v4().substring(0, 8).toUpperCase()}';
        _firstInstallDate = DateTime.now();
        await saveLicensingConfig();
      }

      // Check and import external sahl_config.json configurations if present
      await _importExternalConfiguration();

      _isLicensed = _verifySerialKey(_activationSerial);

      if (_isLicensed) {
        _isTrialActive = false;
        _trialTimeLeftHours = 0;
        final details = _getLicenseDetails(_activationSerial);
        if (details != null) {
          _licensePackageType = details['packageType'] ?? 'desktop_offline';
        }
      } else {
        final diff = DateTime.now().difference(_firstInstallDate!);
        final hoursElapsed = diff.inHours;
        if (hoursElapsed < 24) {
          _isTrialActive = true;
          _trialTimeLeftHours = 24 - hoursElapsed;
        } else {
          _isTrialActive = false;
          _trialTimeLeftHours = 0;
        }
      }
    } catch (e) {
      debugPrint('Error checking licensing: $e');
    }
  }

  Future<List<File>> _getExternalConfigFiles() async {
    List<File> files = [];
    try {
      // 1. Current working directory
      files.add(File('sahl_config.json'));
      
      // 2. Downloads or Documents directory
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        files.add(File('${downloadsDir.path}/sahl_config.json'));
      }
      final docsDir = await getApplicationDocumentsDirectory();
      files.add(File('${docsDir.path}/sahl_config.json'));
      
      // 3. Android specific path
      if (Platform.isAndroid) {
        files.add(File('/storage/emulated/0/Download/sahl_config.json'));
      }
    } catch (_) {}
    return files;
  }

  Future<void> _importExternalConfiguration() async {
    try {
      final configFiles = await _getExternalConfigFiles();
      File? targetFile;

      for (var file in configFiles) {
        if (await file.exists()) {
          targetFile = file;
          break;
        }
      }

      if (targetFile != null) {
        final content = await targetFile.readAsString();
        final Map<String, dynamic> data = json.decode(content);

        final serial = data['activationSerial'] ?? '';
        final deviceIdVal = data['deviceId'] ?? '';
        final packageType = data['licensePackageType'] ?? 'desktop_offline';
        final serverUrlVal = data['serverUrl'] ?? '';
        final tenantIdVal = data['tenantId'] ?? '';

        if (serial.isNotEmpty && deviceIdVal.isNotEmpty) {
          final originalDeviceId = _deviceId;
          // Temporarily swap to verify signature
          _deviceId = deviceIdVal;

          final isValid = _verifySerialKey(serial);
          if (isValid) {
            _deviceId = deviceIdVal;
            _activationSerial = serial;
            _licensePackageType = packageType;
            _isLicensed = true;
            _isTrialActive = false;
            _trialTimeLeftHours = 0;

            await saveLicensingConfig();

            if (serverUrlVal.isNotEmpty || tenantIdVal.isNotEmpty) {
              _syncMode = tenantIdVal.isNotEmpty ? 'cloud' : 'local';
              _cloudServerUrl = serverUrlVal;
              await saveSyncSettings(
                mode: _syncMode,
                ip: _desktopHostIp,
                cloudUrl: _cloudServerUrl,
              );
            }

            // Cleanup imported configuration file
            try {
              await targetFile.delete();
            } catch (_) {
              try {
                await targetFile.rename('${targetFile.path}.imported');
              } catch (_) {}
            }
          } else {
            // Restore original device ID
            _deviceId = originalDeviceId;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> saveLicensingConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/license_config.json');
      await file.writeAsString(json.encode({
        'deviceId': _deviceId,
        'firstInstallDate': _firstInstallDate?.toIso8601String(),
        'activationSerial': _activationSerial,
        'licensePackageType': _licensePackageType,
      }));
    } catch (e) {
      debugPrint('Error saving license config: $e');
    }
  }

  Map<String, dynamic>? _getLicenseDetails(String serial) {
    if (serial.trim().isEmpty) return null;
    try {
      final decodedStr = utf8.decode(base64.decode(serial.trim()));
      final parts = decodedStr.split('|');
      if (parts.length != 4) return null;

      final deviceIdPart = parts[0];
      final expiryTimestamp = int.parse(parts[1]);
      final licenseType = parts[2]; // packageType
      final signature = parts[3];

      if (deviceIdPart != _deviceId) return null;

      final plaintext = '$deviceIdPart|$expiryTimestamp|$licenseType';
      const salt = 'SahlSalesPOSSecretSalt2026';

      final keyBytes = utf8.encode(salt);
      final bytes = utf8.encode(plaintext);
      final hmacSha256 = Hmac(sha256, keyBytes);
      final digest = hmacSha256.convert(bytes);

      if (digest.toString() != signature) return null;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);
      return {
        'deviceId': deviceIdPart,
        'expiryDate': expiryDate,
        'packageType': licenseType,
      };
    } catch (_) {
      return null;
    }
  }

  bool _verifySerialKey(String serial) {
    final details = _getLicenseDetails(serial);
    if (details == null) return false;

    final expiryDate = details['expiryDate'] as DateTime;
    if (DateTime.now().isAfter(expiryDate)) return false;

    final packageType = details['packageType'] as String;
    final isMobilePlatform = Platform.isAndroid || Platform.isIOS;

    if (packageType == 'desktop_offline' && isMobilePlatform) {
      return false; // Not allowed on Mobile
    }
    if (packageType == 'mobile_offline' && !isMobilePlatform) {
      return false; // Not allowed on Desktop
    }
    return true;
  }

  Future<bool> activateLicense(String serial) async {
    final isValid = _verifySerialKey(serial);
    if (isValid) {
      final details = _getLicenseDetails(serial);
      _activationSerial = serial.trim();
      _isLicensed = true;
      _isTrialActive = false;
      _trialTimeLeftHours = 0;
      if (details != null) {
        _licensePackageType = details['packageType'] ?? 'desktop_offline';
      }
      await saveLicensingConfig();
      notifyListeners();
      return true;
    }
    return false;
  }

  String getLicenseValidationMessage(String serial) {
    if (serial.trim().isEmpty) return 'يرجى إدخال كود التفعيل أولاً';
    final details = _getLicenseDetails(serial);
    if (details == null) return 'كود التفعيل غير صالح لجهازك أو تم تعديله!';

    final expiryDate = details['expiryDate'] as DateTime;
    if (DateTime.now().isAfter(expiryDate)) return 'انتهت صلاحية كود التفعيل هذا!';

    final packageType = details['packageType'] as String;
    final isMobilePlatform = Platform.isAndroid || Platform.isIOS;

    if (packageType == 'desktop_offline' && isMobilePlatform) {
      return 'عذراً، هذا الكود مخصص لنسخة الديسكتوب فقط ولا يمكن تفعيله على الموبايل!';
    }
    if (packageType == 'mobile_offline' && !isMobilePlatform) {
      return 'عذراً، هذا الكود مخصص لنسخة الموبايل فقط ولا يمكن تفعيله على الديسكتوب!';
    }

    return '';
  }

  // 1. Initialize App Settings
  Future<void> initializeApp() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _settingsRepo.getSettings();
      await loadSyncConfig();
      await checkLicensing();
      if (_settings != null) {
        await loadData();
      }
    } catch (e) {
      // Log DB init errors
    } finally {
      _initialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Database Lists
  Future<void> loadData() async {
    _products = await _productRepo.getAllProducts();
    _invoices = await _invoiceRepo.getAllInvoices();
    _employees = await _employeeRepo.getAllEmployees();
    notifyListeners();
  }

  // 2. Settings & Onboarding wizard
  Future<bool> setupStore({
    required String name,
    required String category,
    required String businessType,
    required String phone,
    required String address,
    required String managerName,
    required String managerPin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final settingsId = const Uuid().v4();
      final storeSettings = StoreSettings(
        id: settingsId,
        storeName: name,
        storeCategory: category,
        businessType: businessType,
        phone: phone,
        address: address,
        receiptHeader: 'مرحباً بكم في $name',
        receiptFooter: 'شكراً لزيارتكم! يرجى الاحتفاظ بالفاتورة',
        printerMacAddress: '',
        tenantId: const Uuid().v4(), // Future Cloud Sync Tenant key
        updatedAt: DateTime.now(),
      );

      // Save Settings
      await _settingsRepo.saveSettings(storeSettings);
      _settings = storeSettings;

      // Create Manager Account
      final manager = Employee(
        id: const Uuid().v4(),
        name: managerName,
        phone: phone,
        pinCode: managerPin,
        role: 'manager',
        isActive: true,
        updatedAt: DateTime.now(),
      );
      await _employeeRepo.insertEmployee(manager);

      _currentSaleType = businessType == 'wholesale' ? 'wholesale' : 'retail';

      await loadData();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle store category (switches theme dynamically)
  Future<void> updateStoreCategory(String categoryKey) async {
    if (_settings == null) return;
    _settings = _settings!.copyWith(
      storeCategory: categoryKey,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await _settingsRepo.updateSettings(_settings!);
    notifyListeners();
  }

  Future<void> updatePrinterSettings(String macAddress, String header, String footer) async {
    if (_settings == null) return;
    _settings = _settings!.copyWith(
      printerMacAddress: macAddress,
      receiptHeader: header,
      receiptFooter: footer,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await _settingsRepo.updateSettings(_settings!);
    notifyListeners();
  }

  // 3. Authentication
  Future<bool> login(String pin) async {
    final emp = await _employeeRepo.getEmployeeByPin(pin);
    if (emp != null) {
      _activeEmployee = emp;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _activeEmployee = null;
    _cart.clear();
    notifyListeners();
  }

  // 4. Products Management
  Future<bool> addProduct(String name, String barcode, double costPrice, double retailPrice, double wholesalePrice, double stock, double lowStock, Map<String, dynamic> attributes) async {
    final newProduct = Product(
      id: const Uuid().v4(),
      name: name,
      barcode: barcode.isEmpty ? 'BAR-${const Uuid().v4().substring(0, 8)}' : barcode,
      costPrice: costPrice,
      retailPrice: retailPrice,
      wholesalePrice: wholesalePrice,
      stockQuantity: stock,
      lowStockLimit: lowStock,
      dynamicAttributes: attributes,
      updatedAt: DateTime.now(),
    );

    final result = await _productRepo.insertProduct(newProduct);
    if (result > 0) {
      await loadData();
      return true;
    }
    return false;
  }

  Future<bool> editProduct(Product product) async {
    final updated = product.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    final result = await _productRepo.updateProduct(updated);
    if (result > 0) {
      await loadData();
      return true;
    }
    return false;
  }

  Future<bool> updateStockQuantity(String id, double quantity) async {
    final result = await _productRepo.updateStockQuantity(id, quantity);
    if (result > 0) {
      await loadData();
      return true;
    }
    return false;
  }

  Future<bool> deleteProduct(String id) async {
    final result = await _productRepo.deleteProductSoft(id);
    if (result > 0) {
      await loadData();
      return true;
    }
    return false;
  }

  // 5. POS Cart Management
  void addToCart(Product product, {double quantity = 1.0, required Map<String, dynamic> selectedAttributes}) {
    final tempItem = CartItem(product: product, quantity: quantity, selectedAttributes: selectedAttributes);
    final key = tempItem.cartKey;

    if (_cart.containsKey(key)) {
      _cart[key]!.quantity += quantity;
    } else {
      _cart[key] = tempItem;
    }
    notifyListeners();
  }

  void updateCartQty(String key, double qty) {
    if (_cart.containsKey(key)) {
      if (qty <= 0) {
        _cart.remove(key);
      } else {
        _cart[key]!.quantity = qty;
      }
      notifyListeners();
    }
  }

  void removeFromCart(String key) {
    _cart.remove(key);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void saveCartAsDraft() {
    if (_cart.isEmpty) return;
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final draftId = const Uuid().v4();
    final draftLabel = 'فاتورة معلقة #${_drafts.length + 1} ($timeStr)';

    _drafts.add(CartDraft(
      id: draftId,
      items: _cart.values.toList(),
      dateTime: now,
      label: draftLabel,
      saleType: _currentSaleType,
    ));
    _cart.clear();
    notifyListeners();
  }

  void restoreDraft(String id) {
    final draftIndex = _drafts.indexWhere((d) => d.id == id);
    if (draftIndex == -1) return;
    final draft = _drafts[draftIndex];

    _cart.clear();
    for (var item in draft.items) {
      _cart[item.cartKey] = item;
    }
    _currentSaleType = draft.saleType;
    _drafts.removeAt(draftIndex);
    notifyListeners();
  }

  void deleteDraft(String id) {
    _drafts.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void setSaleType(String saleType) {
    _currentSaleType = saleType;
    notifyListeners();
  }

  // Cart Totals
  double get cartSubtotal {
    double total = 0.0;
    _cart.forEach((k, item) {
      total += item.total(_currentSaleType);
    });
    return total;
  }

  // 6. Checkout
  Future<Invoice?> checkout({
    required double discount,
    required double paidAmount,
    required String paymentMethod,
    required String customerName,
  }) async {
    if (_cart.isEmpty || _activeEmployee == null) return null;

    final invoiceId = const Uuid().v4();
    final sub = cartSubtotal;
    final total = sub - discount;
    final change = paidAmount > total ? paidAmount - total : 0.0;

    // Generate Invoice number
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final dailyCount = await _invoiceRepo.getInvoiceCountForDate(dateStr);
    final invoiceNo = 'INV-$dateStr-${(dailyCount + 1).toString().padLeft(4, '0')}';

    // Compile items
    List<InvoiceItem> invoiceItems = [];
    _cart.forEach((k, cartItem) {
      invoiceItems.add(InvoiceItem(
        id: const Uuid().v4(),
        invoiceId: invoiceId,
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        quantity: cartItem.quantity,
        unitPrice: cartItem.getPrice(_currentSaleType),
        itemTotal: cartItem.total(_currentSaleType),
        selectedAttributes: cartItem.selectedAttributes,
        updatedAt: now,
      ));
    });

    final invoice = Invoice(
      id: invoiceId,
      invoiceNumber: invoiceNo,
      customerName: customerName.isEmpty ? 'زبون سفري' : customerName,
      dateTime: now,
      employeeId: _activeEmployee!.id,
      saleType: _currentSaleType,
      subtotal: sub,
      discount: discount,
      tax: 0.0,
      total: total,
      paidAmount: paidAmount,
      changeAmount: change,
      paymentMethod: paymentMethod,
      items: invoiceItems,
      updatedAt: now,
    );

    final success = await _invoiceRepo.insertInvoice(invoice);
    if (success) {
      _cart.clear();
      await loadData(); // Reload products (stock is modified) and invoices
      return invoice;
    }
    return null;
  }

  // Refund invoice
  Future<bool> refundInvoice(String id) async {
    final success = await _invoiceRepo.deleteInvoiceSoft(id);
    if (success) {
      await loadData();
      return true;
    }
    return false;
  }

  // 7. Employees Management
  Future<bool> addEmployee(String name, String phone, String pin, String role) async {
    final newEmp = Employee(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      pinCode: pin,
      role: role,
      isActive: true,
      updatedAt: DateTime.now(),
    );
    final result = await _employeeRepo.insertEmployee(newEmp);
    if (result > 0) {
      await loadData();
      return true;
    }
    return false;
  }

  Future<bool> toggleEmployeeStatus(Employee employee) async {
    final updated = employee.copyWith(
      isActive: !employee.isActive,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    final result = await _employeeRepo.updateEmployee(updated);
    if (result > 0) {
      await loadData();
      return true;
    }
    return false;
  }

  Future<bool> deleteEmployee(String id) async {
    final result = await _employeeRepo.deleteEmployeeSoft(id);
    if (result > 0) {
      await loadData();
      return true;
    }
    return false;
  }

  // Theme Toggler
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
