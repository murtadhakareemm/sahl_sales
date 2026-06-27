import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/printer_service.dart';
import '../core/sync_service.dart';
import 'employees_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  final _macController = TextEditingController();
  final _ipController = TextEditingController();
  final _cloudUrlController = TextEditingController();

  List<PrinterDevice> _scannedDevices = [];
  bool _isScanning = false;
  String _selectedPrinterMac = '';

  bool _isTestingConnection = false;
  String _connectionTestResult = '';

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    if (state.settings != null) {
      _headerController.text = state.settings!.receiptHeader;
      _footerController.text = state.settings!.receiptFooter;
      _macController.text = state.settings!.printerMacAddress;
      _selectedPrinterMac = state.settings!.printerMacAddress;
    }
    _ipController.text = state.desktopHostIp;
    _cloudUrlController.text = state.cloudServerUrl;
  }

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    _macController.dispose();
    _ipController.dispose();
    _cloudUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(AppState state) async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = '';
    });
    
    final target = state.syncMode == 'local' ? _ipController.text.trim() : _cloudUrlController.text.trim();
    if (target.isEmpty) {
      setState(() {
        _isTestingConnection = false;
        _connectionTestResult = 'يرجى إدخال عنوان الاتصال أولاً';
      });
      return;
    }
    
    try {
      final ok = await SyncService.instance.testConnection(target);
      setState(() {
        _connectionTestResult = ok ? 'تم الاتصال بنجاح! السيرفر نشط.' : 'فشل الاتصال: السيرفر غير مستجيب.';
      });
    } catch (e) {
      setState(() {
        _connectionTestResult = 'خطأ في الاتصال: $e';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _isScanning = true;
      _scannedDevices.clear();
    });

    try {
      final devices = await PrinterService.instance.scanBluetoothPrinters();
      setState(() {
        _scannedDevices = devices;
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectPrinter(PrinterDevice device, AppState state) async {
    final success = await PrinterService.instance.connectToPrinter(device);
    if (success) {
      _selectedPrinterMac = device.address;
      _macController.text = device.address;
      await state.updatePrinterSettings(_selectedPrinterMac, _headerController.text.trim(), _footerController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم الاتصال بنجاح بالـ ${device.name}')),
        );
      }
    }
  }

  Future<void> _saveSettings(AppState state) async {
    await state.updatePrinterSettings(
      _macController.text.trim(),
      _headerController.text.trim(),
      _footerController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات الطباعة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    final primary = meta.primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Theme and Store customization switcher
          _buildSectionHeader('تخصيص النشاط وثيم التطبيق (13 تصنيفاً تجارياً مخصصة)', Icons.palette_rounded, primary),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: AppTheme.categories.length,
            itemBuilder: (context, index) {
              final cat = AppTheme.categories[index];
              final isSelected = state.activeThemeCategory == cat.key;

              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? cat.primaryColor.withOpacity(0.08) : Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isSelected ? cat.primaryColor : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () async {
                    await state.updateStoreCategory(cat.key);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: cat.primaryColor,
                          foregroundColor: Colors.white,
                          radius: 18,
                          child: Icon(cat.icon, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cat.titleAr,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? cat.primaryColor : Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'الوحدة: ${cat.defaultUnit}',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 2. Receipt print Customization
          _buildSectionHeader('تخصيص ترويسة وتذييل الفاتورة', Icons.description_rounded, primary),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _headerController,
                    decoration: const InputDecoration(
                      labelText: 'ترويسة الفاتورة (أعلى الوصل)',
                      prefixIcon: Icon(Icons.arrow_drop_up_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _footerController,
                    decoration: const InputDecoration(
                      labelText: 'تذييل الفاتورة (أسفل الوصل)',
                      prefixIcon: Icon(Icons.arrow_drop_down_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      onPressed: () => _saveSettings(state),
                      child: const Text('حفظ نصوص الفاتورة'),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Bluetooth Print Device settings
          _buildSectionHeader('اتصال طابعة الفواتير بالبلوتوث', Icons.bluetooth_rounded, primary),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          PrinterService.instance.isConnected
                              ? 'متصل حالياً بـ: ${PrinterService.instance.connectedDevice?.name}'
                              : 'حالة الطابعة: غير متصل',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: PrinterService.instance.isConnected ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ),
                      if (PrinterService.instance.isConnected)
                        TextButton(
                          onPressed: () async {
                            await PrinterService.instance.disconnect();
                            setState(() {});
                          },
                          child: const Text('قطع الاتصال', style: TextStyle(color: Colors.red)),
                        )
                    ],
                  ),
                  const Divider(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                    onPressed: _isScanning ? null : _scanPrinters,
                    icon: _isScanning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.bluetooth_searching_rounded),
                    label: Text(_isScanning ? 'جاري البحث...' : 'البحث عن أجهزة البلوتوث القريبة'),
                  ),
                  if (_scannedDevices.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('الأجهزة المتاحة بالقرب منك (انقر للربط):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        itemCount: _scannedDevices.length,
                        itemBuilder: (context, index) {
                          final dev = _scannedDevices[index];
                          final isCurrent = _selectedPrinterMac == dev.address;

                          return ListTile(
                            leading: Icon(Icons.print_rounded, color: isCurrent ? primary : Colors.grey),
                            title: Text(dev.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text('العنوان: ${dev.address}', style: const TextStyle(fontSize: 10)),
                            trailing: isCurrent
                                ? Icon(Icons.check_circle_rounded, color: primary)
                                : const Icon(Icons.circle_outlined, color: Colors.grey),
                            onTap: () => _connectPrinter(dev, state),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Synchronization Settings
          _buildSectionHeader('مزامنة الأجهزة والبيانات المشتركة', Icons.sync_rounded, primary),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sync Mode selection
                  const Text(
                    'اختر طريقة المزامنة والربط:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('شبكة محلية (Wi-Fi)', style: TextStyle(fontSize: 12)),
                          value: 'local',
                          groupValue: state.syncMode,
                          contentPadding: EdgeInsets.zero,
                          activeColor: primary,
                          onChanged: (val) {
                            if (val != null) {
                              state.saveSyncSettings(
                                mode: val,
                                ip: _ipController.text.trim(),
                                cloudUrl: _cloudUrlController.text.trim(),
                              );
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('سيرفر سحابي (Cloud)', style: TextStyle(fontSize: 12)),
                          value: 'cloud',
                          groupValue: state.syncMode,
                          contentPadding: EdgeInsets.zero,
                          activeColor: primary,
                          onChanged: (val) {
                            if (val != null) {
                              state.saveSyncSettings(
                                mode: val,
                                ip: _ipController.text.trim(),
                                cloudUrl: _cloudUrlController.text.trim(),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Display Host Server Controls if on Desktop & Local Sync is active
                  if (state.syncMode == 'local' && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ...[
                    Text(
                      'إعدادات السيرفر الرئيسي للمحل (Desktop Host)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('تشغيل سيرفر المزامنة المحلي', style: TextStyle(fontSize: 12)),
                      subtitle: Text(
                        state.isLocalServerRunning ? 'السيرفر نشط ويستقبل اتصالات الأجهزة' : 'السيرفر متوقف حالياً',
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: state.isLocalServerRunning,
                      activeColor: primary,
                      onChanged: (val) => state.toggleLocalServer(val),
                    ),
                    if (state.isLocalServerRunning) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'العناوين المحلية المتاحة للربط (أدخل أحدها في تطبيق الموبايل):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: state.localIps.map((ip) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: SelectableText(
                              '$ip:8080',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'عدد عمليات المزامنة الناجحة: ${SyncService.instance.syncCount}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                    const Divider(height: 20),
                  ],

                  // Display Client Connection Controls (for mobile client or testing)
                  if (state.syncMode == 'local') ...[
                    const Text(
                      'عنوان جهاز الكمبيوتر الرئيسي (IP Address):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        hintText: 'مثال: 192.168.1.15:8080',
                        prefixIcon: Icon(Icons.laptop_rounded),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      onChanged: (val) {
                        state.saveSyncSettings(
                          mode: state.syncMode,
                          ip: val.trim(),
                          cloudUrl: _cloudUrlController.text.trim(),
                        );
                      },
                    ),
                  ] else ...[
                    const Text(
                      'رابط السيرفر السحابي (Cloud API URL):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cloudUrlController,
                      decoration: const InputDecoration(
                        hintText: 'مثال: https://my-pos-api.com',
                        prefixIcon: Icon(Icons.cloud_rounded),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      onChanged: (val) {
                        state.saveSyncSettings(
                          mode: state.syncMode,
                          ip: _ipController.text.trim(),
                          cloudUrl: val.trim(),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Actions row: Test Connection & Sync Now
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTestingConnection ? null : () => _testConnection(state),
                          icon: _isTestingConnection
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.wifi_tethering_rounded, size: 16),
                          label: const Text('فحص الاتصال', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: primary),
                          onPressed: state.isSyncing ? null : () => state.runClientSync(),
                          icon: state.isSyncing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.sync_rounded, size: 16),
                          label: const Text('مزامنة الآن', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),

                  // Display connection test result or sync status messages
                  if (_connectionTestResult.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _connectionTestResult,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _connectionTestResult.contains('بنجاح') ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ],

                  if (state.syncStatusMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.syncStatusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  const Divider(height: 10),
                  const SizedBox(height: 8),
                  
                  // Display Tenant ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'كود المحل الموحد (Tenant ID):',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      SelectableText(
                        state.settings?.tenantId ?? 'غير متوفر',
                        style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 5. Staff Management Control
          if (state.activeEmployee?.role == 'manager') ...[
            _buildSectionHeader('إدارة كادر العمل والصلاحيات', Icons.badge_rounded, primary),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber[100],
                  foregroundColor: Colors.amber[800],
                  child: const Icon(Icons.people_alt_rounded),
                ),
                title: const Text('إدارة الموظفين والرموز السرية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('إضافة كاشير، تفعيل أو تجميد الموظفين، وضبط صلاحياتهم.', style: TextStyle(fontSize: 10)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: const Text('إدارة الكادر'),
                          backgroundColor: primary,
                        ),
                        body: const Directionality(
                          textDirection: TextDirection.rtl,
                          child: EmployeesScreen(),
                        ),
                      ),
                    ),
                  ).then((_) => state.loadData());
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
