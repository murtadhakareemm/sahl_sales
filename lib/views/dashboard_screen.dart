import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/printer_service.dart';
import 'pos_screen.dart';
import 'inventory_screen.dart';
import 'invoice_history_screen.dart';
import 'employees_screen.dart';
import 'settings_screen.dart';
import 'widgets/sales_chart_painter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    final primary = meta.primaryColor;
    final isManager = state.activeEmployee?.role == 'manager';

    // Sub-screens list
    final List<Widget> screens = [
      _buildHomeScreen(state, primary, meta, isManager),
      const PosScreen(),
      const InventoryScreen(),
      const InvoiceHistoryScreen(),
      const SettingsScreen(),
    ];

    // Navigation items
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        label: 'الرئيسية',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.point_of_sale_rounded),
        label: 'البيع (POS)',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_rounded),
        label: 'المستودع',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_rounded),
        label: 'الفواتير',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_rounded),
        label: 'الإعدادات',
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(meta.icon, size: 24),
              const SizedBox(width: 8),
              Text(
                state.settings?.storeName ?? 'سهل للمبيعات',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            // Dark Mode toggle
            IconButton(
              onPressed: () => state.toggleDarkMode(),
              icon: Icon(state.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            ),
            // Logged employee display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      state.activeEmployee?.name ?? 'زائر',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _confirmLogout(context, state),
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (isWide) {
              return Row(
                children: [
                  _buildSidebar(state, primary, meta),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: screens[_currentIndex]),
                ],
              );
            } else {
              return screens[_currentIndex];
            }
          },
        ),
        bottomNavigationBar: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = MediaQuery.of(context).size.width > 800;
            if (isWide) {
              return const SizedBox.shrink();
            }
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primary,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              items: navItems,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebar(AppState state, Color primary, CategoryMetadata meta) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 240,
      color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Navigation items list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarItem(0, 'الرئيسية', Icons.dashboard_rounded, primary),
                _buildSidebarItem(1, 'البيع (POS)', Icons.point_of_sale_rounded, primary),
                _buildSidebarItem(2, 'المستودع', Icons.inventory_2_rounded, primary),
                _buildSidebarItem(3, 'الفواتير', Icons.receipt_long_rounded, primary),
                _buildSidebarItem(4, 'الإعدادات', Icons.settings_rounded, primary),
              ],
            ),
          ),
          
          // Local Server indicator in sidebar
          if (state.isLocalServerRunning)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_outlined, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('سيرفر المزامنة نشط', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 2),
                          Text(
                            state.localIps.isNotEmpty ? state.localIps.first : '127.0.0.1', 
                            style: const TextStyle(fontSize: 9, color: Colors.green, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Sidebar footer with logout
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
              onTap: () => _confirmLogout(context, state),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon, Color primary) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? primary : Colors.grey),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primary : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 13,
          ),
        ),
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  // Visual Analytics Home View
  Widget _buildHomeScreen(AppState state, Color primary, CategoryMetadata meta, bool isManager) {
    // 1. Calculate stats
    double totalSalesToday = 0;
    int invoiceCountToday = 0;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    for (var inv in state.invoices) {
      if (inv.dateTime.toIso8601String().startsWith(todayStr)) {
        totalSalesToday += inv.total;
        invoiceCountToday++;
      }
    }

    // 2. Compute Weekly sales (Spline Chart)
    final List<double> weeklySales = List.filled(7, 0.0);
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final checkDate = now.subtract(Duration(days: 6 - i));
      final datePrefix = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      double dayTotal = 0.0;
      for (var inv in state.invoices) {
        if (inv.dateTime.toIso8601String().startsWith(datePrefix)) {
          dayTotal += inv.total;
        }
      }
      weeklySales[i] = dayTotal;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dynamic Category Welcome Greeting
          Text(
            'مرحباً بك، ${state.activeEmployee?.name} 👋',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'نوع النشاط النشط: ${meta.titleAr} (${state.settings?.businessType == 'wholesale' ? 'جملة' : (state.settings?.businessType == 'retail' ? 'مفرد' : 'جملة ومفرد')})',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Frosted glass stats cards grid
          Row(
            children: [
              Expanded(
                child: _buildGlassDashboardCard(
                  'مبيعات اليوم',
                  PrinterService.formatIQD(totalSalesToday),
                  Icons.monetization_on_rounded,
                  primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassDashboardCard(
                  'فواتير اليوم',
                  '$invoiceCountToday فاتورة',
                  Icons.receipt_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekly curve spline chart
          SalesSplineChart(weeklySales: weeklySales, primaryColor: primary),
          const SizedBox(height: 20),

          // Action Shortcuts & Alerts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Low stock alert section
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 6),
                            const Text('نواقص المخزن الملحّة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Spacer(),
                            if (state.lowStockProducts.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(10)),
                                child: Text('${state.lowStockProducts.length}', style: TextStyle(fontSize: 10, color: Colors.red[900], fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (state.lowStockProducts.isEmpty)
                          const Text('المخزن متوفر بالكامل ولا توجد نواقص!', style: TextStyle(fontSize: 11, color: Colors.green))
                        else
                          Column(
                            children: state.lowStockProducts.take(3).map((p) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(p.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                    Text('${p.stockQuantity.toStringAsFixed(0)} ${meta.defaultUnit}', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Held/Draft Invoices section
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pause_circle_filled_rounded, color: Colors.blue, size: 20),
                            const SizedBox(width: 6),
                            const Text('الفواتير المعلقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Spacer(),
                            if (state.drafts.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(10)),
                                child: Text('${state.drafts.length}', style: TextStyle(fontSize: 10, color: Colors.blue[900], fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (state.drafts.isEmpty)
                          const Text('لا توجد فواتير معلقة حالياً.', style: TextStyle(fontSize: 11, color: Colors.grey))
                        else
                          Column(
                            children: state.drafts.take(2).map((draft) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(draft.label, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                    TextButton(
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                      onPressed: () {
                                        state.restoreDraft(draft.id);
                                        setState(() {
                                          _currentIndex = 1; // Direct route to POS checkout
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('تم استرجاع السلة المعلقة بنجاح!')),
                                        );
                                      },
                                      child: const Text('استرجاع', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Shortcut Manager Buttons (if manager, show Quick Employees settings link)
          if (isManager) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber[100],
                  foregroundColor: Colors.amber[800],
                  child: const Icon(Icons.badge_rounded),
                ),
                title: const Text('إدارة كادر الموظفين والملفات الشخصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('إضافة كاشير، تفعيل/تعطيل الموظفين، وضبط رموز الدخول PIN.', style: TextStyle(fontSize: 10)),
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
          ],
        ],
      ),
    );
  }

  Widget _buildGlassDashboardCard(String title, String value, IconData icon, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withOpacity(0.1),
            foregroundColor: accentColor,
            radius: 20,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج وإغلاق الجلسة الحالية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              state.logout();
            },
            child: const Text('تسجيل خروج'),
          ),
        ],
      ),
    );
  }
}
