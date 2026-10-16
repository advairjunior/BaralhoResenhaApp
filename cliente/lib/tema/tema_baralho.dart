import 'package:flutter/material.dart';

/// Clima de mesa de bar à noite: fundo escuro e quente, âmbar de chope e
/// coral para os destaques.
abstract final class CoresBaralho {
  static const fundo = Color(0xFF120C0A);
  static const superficie = Color(0xFF1E1714);
  static const superficieElevada = Color(0xFF2A201B);
  static const borda = Color(0xFF3D3029);
  static const ambar = Color(0xFFFFB627);
  static const ambarEscuro = Color(0xFF3A2A0C);
  static const coral = Color(0xFFFF6B5B);
  static const texto = Color(0xFFFFF8F2);
  static const textoSecundario = Color(0xFFCDBFB5);
  static const textoApagado = Color(0xFF8F8077);
  static const sucesso = Color(0xFF5BD68A);

  // Uma cor por modo de jogo: a carta já diz o que é antes de ler.
  static const euNunca = Color(0xFF8B5CF6);
  static const maisProvavel = Color(0xFF3B82F6);
  static const bebaSe = Color(0xFFF59E0B);
  static const relampago = Color(0xFFEAB308);
  static const casais = Color(0xFFEC4899);
  static const tribunal = Color(0xFF14B8A6);
  static const correio = Color(0xFFE4572E);
  static const mimica = Color(0xFF22A06B);
  static const elogios = Color(0xFFF5B301);
}

abstract final class EspacoBaralho {
  static const double mini = 4;
  static const double pequeno = 8;
  static const double medio = 12;
  static const double base = 16;
  static const double grande = 24;
  static const double enorme = 32;
}

abstract final class TemaBaralho {
  static ThemeData get escuro {
    const esquema = ColorScheme.dark(
      primary: CoresBaralho.ambar,
      onPrimary: Color(0xFF1A1205),
      secondary: CoresBaralho.coral,
      onSecondary: CoresBaralho.texto,
      error: CoresBaralho.coral,
      onError: CoresBaralho.texto,
      surface: CoresBaralho.superficie,
      onSurface: CoresBaralho.texto,
      outline: CoresBaralho.borda,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: esquema,
      fontFamily: 'Poppins',
      useMaterial3: true,
      scaffoldBackgroundColor: CoresBaralho.fundo,
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontSize: 40, fontWeight: FontWeight.w600, height: 1.1),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ).apply(bodyColor: CoresBaralho.texto, displayColor: CoresBaralho.texto),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: CoresBaralho.texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: CoresBaralho.texto,
          side: const BorderSide(color: CoresBaralho.borda),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CoresBaralho.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: CoresBaralho.textoSecundario),
        border: _borda(CoresBaralho.borda),
        enabledBorder: _borda(CoresBaralho.borda),
        focusedBorder: _borda(CoresBaralho.ambar, largura: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((estado) =>
            estado.contains(WidgetState.selected) ? const Color(0xFF1A1205) : CoresBaralho.textoSecundario),
        trackColor: WidgetStateProperty.resolveWith((estado) =>
            estado.contains(WidgetState.selected) ? CoresBaralho.ambar : CoresBaralho.superficieElevada),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CoresBaralho.superficie,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: CoresBaralho.superficie,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  static OutlineInputBorder _borda(Color cor, {double largura = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cor, width: largura),
      );
}
