import 'package:flutter/material.dart';

const purple = Color(0xFF6240D7);
const lavender = Color(0xFFEEE9FF);
const mint = Color(0xFFE3F4EE);
const ink = Color(0xFF201D35);
ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: purple,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(
      primary: dark ? const Color(0xFFC3B5FF) : purple,
    ),
    brightness: brightness,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF161421)
        : const Color(0xFFF8F6FF),
    fontFamily: 'sans-serif',
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: DaryeelPageTransitionsBuilder(),
        TargetPlatform.windows: DaryeelPageTransitionsBuilder(),
      },
    ),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'sans-serif',
      bodyColor: dark ? Colors.white : ink,
      displayColor: dark ? Colors.white : ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: purple.withValues(alpha: .07),
      surfaceTintColor: Colors.transparent,
      color: dark ? const Color(0xFF242131) : Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: dark ? const Color(0xFF3B3351) : const Color(0xFFF0ECF8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF2C283C) : const Color(0xFFFDFCFF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF55496D) : const Color(0xFFDBD4EE),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.all(18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        textStyle: const TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
        animationDuration: const Duration(milliseconds: 220),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF242131) : Colors.white,
      indicatorColor: dark ? const Color(0xFF44356C) : lavender,
      height: 78,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: purple,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFFE5DEF8) : const Color(0xFF252039),
      contentTextStyle: TextStyle(
        color: dark ? ink : Colors.white,
        fontSize: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      iconColor: dark ? const Color(0xFFC3B5FF) : purple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .4),
    ),
  );
}

class DaryeelPageTransitionsBuilder extends PageTransitionsBuilder {
  const DaryeelPageTransitionsBuilder();
  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return const FadeForwardsPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
