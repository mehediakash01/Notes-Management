import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/notes_list_screen.dart';
import 'services/firestore_service.dart';

final FirestoreService firestoreService = FirestoreService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NotesApp());
}

class FirestoreServiceScope extends InheritedWidget {
  final FirestoreService service;

  const FirestoreServiceScope({
    super.key,
    required this.service,
    required super.child,
  });

  static FirestoreService of(BuildContext context) {
    final FirestoreServiceScope? scope =
        context.dependOnInheritedWidgetOfExactType<FirestoreServiceScope>();
    assert(scope != null, 'FirestoreServiceScope missing from widget tree.');
    return scope!.service;
  }

  @override
  bool updateShouldNotify(FirestoreServiceScope oldWidget) =>
      service != oldWidget.service;
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  static const Color backgroundDeepSlate = Color(0xFF121214);
  static const Color surfaceDarkCharcoal = Color(0xFF1A1A1E);
  static const Color primaryNeonTeal = Color(0xFF00F5D4);
  static const Color accentEmerald = Color(0xFF00E676);

  static const Color textHigh = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9AA0A6);

  ThemeData _buildTheme() {
    const TextTheme textTheme = TextTheme(
      displayLarge: TextStyle(color: textHigh, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(color: textHigh, fontWeight: FontWeight.w700),
      displaySmall: TextStyle(color: textHigh, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: textHigh, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: textHigh, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: textHigh, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textHigh, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textHigh, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textHigh, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textHigh),
      bodyMedium: TextStyle(color: textHigh),
      bodySmall: TextStyle(color: textMuted),
      labelLarge: TextStyle(color: textHigh, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: textMuted),
      labelSmall: TextStyle(color: textMuted),
    );

    final OutlineInputBorder baseRoundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2A2A30), width: 1),
    );

    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: surfaceDarkCharcoal,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: textMuted),
      floatingLabelStyle: const TextStyle(color: primaryNeonTeal),
      enabledBorder: baseRoundedBorder,
      focusedBorder: baseRoundedBorder.copyWith(
        borderSide: const BorderSide(color: primaryNeonTeal, width: 1.6),
      ),
      errorBorder: baseRoundedBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1),
      ),
      focusedErrorBorder: baseRoundedBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.6),
      ),
      disabledBorder: baseRoundedBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF2A2A30), width: 1),
      ),
    );

    final CardTheme cardTheme = CardTheme(
      color: surfaceDarkCharcoal,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF24242A), width: 1),
      ),
    );

    final AppBarTheme appBarTheme = const AppBarTheme(
      backgroundColor: backgroundDeepSlate,
      foregroundColor: textHigh,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textHigh,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    final ElevatedButtonThemeData elevatedButtonTheme =
        ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryNeonTeal,
        foregroundColor: backgroundDeepSlate,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    final FloatingActionButtonThemeData fabTheme =
        const FloatingActionButtonThemeData(
      backgroundColor: primaryNeonTeal,
      foregroundColor: backgroundDeepSlate,
      elevation: 4,
    );

    final ColorScheme colorScheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: primaryNeonTeal,
      onPrimary: backgroundDeepSlate,
      secondary: accentEmerald,
      onSecondary: backgroundDeepSlate,
      surface: surfaceDarkCharcoal,
      onSurface: textHigh,
      error: Color(0xFFFF5252),
      onError: textHigh,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDeepSlate,
      canvasColor: backgroundDeepSlate,
      cardColor: surfaceDarkCharcoal,
      dividerColor: const Color(0xFF24242A),
      splashColor: primaryNeonTeal.withValues(alpha: 0.08),
      highlightColor: primaryNeonTeal.withValues(alpha: 0.05),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: textHigh),
      primaryIconTheme: const IconThemeData(color: textHigh),
      appBarTheme: appBarTheme,
      cardTheme: cardTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      floatingActionButtonTheme: fabTheme,
      inputDecorationTheme: inputDecorationTheme,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceDarkCharcoal,
        contentTextStyle: TextStyle(color: textHigh),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: surfaceDarkCharcoal,
        titleTextStyle: TextStyle(
          color: textHigh,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FirestoreServiceScope(
      service: firestoreService,
      child: MaterialApp(
        title: 'Notes',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const NotesListScreenPlaceholder(),
      ),
    );
  }
}

class NotesListScreenPlaceholder extends StatelessWidget {
  const NotesListScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return NotesListScreen(
      service: FirestoreServiceScope.of(context),
    );
  }
}

extension NotesColors on ColorScheme {
  static const Color backgroundDeepSlate = NotesApp.backgroundDeepSlate;
  static const Color surfaceDarkCharcoal = NotesApp.surfaceDarkCharcoal;
  static const Color primaryNeonTeal = NotesApp.primaryNeonTeal;
  static const Color accentEmerald = NotesApp.accentEmerald;
}
