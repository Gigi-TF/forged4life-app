import 'dart:async';
import 'package:flutter/material.dart';

import 'services/card_token.dart';
import 'theme/f4l_theme.dart';
import 'widgets/membership_card.dart';

/// Preview harness — not the real app.
///
/// Renders the card with dummy data so you can check layout, colour and the
/// rotating QR in a browser before you have an Android phone. Deliberately
/// touches no plugins that lack web support: no secure storage, no screen
/// brightness, no network. Replace this file when you build the real flow.
void main() => runApp(const PreviewApp());

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  ThemeMode _mode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Forged 4 Life — preview',
        debugShowCheckedModeBanner: false,
        theme: F4L.light(),
        darkTheme: F4L.dark(),
        themeMode: _mode,
        home: PreviewScreen(
          onToggleTheme: () => setState(() => _mode =
              _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
          isDark: _mode == ThemeMode.dark,
        ),
      );
}

class PreviewScreen extends StatefulWidget {
  const PreviewScreen(
      {super.key, required this.onToggleTheme, required this.isDark});

  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  // A throwaway card so the QR generates and rotates like the real one.
  // NOT a real secret — 64 hex characters of nothing.
  static const _uid = '852ea8f4-4a2a-439d-b2fe-4652e2b17bf5';
  static const _secret =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  String _token = '';
  int _left = CardToken.period;
  Timer? _timer;
  bool _showQr = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _token = CardToken.issue(uid: _uid, version: 1, secretHex: _secret);
      _left = CardToken.secondsRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Roughly a phone's width, so the layout is honest even in a
            // wide browser window.
            constraints: const BoxConstraints(maxWidth: 400),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
              children: [
                Row(
                  children: [
                    Image.asset(
                      widget.isDark
                          ? 'assets/images/logo-icon-reverse.png'
                          : 'assets/images/logo-icon.png',
                      height: 52,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onToggleTheme,
                      icon: Icon(widget.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined),
                      tooltip: 'Toggle theme',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const BlendText(
                  'Talent Forged.\nPurpose Lived.',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800, height: 1.2),
                ),
                const SizedBox(height: 22),
                _label(context, 'Full membership — tap to flip'),
                MembershipCard(
                  name: 'Chiedza Mutasa',
                  cardNumber: 'FL 360 · 0447 2291',
                  tier: 'Tempered',
                  showQr: _showQr,
                  token: _token,
                  secondsLeft: _left,
                  onTap: () => setState(() => _showQr = !_showQr),
                ),
                const SizedBox(height: 26),
                _label(context, 'Day pass — expires tonight'),
                MembershipCard(
                  name: 'Tendai Moyo',
                  cardNumber: 'FL 360 · 0448 7734',
                  tier: 'Day Pass',
                  isDayPass: true,
                  expiresLabel: 'UNTIL 23:59',
                ),
                const SizedBox(height: 26),
                _label(context, 'Community'),
                MembershipCard(
                  name: 'Rudo Chikafu',
                  cardNumber: 'FL 360 · 0451 1180',
                  tier: 'Community',
                ),
                const SizedBox(height: 26),
                _label(context, 'FORGE Silver'),
                MembershipCard(
                  name: 'Edmore Vhera',
                  cardNumber: 'FL 360 · 0221 5590',
                  tier: 'Silver',
                ),
                const SizedBox(height: 28),
                Text(
                  'Preview only — dummy data, no login, no network. '
                  'The QR rotates every ${CardToken.period}s exactly as it will on a phone.',
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.8),
        ),
      );
}
