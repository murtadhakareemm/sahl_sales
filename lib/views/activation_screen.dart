import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import 'login_screen.dart';
import 'setup_wizard_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _serialController = TextEditingController();
  bool _isActivating = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }

  void _activate(AppState state) async {
    final code = _serialController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إدخال كود التفعيل أولاً';
      });
      return;
    }

    setState(() {
      _isActivating = true;
      _errorMessage = '';
    });

    // Simulate network delay if they chose server provisioning or verify local
    await Future.delayed(const Duration(milliseconds: 600));

    final success = await state.activateLicense(code);

    setState(() {
      _isActivating = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل نظام سهل للمبيعات بنجاح! شكراً لاشتراككم.'),
            backgroundColor: Colors.green,
          ),
        );
        // Direct route to onboarding wizard or login
        _continueToApp(state);
      }
    } else {
      final errorMsg = state.getLicenseValidationMessage(code);
      setState(() {
        _errorMessage = errorMsg.isEmpty ? 'كود التفعيل غير صالح أو منتهي الصلاحية!' : errorMsg;
      });
    }
  }

  void _continueToApp(AppState state) {
    if (state.settings == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SetupWizardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PinLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final themeMeta = AppTheme.getMetadata(state.activeThemeCategory);
    final primary = themeMeta.primaryColor;
    
    final isTrialAvailable = state.isTrialActive;
    final hoursLeft = state.trialTimeLeftHours;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Icon & Title
                      Icon(Icons.lock_clock_rounded, size: 64, color: isTrialAvailable ? Colors.amber[800] : Colors.red[800]),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          isTrialAvailable ? 'الفترة التجريبية لنظام سهل' : 'انتهت صلاحية نظام سهل للمبيعات',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Trial status alert
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTrialAvailable ? Colors.amber[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isTrialAvailable ? Colors.amber[200]! : Colors.red[200]!),
                        ),
                        child: Text(
                          isTrialAvailable
                              ? 'البرنامج يعمل بنسخة تجريبية مجانية صالحة لمدة يوم واحد (24 ساعة). المتبقي لك: $hoursLeft ساعة.'
                              : 'لقد انتهت فترة التجربة المجانية (يوم واحد) وتوقف النظام. يرجى تفعيل المنتج لمتابعة مبيعاتك.',
                          style: TextStyle(
                            fontSize: 12, 
                            color: isTrialAvailable ? Colors.amber[900] : Colors.red[900], 
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Device ID section
                      const Text(
                        'معرف هذا الجهاز الفريد (Device ID):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.fingerprint_rounded, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            SelectableText(
                              state.deviceId,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'قم بنسخ الكود أعلاه وإرساله للمشرف لتوليد كود التفعيل المخصص لجهازك.',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Activation Form
                      const Text('أدخل كود تفعيل النظام:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _serialController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'ألصق كود التفعيل هنا...',
                          prefixIcon: Icon(Icons.key_rounded),
                        ),
                      ),
                      
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Actions Buttons
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isActivating ? null : () => _activate(state),
                        child: _isActivating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('تفعيل النظام الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      
                      if (isTrialAvailable) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _continueToApp(state),
                          child: const Text('متابعة الفترة التجريبية', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
