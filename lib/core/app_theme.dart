import 'package:flutter/material.dart';

class CategoryMetadata {
  final String key;
  final String titleAr;
  final IconData icon;
  final Color primaryColor;
  final List<Color> gradientColors;
  final List<String> defaultSizes;
  final String defaultUnit;
  final bool hasSerial;
  final bool hasKarat;
  final bool hasCarModel;

  CategoryMetadata({
    required this.key,
    required this.titleAr,
    required this.icon,
    required this.primaryColor,
    required this.gradientColors,
    required this.defaultSizes,
    required this.defaultUnit,
    this.hasSerial = false,
    this.hasKarat = false,
    this.hasCarModel = false,
  });
}

class AppTheme {
  // Metadata for the 10 Categories
  static final List<CategoryMetadata> categories = [
    CategoryMetadata(
      key: 'clothing',
      titleAr: 'ملابس وأزياء',
      icon: Icons.checkroom_rounded,
      primaryColor: const Color(0xFF6C63FF),
      gradientColors: [const Color(0xFF6C63FF), const Color(0xFFFF6584)],
      defaultSizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'],
      defaultUnit: 'قطعة',
    ),
    CategoryMetadata(
      key: 'shoes',
      titleAr: 'أحذية وحقائب',
      icon: Icons.ice_skating_rounded,
      primaryColor: const Color(0xFFE94560),
      gradientColors: [const Color(0xFFE94560), const Color(0xFF0F0E17)],
      defaultSizes: ['36', '37', '38', '39', '40', '41', '42', '43', '44', '45'],
      defaultUnit: 'زوج',
    ),
    CategoryMetadata(
      key: 'supermarket',
      titleAr: 'سوبرماركت ومواد غذائية',
      icon: Icons.local_grocery_store_rounded,
      primaryColor: const Color(0xFF2EC4B6),
      gradientColors: [const Color(0xFF2EC4B6), const Color(0xFF208B81)],
      defaultSizes: [],
      defaultUnit: 'كغم',
    ),
    CategoryMetadata(
      key: 'electronics',
      titleAr: 'إلكترونيات وهواتف ذكية',
      icon: Icons.devices_rounded,
      primaryColor: const Color(0xFF00B4D8),
      gradientColors: [const Color(0xFF03045E), const Color(0xFF00B4D8)],
      defaultSizes: [],
      defaultUnit: 'جهاز',
      hasSerial: true,
    ),
    CategoryMetadata(
      key: 'pharmacy',
      titleAr: 'صيدلية ومستحضرات تجميل',
      icon: Icons.local_pharmacy_rounded,
      primaryColor: const Color(0xFF06D6A0),
      gradientColors: [const Color(0xFF06D6A0), const Color(0xFF118AB2)],
      defaultSizes: [],
      defaultUnit: 'علبة',
    ),
    CategoryMetadata(
      key: 'jewelry',
      titleAr: 'صياغة ومجوهرات',
      icon: Icons.workspace_premium_rounded,
      primaryColor: const Color(0xFFFFB703),
      gradientColors: [const Color(0xFF023047), const Color(0xFFFFB703)],
      defaultSizes: [],
      defaultUnit: 'غرام',
      hasKarat: true,
    ),
    CategoryMetadata(
      key: 'hardware',
      titleAr: 'مواد إنشائية وبناء',
      icon: Icons.construction_rounded,
      primaryColor: const Color(0xFFF77F00),
      gradientColors: [const Color(0xFFD62828), const Color(0xFFF77F00)],
      defaultSizes: [],
      defaultUnit: 'قطعة',
    ),
    CategoryMetadata(
      key: 'auto_parts',
      titleAr: 'قطع غيار السيارات',
      icon: Icons.directions_car_filled_rounded,
      primaryColor: const Color(0xFFD90429),
      gradientColors: [const Color(0xFF2B2D42), const Color(0xFFD90429)],
      defaultSizes: [],
      defaultUnit: 'قطعة',
      hasCarModel: true,
    ),
    CategoryMetadata(
      key: 'furniture',
      titleAr: 'أثاث ومفروشات منزلية',
      icon: Icons.chair_rounded,
      primaryColor: const Color(0xFF8B5A2B),
      gradientColors: [const Color(0xFF8B5A2B), const Color(0xFFCD853F)],
      defaultSizes: [],
      defaultUnit: 'طقم',
    ),
    CategoryMetadata(
      key: 'restaurant',
      titleAr: 'مطاعم ومقاهي',
      icon: Icons.restaurant_rounded,
      primaryColor: const Color(0xFFFF5E36),
      gradientColors: [const Color(0xFFFF5E36), const Color(0xFFFFAE19)],
      defaultSizes: ['صغير', 'وسط', 'كبير'],
      defaultUnit: 'وجبة',
    ),
    CategoryMetadata(
      key: 'perfumes',
      titleAr: 'عطور وبخور',
      icon: Icons.opacity_rounded,
      primaryColor: const Color(0xFF8A2BE2),
      gradientColors: [const Color(0xFF8A2BE2), const Color(0xFFFF1493)],
      defaultSizes: ['30ml', '50ml', '100ml', 'تولة', 'نصف تولة', 'ربع تولة'],
      defaultUnit: 'قنينة',
    ),
    CategoryMetadata(
      key: 'bookstore',
      titleAr: 'مكتبة وقرطاسية',
      icon: Icons.menu_book_rounded,
      primaryColor: const Color(0xFF008080),
      gradientColors: [const Color(0xFF008080), const Color(0xFF20B2AA)],
      defaultSizes: [],
      defaultUnit: 'قطعة',
    ),
    CategoryMetadata(
      key: 'petshop',
      titleAr: 'حيوانات ومستلزمات أليفة',
      icon: Icons.pets_rounded,
      primaryColor: const Color(0xFFFF8C00),
      gradientColors: [const Color(0xFFFF8C00), const Color(0xFFFFD700)],
      defaultSizes: ['كيس صغير', 'كيس كبير', 'علبة'],
      defaultUnit: 'قطعة',
    ),
  ];

  static CategoryMetadata getMetadata(String categoryKey) {
    return categories.firstWhere(
      (c) => c.key == categoryKey,
      orElse: () => categories.first,
    );
  }

  static ThemeData getTheme(String categoryKey, {bool isDark = false}) {
    final meta = getMetadata(categoryKey);
    final primary = meta.primaryColor;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Tajawal', // Using Tajawal font (fallback to system Arabic font)
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: primary.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
