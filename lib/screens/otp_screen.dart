import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/card_store.dart';
import '../services/signup_draft.dart';
import '../theme/f4l_theme.dart';
import 'home_shell.dart';

/// Six-digit code, emailed. Handles both signup (draft supplied) and sign-in.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.draft, this.email});

  final SignupDraft? draft;
  final String? email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _api = ApiClient();
  final _code = TextEditingController();

  String get _email => widget.draft?.email ?? widget.email ?? '';

  bool _sending = true;
  bool _verifying = false;
  String? _error;
  int _resendIn = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _send();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await _api.requestCode(_email);
      _startResendTimer();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }

    if (mounted) setState(() => _sending = false);
  }

  void _startResendTimer() {
    _resendIn = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_code.text.trim().length != 6) {
      setState(() => _error = 'Enter all six digits.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final d = widget.draft;
      final res = await _api.verifyCode(
        email: _email,
        code: _code.text.trim(),
        name: d?.name,
        phone: d?.phone,
        memberType: d?.memberType,
        ageGroup: d?.ageGroup,
        company: d?.company,
        interests: d?.interests,
        transitionStage: d?.isSilver == true ? d?.transitionStage : null,
      );

      await CardStore.saveMember(res['member'] as Map<String, dynamic>);

      // Pull the card secret straight into secure storage — after this the
      // card works with no signal at all.
      await _api.bootstrapCard();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 2)),
        (_) => false,
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _verifying = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Check your email')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const BlendText('Enter your code',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'We sent a six-digit code to '),
                  TextSpan(
                      text: _email,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(
                      text: '. It expires in ten minutes. '
                          'Check your spam folder if it does not arrive.'),
                ]),
                style: TextStyle(fontSize: 15, height: 1.62, color: mute),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                enabled: !_verifying,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 12),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '––––––',
                  contentPadding: EdgeInsets.symmetric(vertical: 18),
                ),
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: Colors.red),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text(_error!,
                            style:
                                const TextStyle(fontSize: 13.5, height: 1.4))),
                  ]),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _verifying ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: F4L.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white))
                      : const Text('Verify and issue my card',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: (_resendIn > 0 || _sending) ? null : _send,
                  child: Text(_resendIn > 0
                      ? 'Resend code in ${_resendIn}s'
                      : 'Send another code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
