import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'services/card_store.dart';
import 'theme/f4l_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/f4l_backdrop.dart';

void main() => runApp(const F4LApp());

class F4LApp extends StatefulWidget {
  const F4LApp({super.key});

  @override
  State<F4LApp> createState() => _F4LAppState();
}

class _F4LAppState extends State<F4LApp> {
  final _theme = ThemeController();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The provider sits ABOVE MaterialApp so every route can reach it,
    // and the AnimatedBuilder rebuilds MaterialApp when the mode changes.
    return F4LTheme(
      controller: _theme,
      child: AnimatedBuilder(
        animation: _theme,
        builder: (context, _) => MaterialApp(
          title: 'Forged 4 Life',
          debugShowCheckedModeBanner: false,
          theme: F4L.light(),
          darkTheme: F4L.dark(),
          themeMode: _theme.mode,
          builder: (context, child) =>
              F4LBackdrop(child: child ?? const SizedBox()),
          home: const _Gate(),
        ),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: CardStore.readAuthToken(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return snap.data == null ? const WelcomeScreen() : const HomeShell();
        },
      );
}
