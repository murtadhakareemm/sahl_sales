import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/printer_service.dart';
import '../models/product.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _paidAmountController = TextEditingController();

  final _searchFocusNode = FocusNode();
  final _barcodeFocusNode = FocusNode();
  final _screenFocusNode = FocusNode();

  String _searchQuery = '';
  double _discount = 0.0;
  String _paymentMethod = 'cash'; // 'cash', 'debt'

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _customerNameController.dispose();
    _paidAmountController.dispose();
    _searchFocusNode.dispose();
    _barcodeFocusNode.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _scanBarcode(AppState state) {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    final product = state.products.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => Product(
        id: '',
        name: '',
        barcode: '',
        costPrice: 0,
        retailPrice: 0,
        wholesalePrice: 0,
        stockQuantity: 0,
        lowStockLimit: 0,
        dynamicAttributes: {},
        updatedAt: DateTime.now(),
      ),
    );

    if (product.id.isNotEmpty) {
      _showAttributeSelector(product, state);
      _barcodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المنتج غير موجود في قاعدة البيانات')),
      );
    }
  }

  void _showAttributeSelector(Product product, AppState state) {
    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    String? selectedSize;
    String? selectedColor;
    String customAttr = '';

    // If clothing or shoes, set default size first
    if (meta.defaultSizes.isNotEmpty) {
      // If product has customized sizes in attributes, use them, otherwise use category defaults
      final availableSizes = product.sizes.isNotEmpty ? product.sizes : meta.defaultSizes;
      selectedSize = availableSizes.first;
    }

    final hasColors = product.colors.isNotEmpty;
    if (hasColors) {
      selectedColor = product.colors.first;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableSizes = product.sizes.isNotEmpty ? product.sizes : meta.defaultSizes;
            return AlertDialog(
              title: Text(
                'تخصيص المادة: ${product.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stock check warning
                  Text(
                    'الكمية المتوفرة في المخزن: ${product.stockQuantity} ${meta.defaultUnit}',
                    style: TextStyle(
                      color: product.stockQuantity <= product.lowStockLimit ? Colors.red : Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Size selection UI if applicable
                  if (availableSizes.isNotEmpty) ...[
                    const Text('اختر المقاس:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: availableSizes.map((size) {
                        final isSelected = selectedSize == size;
                        return ChoiceChip(
                          label: Text(size),
                          selected: isSelected,
                          selectedColor: meta.primaryColor,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                          onSelected: (selected) {
                            setModalState(() {
                              selectedSize = size;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Colors selection UI if applicable
                  if (hasColors) ...[
                    const Text('اختر اللون:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: product.colors.map((color) {
                        final isSelected = selectedColor == color;
                        return ChoiceChip(
                          label: Text(color),
                          selected: isSelected,
                          selectedColor: meta.primaryColor,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                          onSelected: (selected) {
                            setModalState(() {
                              selectedColor = color;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Electronics Serial / Gold work fees/ Auto parts compatible text inputs
                  if (meta.hasSerial)
                    TextField(
                      decoration: const InputDecoration(labelText: 'الرقم التسلسلي (IMEI / Serial)'),
                      onChanged: (val) => customAttr = val,
                    ),
                  if (meta.hasKarat)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'عيار الذهب'),
                      value: '21',
                      items: ['18', '21', '22', '24'].map((k) {
                        return DropdownMenuItem(value: k, child: Text('عيار $k'));
                      }).toList(),
                      onChanged: (val) => customAttr = val ?? '21',
                    ),
                  if (meta.hasCarModel)
                    TextField(
                      decoration: const InputDecoration(labelText: 'موديل السيارة المتوافق'),
                      onChanged: (val) => customAttr = val,
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: meta.primaryColor),
                  onPressed: () {
                    final Map<String, dynamic> attrs = {};
                    if (selectedSize != null) attrs['المقاس'] = selectedSize;
                    if (selectedColor != null) attrs['اللون'] = selectedColor;
                    if (customAttr.isNotEmpty) {
                      if (meta.hasSerial) attrs['التسلسلي'] = customAttr;
                      if (meta.hasKarat) attrs['العيار'] = customAttr;
                      if (meta.hasCarModel) attrs['الموديل'] = customAttr;
                    }

                    state.addToCart(product, quantity: 1.0, selectedAttributes: attrs);
                    Navigator.pop(ctx);
                  },
                  child: const Text('إضافة للسلة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCheckoutSheet(AppState state) {
    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    final totalAmount = state.cartSubtotal - _discount;
    _paidAmountController.text = totalAmount.toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentPaid = double.tryParse(_paidAmountController.text) ?? totalAmount;
            final change = currentPaid > totalAmount ? currentPaid - totalAmount : 0.0;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 24,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        'إتمام عملية البيع ودفع الفاتورة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount totals summary
                    Card(
                      color: meta.primaryColor.withOpacity(0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المجموع الكلي:'),
                                Text(
                                  PrinterService.formatIQD(totalAmount),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: meta.primaryColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method selector
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => _paymentMethod = 'cash'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'cash' ? meta.primaryColor : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'دفع نقدي',
                                  style: TextStyle(
                                    color: _paymentMethod == 'cash' ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => _paymentMethod = 'debt'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'debt' ? meta.primaryColor : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'بيع آجل (دين)',
                                  style: TextStyle(
                                    color: _paymentMethod == 'debt' ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Customer Name input
                    TextField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الزبون (اختياري)',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        hintText: 'مثال: أبو أحمد الكرادي',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fast IQD Cash Buttons
                    const Text('فئات الدفع السريع (دينار عراقي):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [10000, 25000, 50000, 75000, 100000].map((val) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: ActionChip(
                              label: Text(PrinterService.formatIQD(val.toDouble()), style: const TextStyle(fontSize: 10)),
                              onPressed: () {
                                setSheetState(() {
                                  _paidAmountController.text = val.toString();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cash paid input & Change calculation
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _paidAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'المبلغ المستلم الواصل',
                              prefixIcon: Icon(Icons.payments_rounded),
                            ),
                            onChanged: (val) {
                              setSheetState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الباقي للزبون', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(
                                  PrinterService.formatIQD(change),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: change > 0 ? Colors.green[800] : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Checkout confirmation button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: meta.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final paid = double.tryParse(_paidAmountController.text) ?? totalAmount;
                        final createdInvoice = await state.checkout(
                          discount: _discount,
                          paidAmount: paid,
                          paymentMethod: _paymentMethod,
                          customerName: _customerNameController.text.trim(),
                        );

                        if (createdInvoice != null) {
                          if (mounted) {
                            Navigator.pop(ctx); // Close sheet
                            _customerNameController.clear();
                            _paidAmountController.clear();
                            setState(() {
                              _discount = 0.0;
                            });

                            // Display Print Receipt dialog
                            PrinterService.instance.showPrintPreview(context, createdInvoice, state.settings!);
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('فشلت العملية، يرجى التحقق من الكميات المتوفرة')),
                            );
                          }
                        }
                      },
                      child: const Text('تأكيد الدفع وحفظ الفاتورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    final primary = meta.primaryColor;

    // Filter products list based on search bar
    final filteredProducts = state.products.where((p) {
      final nameMatches = p.name.contains(_searchQuery);
      final barcodeMatches = p.barcode.contains(_searchQuery);
      return nameMatches || barcodeMatches;
    }).toList();

    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.f1) {
            _searchFocusNode.requestFocus();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.f2) {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
            });
            _barcodeFocusNode.requestFocus();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.f5) {
            if (state.cart.isNotEmpty) {
              _showCheckoutSheet(state);
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.f12) {
            if (state.cart.isNotEmpty) {
              state.saveCartAsDraft();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تعليق السلة وحفظها كمسودة (F12)')),
              );
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          return Row(
            children: [
              // Left block: Products grid / Selection List (takes more space)
              Expanded(
                flex: isWide ? 3 : 5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Search and Mock Barcode Input Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'البحث باسم المادة أو الباركود...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _barcodeController,
                              focusNode: _barcodeFocusNode,
                              decoration: InputDecoration(
                                hintText: 'محاكاة قارئ الباركود...',
                                prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.check_circle_rounded, color: primary),
                                  onPressed: () => _scanBarcode(state),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (val) => _scanBarcode(state),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Products list
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_rounded, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  const Text('لا توجد منتجات مضافة تلبي البحث.', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  TextButton(
                                    onPressed: () {
                                      // Switch tab to Inventory helper
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('الرجاء التوجه لتبويب المستودع لإضافة منتجات')),
                                      );
                                    },
                                    child: const Text('إضافة منتج جديد'),
                                  )
                                ],
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWide ? 3 : 2,
                                childAspectRatio: 1.1,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final isLowStock = product.stockQuantity <= product.lowStockLimit;

                                return Card(
                                  child: InkWell(
                                    onTap: () => _showAttributeSelector(product, state),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'باركود: ${product.barcode}',
                                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                state.currentSaleType == 'wholesale'
                                                    ? PrinterService.formatIQD(product.wholesalePrice)
                                                    : PrinterService.formatIQD(product.retailPrice),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: primary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'المتوفر: ${product.stockQuantity.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: isLowStock ? Colors.red : Colors.black54,
                                                      fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                                    ),
                                                  ),
                                                  if (isLowStock)
                                                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 14),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Right/Side block: POS cart pane
            Container(
              width: isWide ? 300 : 250,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey[350]!)),
                color: state.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              ),
              child: Column(
                children: [
                  // Cart Header & Sale Type toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: primary.withOpacity(0.06),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.shopping_cart_rounded, size: 20),
                                SizedBox(width: 6),
                                Text('السلة الحالية', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.pause_circle_filled_rounded, color: Colors.blue),
                                  onPressed: () {
                                    state.saveCartAsDraft();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم تعليق الفاتورة بنجاح. يمكنك استرجاعها من الرئيسية')),
                                    );
                                  },
                                  tooltip: 'تعليق الفاتورة',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                                  onPressed: () => state.clearCart(),
                                  tooltip: 'تفريغ السلة',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Wholesale / Retail toggle
                        if (state.settings?.businessType == 'both')
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => state.setSaleType('retail'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: state.currentSaleType == 'retail' ? primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'سعر مفرد',
                                        style: TextStyle(
                                          color: state.currentSaleType == 'retail' ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => state.setSaleType('wholesale'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: state.currentSaleType == 'wholesale' ? primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'سعر جملة',
                                        style: TextStyle(
                                          color: state.currentSaleType == 'wholesale' ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Cart Items
                  Expanded(
                    child: state.cart.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_basket_outlined, size: 36, color: Colors.grey[400]),
                                const SizedBox(height: 6),
                                const Text('السلة فارغة. انقر مادة للإضافة', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.cart.values.length,
                            itemBuilder: (context, index) {
                              final item = state.cart.values.elementAt(index);
                              final key = item.cartKey;

                              return Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.black12)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.product.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                          onPressed: () => state.removeFromCart(key),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        )
                                      ],
                                    ),
                                    if (item.attributesSummary.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          item.attributesSummary,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Quantity adjusts
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                                              onPressed: () => state.updateCartQty(key, item.quantity - 1),
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text(
                                                item.quantity.toStringAsFixed(0),
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                              onPressed: () => state.updateCartQty(key, item.quantity + 1),
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                        // Item total
                                        Text(
                                          PrinterService.formatIQD(item.total(state.currentSaleType)),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Cart Totals and Checkout
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      color: state.isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المجموع:', style: TextStyle(fontSize: 12)),
                            Text(PrinterService.formatIQD(state.cartSubtotal), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الخصم (الديسكونت):', style: TextStyle(fontSize: 12)),
                            SizedBox(
                              width: 80,
                              height: 32,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (val) {
                                  setState(() {
                                    _discount = double.tryParse(val) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الصافي الكلي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              PrinterService.formatIQD(state.cartSubtotal - _discount),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: state.cart.isEmpty ? null : () => _showCheckoutSheet(state),
                            child: const Text('إتمام الفاتورة وتحصيل'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
}
