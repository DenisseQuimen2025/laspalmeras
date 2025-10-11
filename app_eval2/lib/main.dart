import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const LasPalmerasApp());
}

class LasPalmerasApp extends StatelessWidget {
  const LasPalmerasApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✔ Verde principal #5B9E35
    const seed = Color(0xFF5B9E35);
    // Fondo suave verdoso
    const softBg = Color(0xFFF6FAF4);

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Evaluación 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,

        // Fondo general
        scaffoldBackgroundColor: softBg,

        // Inputs: borde/foco y estilos
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: seed, width: 2),
          ),
          labelStyle: TextStyle(
            // reemplaza withOpacity por withValues
            color: scheme.onSurface.withValues(alpha: 0.80),
          ),
        ),

        // Botones elevados (Ingresar)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 14),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),

        // FAB (botón "Nueva")
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          shape: StadiumBorder(),
        ),

        // Chips (Todas/Pendientes/Completas)
        chipTheme: ChipThemeData(
          side: BorderSide(color: seed.withValues(alpha: 0.25)),
          selectedColor: seed,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(color: scheme.onSurface),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
