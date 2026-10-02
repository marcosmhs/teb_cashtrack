import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de espaçamento e forma (ver `lib/DESIGN.md`).
class AppSpacing {
  const AppSpacing._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radius = 12.0;
  static const chipRadius = 8.0;
  static const maxContentWidth = 760.0;
}

/// Cores semânticas para valores financeiros, com variações para tema claro e escuro.
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.onIncomeContainer,
    required this.incomeContainer,
    required this.expense,
    required this.expenseContainer,
    required this.onExpenseContainer,
    required this.cardBorder,
  });

  final Color income;
  final Color incomeContainer;
  final Color onIncomeContainer;
  final Color expense;
  final Color expenseContainer;
  final Color onExpenseContainer;
  final Color cardBorder;

  static const light = FinanceColors(
    income: Color(0xFF047857),
    incomeContainer: Color(0xFFD1FAE5),
    onIncomeContainer: Color(0xFF065F46),
    expense: Color(0xFFB91C1C),
    expenseContainer: Color(0xFFFEE2E2),
    onExpenseContainer: Color(0xFF991B1B),
    cardBorder: Color(0xFFE2E8F0),
  );

  static const dark = FinanceColors(
    income: Color(0xFF4EDEA3),
    incomeContainer: Color(0xFF00422B),
    onIncomeContainer: Color(0xFF6FFBBE),
    expense: Color(0xFFFF8A80),
    expenseContainer: Color(0xFF5F1414),
    onExpenseContainer: Color(0xFFFFDAD6),
    cardBorder: Color(0xFF2E3A33),
  );

  Color forSign(int cents) => cents < 0 ? expense : income;

  @override
  FinanceColors copyWith({
    Color? income,
    Color? incomeContainer,
    Color? onIncomeContainer,
    Color? expense,
    Color? expenseContainer,
    Color? onExpenseContainer,
    Color? cardBorder,
  }) {
    return FinanceColors(
      income: income ?? this.income,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      onIncomeContainer: onIncomeContainer ?? this.onIncomeContainer,
      expense: expense ?? this.expense,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      onExpenseContainer: onExpenseContainer ?? this.onExpenseContainer,
      cardBorder: cardBorder ?? this.cardBorder,
    );
  }

  @override
  FinanceColors lerp(FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      onIncomeContainer: Color.lerp(onIncomeContainer, other.onIncomeContainer, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseContainer: Color.lerp(expenseContainer, other.expenseContainer, t)!,
      onExpenseContainer: Color.lerp(onExpenseContainer, other.onExpenseContainer, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  FinanceColors get finance => Theme.of(this).extension<FinanceColors>()!;
}

class AppTheme {
  const AppTheme._();

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006C49),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF10B981),
    onPrimaryContainer: Color(0xFF00422B),
    secondary: Color(0xFF545F73),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD5E0F8),
    onSecondaryContainer: Color(0xFF3C475A),
    tertiary: Color(0xFF505F76),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFD3E4FE),
    onTertiaryContainer: Color(0xFF2A3A4F),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFF4FBF4),
    onSurface: Color(0xFF161D19),
    onSurfaceVariant: Color(0xFF3C4A42),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFEEF6EE),
    surfaceContainer: Color(0xFFE8F0E9),
    surfaceContainerHigh: Color(0xFFE3EAE3),
    surfaceContainerHighest: Color(0xFFDDE4DD),
    outline: Color(0xFF6C7A71),
    outlineVariant: Color(0xFFBBCABF),
    shadow: Color(0xFF1E293B),
    inverseSurface: Color(0xFF2B322D),
    onInverseSurface: Color(0xFFEBF3EB),
    inversePrimary: Color(0xFF4EDEA3),
    surfaceTint: Colors.transparent,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4EDEA3),
    onPrimary: Color(0xFF003824),
    primaryContainer: Color(0xFF005236),
    onPrimaryContainer: Color(0xFF6FFBBE),
    secondary: Color(0xFFBCC7DE),
    onSecondary: Color(0xFF263143),
    secondaryContainer: Color(0xFF3C475A),
    onSecondaryContainer: Color(0xFFD8E3FB),
    tertiary: Color(0xFFB7C8E1),
    onTertiary: Color(0xFF213145),
    tertiaryContainer: Color(0xFF38485D),
    onTertiaryContainer: Color(0xFFD3E4FE),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0E1511),
    onSurface: Color(0xFFDDE4DD),
    onSurfaceVariant: Color(0xFFBBCABF),
    surfaceContainerLowest: Color(0xFF09100C),
    surfaceContainerLow: Color(0xFF161D19),
    surfaceContainer: Color(0xFF1A211D),
    surfaceContainerHigh: Color(0xFF252B27),
    surfaceContainerHighest: Color(0xFF2F3632),
    outline: Color(0xFF86948A),
    outlineVariant: Color(0xFF3C4A42),
    shadow: Colors.black,
    inverseSurface: Color(0xFFDDE4DD),
    onInverseSurface: Color(0xFF2B322D),
    inversePrimary: Color(0xFF006C49),
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light => _build(_lightScheme, FinanceColors.light);
  static ThemeData get dark => _build(_darkScheme, FinanceColors.dark);

  static ThemeData _build(ColorScheme scheme, FinanceColors finance) {
    final radius = BorderRadius.circular(AppSpacing.radius);
    final baseText = ThemeData(brightness: scheme.brightness).textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseText)
        .copyWith(
          headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, height: 1.25),
          headlineMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.33,
          ),
          titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5),
          bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.43),
          bodySmall: GoogleFonts.inter(fontSize: 13, height: 1.38),
          labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final buttonShape = RoundedRectangleBorder(borderRadius: radius);
    const buttonSize = Size(64, 48);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [finance],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: finance.cardBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: buttonShape,
          minimumSize: buttonSize,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: buttonShape,
          minimumSize: buttonSize,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(shape: buttonShape, minimumSize: buttonSize),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.chipRadius)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.35),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.35),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(color: finance.cardBorder, space: 1),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
