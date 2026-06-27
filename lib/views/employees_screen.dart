import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/employee.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  String _selectedRole = 'cashier'; // 'manager', 'cashier'

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _pinController.clear();
    setState(() {
      _selectedRole = 'cashier';
    });
  }

  Future<void> _submitAddEmployee(AppState state) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await state.addEmployee(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _pinController.text.trim(),
      _selectedRole,
    );

    if (success) {
      if (mounted) {
        Navigator.pop(context); // Close sheet
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الموظف بنجاح!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشلت إضافة الموظف، يرجى المحاولة لاحقاً')),
        );
      }
    }
  }

  void _showAddEmployeeSheet(AppState state, Color primary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 24,
                  left: 24,
                  right: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Text(
                          'إضافة موظف جديد للنظام',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الموظف الثلاثي *',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) => value!.isEmpty ? 'اسم الموظف مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف *',
                          prefixIcon: Icon(Icons.phone_android_rounded),
                        ),
                        validator: (value) => value!.isEmpty ? 'رقم الهاتف مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'رمز الدخول السري (PIN) *',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'الرمز مطلوب';
                          if (value.length < 4) return 'يجب أن يتكون من 4 أرقام';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('الصلاحية الوظيفية:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('كاشير مبيعات', style: TextStyle(fontSize: 13)),
                              value: 'cashier',
                              groupValue: _selectedRole,
                              onChanged: (val) => setSheetState(() => _selectedRole = val!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('مدير نظام', style: TextStyle(fontSize: 13)),
                              value: 'manager',
                              groupValue: _selectedRole,
                              onChanged: (val) => setSheetState(() => _selectedRole = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _submitAddEmployee(state),
                        child: const Text('حفظ الموظف وتفعيل حسابه', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Employee employee, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من رغبتك في حذف حساب الموظف (${employee.name})؟ سيتم إيقافه محلياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await state.deleteEmployee(employee.id);
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add employee button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _showAddEmployeeSheet(state, primary),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('إضافة كاشير / موظف جديد للنظام', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            const Text(
              'قائمة الموظفين المسجلين:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),

            // Employees list
            Expanded(
              child: state.employees.isEmpty
                  ? const Center(child: Text('لا يوجد موظفون مضافون حالياً.'))
                  : ListView.builder(
                      itemCount: state.employees.length,
                      itemBuilder: (context, index) {
                        final emp = state.employees[index];
                        final isManager = emp.role == 'manager';

                        // Do not show delete/disable options for the currently active user
                        final isCurrentUser = state.activeEmployee?.id == emp.id;

                        return Card(
                          color: emp.isActive ? null : Colors.grey[200],
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isManager ? Colors.amber[100] : primary.withOpacity(0.1),
                              foregroundColor: isManager ? Colors.amber[800] : primary,
                              child: Icon(isManager ? Icons.shield_rounded : Icons.person_rounded),
                            ),
                            title: Text(
                              emp.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: emp.isActive ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: Text('هاتف: ${emp.phone} | الصلاحية: ${isManager ? "مدير" : "كاشير"}'),
                            trailing: isCurrentUser
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(12)),
                                    child: const Text('حسابك الحالي', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Active/Inactive toggle switch
                                      Switch(
                                        value: emp.isActive,
                                        activeColor: primary,
                                        onChanged: (value) async {
                                          await state.toggleEmployeeStatus(emp);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                        onPressed: () => _confirmDelete(emp, state),
                                        tooltip: 'حذف الموظف',
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
      ),
    );
  }
}
