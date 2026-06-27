import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Form Fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerPinController = TextEditingController();

  String _selectedCategory = 'clothing';
  String _selectedBusinessType = 'both'; // 'retail', 'wholesale', 'both'

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _managerNameController.dispose();
    _managerPinController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate store details
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال اسم المحل / الشركة')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Category selected - move to admin setup
    }
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _submitSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final state = Provider.of<AppState>(context, listen: false);
    final success = await state.setupStore(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      businessType: _selectedBusinessType,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      managerName: _managerNameController.text.trim(),
      managerPin: _managerPinController.text.trim(),
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت تهيئة النظام بنجاح!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء التهيئة، يرجى المحاولة لاحقاً')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = AppTheme.getMetadata(_selectedCategory);
    final primary = meta.primaryColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                primary.withOpacity(0.08),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // App Title Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(meta.icon, size: 48, color: primary),
                        const SizedBox(height: 8),
                        const Text(
                          'سهل للمبيعات والمخازن',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'تهيئة النظام لأول مرة لنشاطك التجاري',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  // Active Step Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: _buildStepContent(),
                        ),
                      ),
                    ),
                  ),

                  // Step Action Navigation
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          OutlinedButton(
                            onPressed: _prevStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              side: BorderSide(color: primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('السابق', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                          )
                        else
                          const SizedBox(),
                        ElevatedButton(
                          onPressed: _currentStep < 2 ? _nextStep : _submitSetup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          ),
                          child: Text(
                            _currentStep < 2 ? 'التالي' : 'إتمام وبدء التشغيل',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepStoreInfo();
      case 1:
        return _buildStepCategorySelect();
      case 2:
        return _buildStepAdminConfig();
      default:
        return const SizedBox();
    }
  }

  // Step 1: Store profile details
  Widget _buildStepStoreInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. معلومات النشاط التجاري',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'اسم المحل أو الشركة *',
            prefixIcon: Icon(Icons.storefront_rounded),
            hintText: 'مثال: ملابس البغدادي، أسواق الهلال',
          ),
          validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'رقم الهاتف *',
            prefixIcon: Icon(Icons.phone_android_rounded),
            hintText: 'مثال: 077xxxxxxxx',
          ),
          validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'العنوان بالتفصيل',
            prefixIcon: Icon(Icons.location_on_rounded),
            hintText: 'مثال: بغداد - الكرادة - قرب ساحة الحرية',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'طريقة البيع الافتراضية:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('مفرد', style: TextStyle(fontSize: 13)),
                value: 'retail',
                groupValue: _selectedBusinessType,
                onChanged: (val) => setState(() => _selectedBusinessType = val!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('جملة', style: TextStyle(fontSize: 13)),
                value: 'wholesale',
                groupValue: _selectedBusinessType,
                onChanged: (val) => setState(() => _selectedBusinessType = val!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('كلاهما', style: TextStyle(fontSize: 13)),
                value: 'both',
                groupValue: _selectedBusinessType,
                onChanged: (val) => setState(() => _selectedBusinessType = val!),
              ),
            ),
          ],
        )
      ],
    );
  }

  // Step 2: Choose 10 store categories
  Widget _buildStepCategorySelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. نوع النشاط والمنتجات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'سيتم تعديل ألوان التطبيق وحقول المقاسات والكميات تلقائياً بناءً على اختيارك:',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AppTheme.categories.length,
          itemBuilder: (context, index) {
            final cat = AppTheme.categories[index];
            final isSelected = _selectedCategory == cat.key;
            return Card(
              elevation: isSelected ? 4 : 1,
              margin: const EdgeInsets.only(bottom: 10),
              color: isSelected ? cat.primaryColor.withOpacity(0.08) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isSelected ? cat.primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cat.primaryColor,
                  foregroundColor: Colors.white,
                  child: Icon(cat.icon),
                ),
                title: Text(
                  cat.titleAr,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? cat.primaryColor : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'وحدة القياس: ${cat.defaultUnit} ${cat.defaultSizes.isNotEmpty ? "• مع دعم المقاسات المخصصة" : ""}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: cat.primaryColor)
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () {
                  setState(() {
                    _selectedCategory = cat.key;
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // Step 3: AdminPIN and Manager details
  Widget _buildStepAdminConfig() {
    final meta = AppTheme.getMetadata(_selectedCategory);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. إعداد حساب المدير المسؤول',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _managerNameController,
          decoration: const InputDecoration(
            labelText: 'اسم المدير المسؤول *',
            prefixIcon: Icon(Icons.person_outline_rounded),
            hintText: 'مثال: الأستاذ محمد علي',
          ),
          validator: (value) => value!.isEmpty ? 'يرجى إدخال اسم المدير' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _managerPinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'رمز الدخول السري (PIN) للمدير *',
            prefixIcon: Icon(Icons.lock_outline_rounded),
            hintText: 'مثال: 1234',
            counterText: '',
          ),
          validator: (value) {
            if (value!.isEmpty) return 'يرجى تعيين رمز الدخول';
            if (value.length < 4) return 'يجب أن يتكون الرمز من 4 أرقام';
            return null;
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: meta.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: meta.primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: meta.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'رمز الدخول يستخدم لتسجيل الدخول السريع وتجنب دخول الموظفين غير المصرح لهم لصفحة الحسابات والتقارير.',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
