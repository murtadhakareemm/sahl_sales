import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/printer_service.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Add Product Controllers
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _lowStockLimitController = TextEditingController();

  // Custom attributes selectors
  final List<String> _selectedSizes = [];
  final List<String> _selectedColors = [];
  final _customAttrController = TextEditingController(); // scientific name / model / workmanship fee etc

  String _searchQuery = '';
  bool _filterLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _retailPriceController.dispose();
    _wholesalePriceController.dispose();
    _stockController.dispose();
    _lowStockLimitController.dispose();
    _customAttrController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _barcodeController.clear();
    _costPriceController.clear();
    _retailPriceController.clear();
    _wholesalePriceController.clear();
    _stockController.clear();
    _lowStockLimitController.clear();
    _customAttrController.clear();
    setState(() {
      _selectedSizes.clear();
      _selectedColors.clear();
    });
  }

  Future<void> _submitProduct(AppState state) async {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.tryParse(_costPriceController.text) ?? 0.0;
    final retail = double.tryParse(_retailPriceController.text) ?? 0.0;
    final wholesale = double.tryParse(_wholesalePriceController.text) ?? 0.0;
    final stock = double.tryParse(_stockController.text) ?? 0.0;
    final lowStock = double.tryParse(_lowStockLimitController.text) ?? 5.0;

    // Compile dynamic attributes
    final Map<String, dynamic> attributes = {};
    if (_selectedSizes.isNotEmpty) {
      attributes['sizes'] = _selectedSizes;
    }
    if (_selectedColors.isNotEmpty) {
      attributes['colors'] = _selectedColors;
    }

    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    final customVal = _customAttrController.text.trim();
    if (customVal.isNotEmpty) {
      if (meta.hasSerial) attributes['serial'] = customVal;
      if (meta.hasKarat) attributes['karat'] = customVal;
      if (meta.hasCarModel) attributes['car_model'] = customVal;
      if (meta.key == 'pharmacy') attributes['scientific_name'] = customVal;
      if (meta.key == 'perfumes') attributes['scent_notes'] = customVal;
      if (meta.key == 'bookstore') attributes['author_publisher'] = customVal;
      if (meta.key == 'petshop') attributes['animal_type'] = customVal;
    }

    final success = await state.addProduct(
      _nameController.text.trim(),
      _barcodeController.text.trim(),
      cost,
      retail,
      wholesale,
      stock,
      lowStock,
      attributes,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المنتج بنجاح!')),
        );
        _clearForm();
        _tabController.animateTo(0); // Return to list view
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: قد يكون الباركود مستخدماً بالفعل لمنتج آخر')),
        );
      }
    }
  }

  void _showAdjustStockDialog(Product product, AppState state) {
    final qtyController = TextEditingController(text: product.stockQuantity.toStringAsFixed(0));
    final meta = AppTheme.getMetadata(state.activeThemeCategory);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('تعديل مخزون: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الكمية الجديدة بالـ ${meta.defaultUnit}',
                  prefixIcon: const Icon(Icons.inventory_rounded),
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: meta.primaryColor),
              onPressed: () async {
                final qty = double.tryParse(qtyController.text) ?? product.stockQuantity;
                final success = await state.updateStockQuantity(product.id, qty);
                if (success) {
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ التعديل'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Product product, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنتج', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من رغبتك في حذف المنتج (${product.name})؟ سيتم أرشفة المادة محلياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await state.deleteProduct(product.id);
            },
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    final primary = meta.primaryColor;

    // Filter products
    final filtered = state.products.where((p) {
      final nameMatch = p.name.contains(_searchQuery);
      final barcodeMatch = p.barcode.contains(_searchQuery);
      final lowStockFilter = !_filterLowStockOnly || (p.stockQuantity <= p.lowStockLimit);
      return (nameMatch || barcodeMatch) && lowStockFilter;
    }).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: primary.withOpacity(0.04),
          child: TabBar(
            controller: _tabController,
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primary,
            tabs: const [
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'قائمة المواد المتوفرة'),
              Tab(icon: Icon(Icons.add_to_photos_rounded), text: 'إضافة مادة جديدة للمخزن'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Products listing
          _buildProductsListTab(filtered, state, primary, meta),

          // Tab 2: Add Product form
          _buildAddProductTab(state, primary, meta),
        ],
      ),
    );
  }

  Widget _buildProductsListTab(List<Product> products, AppState state, Color primary, CategoryMetadata meta) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search & Filter header
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'البحث عن مادة بالمخزن...',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Filter Low Stock only
              FilterChip(
                label: const Text('المواد المنتهية / القريبة من النفاد'),
                selected: _filterLowStockOnly,
                selectedColor: Colors.red[100],
                labelStyle: TextStyle(
                  color: _filterLowStockOnly ? Colors.red[900] : Colors.black87,
                  fontSize: 12,
                  fontWeight: _filterLowStockOnly ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  setState(() {
                    _filterLowStockOnly = selected;
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 16),

          // Table / Cards list
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text('لا توجد مواد تطابق البحث والفلتر في المخزن.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isLowStock = product.stockQuantity <= product.lowStockLimit;

                      return Card(
                        color: isLowStock ? Colors.red[50] : null,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLowStock ? Colors.red[200] : primary.withOpacity(0.1),
                            foregroundColor: isLowStock ? Colors.red[800] : primary,
                            child: Icon(meta.icon),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'شراء: ${PrinterService.formatIQD(product.costPrice)} | مفرد: ${PrinterService.formatIQD(product.retailPrice)} | جملة: ${PrinterService.formatIQD(product.wholesalePrice)}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'الكمية: ${product.stockQuantity.toStringAsFixed(0)} ${meta.defaultUnit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isLowStock ? Colors.red[900] : Colors.black87,
                                    ),
                                  ),
                                  if (isLowStock)
                                    const Text('يحتاج توريد!', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'adjust') {
                                    _showAdjustStockDialog(product, state);
                                  } else if (value == 'delete') {
                                    _confirmDelete(product, state);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'adjust',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_note_rounded, size: 18),
                                        SizedBox(width: 6),
                                        Text('تعديل المخزون'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                                        SizedBox(width: 6),
                                        Text('حذف المادة', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductTab(AppState state, Color primary, CategoryMetadata meta) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات المادة الرئيسية',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المادة أو المنتج *',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'رقم الباركود (اتركه فارغاً للتوليد التلقائي)',
                prefixIcon: const Icon(Icons.qr_code_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.autorenew_rounded),
                  onPressed: () {
                    // Generate barcode
                    _barcodeController.text = 'BAR-${DateTime.now().microsecondsSinceEpoch.toString().substring(6)}';
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سعر الشراء (التكلفة) *',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (value) => value!.isEmpty ? 'التكلفة مطلوبة' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _retailPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سعر المفرد *',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    validator: (value) => value!.isEmpty ? 'السعر مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _wholesalePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سعر الجملة *',
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                    validator: (value) => value!.isEmpty ? 'سعر الجملة مطلوب' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'الكمية الابتدائية بالـ (${meta.defaultUnit}) *',
                      prefixIcon: const Icon(Icons.inventory_rounded),
                    ),
                    validator: (value) => value!.isEmpty ? 'الكمية مطلوبة' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lowStockLimitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'حد التنبيه بالنفاد (الحد الأدنى) *',
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                    ),
                    validator: (value) => value!.isEmpty ? 'حد النفاد مطلوب' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Dynamic Category Attributes Section (sizes/colors)
            if (meta.defaultSizes.isNotEmpty || meta.key == 'clothing' || meta.key == 'restaurant' || meta.key == 'perfumes' || meta.key == 'petshop') ...[
              Text(
                'الخصائص المتاحة لهذا الموديل (${meta.titleAr})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (meta.defaultSizes.isNotEmpty) ...[
                const Text('المقاسات المتوفرة لهذه المادة:', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: meta.defaultSizes.map((size) {
                    final isChecked = _selectedSizes.contains(size);
                    return FilterChip(
                      label: Text(size),
                      selected: isChecked,
                      selectedColor: primary.withOpacity(0.2),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSizes.add(size);
                          } else {
                            _selectedSizes.remove(size);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Custom Colors (if clothing or shoes)
              if (meta.key == 'clothing' || meta.key == 'shoes') ...[
                const Text('الألوان المتوفرة:', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: ['أسود', 'أبيض', 'أزرق', 'أحمر', 'أخضر', 'رمادي', 'بيج'].map((color) {
                    final isChecked = _selectedColors.contains(color);
                    return FilterChip(
                      label: Text(color),
                      selected: isChecked,
                      selectedColor: primary.withOpacity(0.2),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedColors.add(color);
                          } else {
                            _selectedColors.remove(color);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Custom Text Input depending on fields
            if (meta.hasSerial || meta.hasCarModel || meta.hasKarat || meta.key == 'pharmacy' || meta.key == 'perfumes' || meta.key == 'bookstore' || meta.key == 'petshop') ...[
              Text(
                'مواصفات إضافية للتخصص (${meta.titleAr})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customAttrController,
                decoration: InputDecoration(
                  labelText: meta.hasSerial
                      ? 'الرقم التسلسلي الافتراضي (Serial/IMEI)'
                      : meta.hasCarModel
                          ? 'موديلات السيارات المتوافقة (مثال: نيسان صني 2018-2022)'
                          : meta.key == 'pharmacy'
                              ? 'الاسم العلمي للدواء'
                              : meta.key == 'perfumes'
                                  ? 'النوتة العطرية ومكونات العطر (مثال: عود، مسك، عنبر)'
                                  : meta.key == 'bookstore'
                                      ? 'المؤلف / دار النشر (مثال: د. مصطفى محمود / دار المعارف)'
                                      : meta.key == 'petshop'
                                          ? 'نوع الحيوان الأليف (مثال: قطط، طيور، أسماك)'
                                          : 'أجور الصياغة والمصنعية للغرام الواحد',
                  prefixIcon: const Icon(Icons.info_outline_rounded),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _submitProduct(state),
                icon: const Icon(Icons.save_rounded),
                label: const Text('إضافة المادة وقيدها في المخزن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
