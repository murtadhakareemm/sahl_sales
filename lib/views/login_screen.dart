import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';

  void _keypadTap(String value) {
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
      });

      if (_pin.length == 4) {
        _submitLogin();
      }
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _clear() {
    setState(() {
      _pin = '';
    });
  }

  Future<void> _submitLogin() async {
    final state = Provider.of<AppState>(context, listen: false);
    final success = await state.login(_pin);

    if (success) {
      // Authenticated successfully
      if (mounted) {
        _clear();
      }
    } else {
      if (mounted) {
        _clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رمز الدخول السري غير صحيح أو الموظف غير نشط'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final meta = AppTheme.getMetadata(state.activeThemeCategory);
    final primary = meta.primaryColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: state.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF0F2F5),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Store Branding
                    Icon(meta.icon, size: 64, color: primary),
                    const SizedBox(height: 16),
                    Text(
                      state.settings?.storeName ?? 'سهل للمبيعات',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: state.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أدخل رمز الدخول السري للبدء',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 32),

                    // PIN Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final filled = index < _pin.length;
                        return Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled ? primary : Colors.grey[300],
                            border: Border.all(
                              color: filled ? primary : Colors.grey[400]!,
                              width: 1.5,
                            ),
                            boxShadow: filled
                                ? [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 8)]
                                : [],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 48),

                    // Custom Numeric Keypad
                    Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildNumberButton('1'),
                              _buildNumberButton('2'),
                              _buildNumberButton('3'),
                            ],
                          ),
                          Row(
                            children: [
                              _buildNumberButton('4'),
                              _buildNumberButton('5'),
                              _buildNumberButton('6'),
                            ],
                          ),
                          Row(
                            children: [
                              _buildNumberButton('7'),
                              _buildNumberButton('8'),
                              _buildNumberButton('9'),
                            ],
                          ),
                          Row(
                            children: [
                              _buildIconButton(Icons.clear_rounded, _clear),
                              _buildNumberButton('0'),
                              _buildIconButton(Icons.backspace_outlined, _backspace),
                            ],
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
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    final isDark = Provider.of<AppState>(context, listen: false).isDarkMode;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          shadowColor: Colors.black12,
          child: InkWell(
            onTap: () => _keypadTap(number),
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 64,
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    final isDark = Provider.of<AppState>(context, listen: false).isDarkMode;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 64,
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
