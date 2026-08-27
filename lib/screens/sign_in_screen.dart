import 'package:flutter/material.dart';
import '../theme/f4l_theme.dart';
import 'otp_screen.dart';

/// Returning members — email only, no password anywhere in this app.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  String _email = '';

  void _next() {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OtpScreen(email: _email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const BlendText('Welcome back',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'No password to remember. Give us your email and we will send '
                  'a code.',
                  style: TextStyle(fontSize: 15, height: 1.6, color: mute),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'Email', hintText: 'you@example.com'),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'We need your email';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                      return 'That does not look like an email address';
                    }
                    return null;
                  },
                  onSaved: (v) => _email = v!.trim().toLowerCase(),
                  onFieldSubmitted: (_) => _next(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: F4L.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Send my code',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
