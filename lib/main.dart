import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'services/card_store.dart';
import 'services/deep_links.dart';
import 'services/features.dart';
import 'theme/f4l_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/f4l_backdrop.dart';

void main() {
  // Needed because DeepLinks touches platform channels before the first
  // frame; without it a cold-start link throws.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const F4LApp());

  /*
   * After runApp, not before.
   *
   * A link that launched the app fires almost immediately, and the navigator
   * has to exist before anything tries to push onto it.
   */
  DeepLinks.instance.start();

  /*
   * Fire and forget.
   *
   * A member must never wait on this to open the app. The flags default to
   * OFF, so a slow or failed fetch shows "Opening soon" briefly rather than
   * a live ordering screen for a kitchen that is not taking orders.
   */
  Features.instance.load();
}

class F4LApp extends StatefulWidget {
  const F4LApp({super.key});

  @override
  State<F4LApp> createState() => _F4LAppState();
}

class _F4LAppState extends State<F4LApp> {
  final _theme = ThemeController();

  @override
  void dispose() {
    DeepLinks.instance.dispose();
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

          // Lets a deep link navigate from outside the widget tree.
          navigatorKey: DeepLinks.navigatorKey,

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
