import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/purposes_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import '../widgets/picker_field.dart';
import 'home_shell.dart';

/// Sign in and create account, in one screen.
///
/// One screen rather than two: they are the same form with a few extra
/// fields, and someone who taps "Create one" should not lose the email they
/// just typed.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.startOnSignUp = false});

  final bool startOnSignUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _signUp = widget.startOnSignUp;

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otherPurpose = TextEditingController();

  /// 'member' or 'day'. Only asked on signup — a day visitor who comes back
  /// next month signs in with the same account, and reception upgrades them.
  String _joinAs = 'member';

  List<VisitPurpose> _purposes = [];
  VisitPurpose? _purpose;

  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Loaded once, and failing quietly is deliberate: signup must not break
    // because a dropdown could not reach the server.
    PurposesApi().all().then((list) {
      if (mounted) setState(() => _purposes = list);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _company.dispose();
    _password.dispose();
    _confirm.dispose();
    _otherPurpose.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_signUp) {
        await AuthApi().register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          memberType: _joinAs,
          company: _company.text.trim(),
          // Only sent for a day pass — a member is never asked.
          visitPurposeId: _joinAs == 'day' ? _purpose?.id : null,
          otherPurpose: _joinAs == 'day' && _purpose?.isOther == true
              ? _otherPurpose.text.trim()
              : null,
        );
      } else {
        await AuthApi().login(
          email: _email.text.trim(),
          password: _password.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _busy = false;
      });
    }
  }

  void _switchMode() => setState(() {
        _signUp = !_signUp;
        _error = null;
        // Email survives the switch. Passwords do not — carrying one between
        // a failed login and a signup form is how people register with a typo
        // of the password they meant.
        _password.clear();
        _confirm.clear();
      });

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Type your email above first, then tap this.');
      return;
    }

    await AuthApi().forgotPassword(email);

    if (!mounted) return;
    // Deliberately the same message whether or not the address exists —
    // confirming which emails are registered hands out a list of your members.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('If $email has an account, a reset link is on its way.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final isDay = _joinAs == 'day';

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    ForgeIcon(
                      _signUp
                          ? Icons.person_add_alt_1_rounded
                          : Icons.login_rounded,
                      tone: _signUp ? ForgeTone.ember : ForgeTone.teal,
                      size: 62,
                    ),
                    const SizedBox(height: 20),
                    BlendText(
                      _signUp ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          height: 1.2),
                    ),
                    const SizedBox(height: 7),
                    Text(
                        _signUp
                            ? (isDay
                                ? 'Your pass is issued now and expires tonight. '
                                    'The account stays — upgrade any time.'
                                : 'Free to join. Your card is issued the moment '
                                    'you finish.')
                            : 'Log in to your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14.5, height: 1.5, color: mute)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _GoogleButton(),
                          const SizedBox(height: 16),
                          _orDivider(context, mute),
                          const SizedBox(height: 16),
                          if (_signUp) ...[
                            _label('What brings you in?'),
                            _JoinChoice(
                              value: _joinAs,
                              onChanged: (v) => setState(() => _joinAs = v),
                            ),
                            const SizedBox(height: 16),
                            _label('Full name'),
                            _field(
                              controller: _name,
                              hint: 'Grace Chundu',
                              icon: Icons.person_outline,
                              capitalise: true,
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'We need your name for your card'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _label('Email'),
                          _field(
                            controller: _email,
                            hint: 'you@example.com',
                            icon: Icons.mail_outline,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'We need your email';
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(s)) {
                                return 'That does not look like an email';
                              }
                              return null;
                            },
                          ),
                          if (_signUp) ...[
                            const SizedBox(height: 14),
                            _label('Mobile number'),
                            _field(
                              controller: _phone,
                              hint: '+263 71 000 0000',
                              icon: Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                            ),

                            // Only worth asking a day visitor — a member's
                            // employer is not something the card needs.
                            if (isDay) ...[
                              const SizedBox(height: 14),
                              _label('Company or organisation'),
                              _field(
                                controller: _company,
                                hint: 'Who you are here with',
                                icon: Icons.business_outlined,
                                capitalise: true,
                              ),

                              // Hidden when the list could not load, so a
                              // failed fetch never blocks signup.
                              if (_purposes.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                PickerField<VisitPurpose>(
                                  label: 'What are you here for?',
                                  title: 'What brings you in today?',
                                  hint: 'Choose one',
                                  icon: Icons.interests_outlined,
                                  value: _purpose,
                                  items: _purposes,
                                  labelOf: (p) => p.label,
                                  onChanged: (v) =>
                                      setState(() => _purpose = v),
                                ),

                                // Only appears when it is needed. A permanent
                                // "other" box is a field people skip.
                                if (_purpose?.isOther == true) ...[
                                  const SizedBox(height: 12),
                                  _field(
                                    controller: _otherPurpose,
                                    hint: 'Tell us in a few words',
                                    icon: Icons.edit_outlined,
                                    capitalise: true,
                                  ),
                                ],
                              ],
                            ],
                          ],
                          const SizedBox(height: 14),
                          Row(children: [
                            _label('Password'),
                            const Spacer(),
                            if (!_signUp)
                              InkWell(
                                onTap: _forgot,
                                child: const Padding(
                                  padding: EdgeInsets.only(bottom: 7),
                                  child: Text('Forgot password?',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: F4L.orange)),
                                ),
                              ),
                          ]),
                          _field(
                            controller: _password,
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: _hide,
                            suffix: IconButton(
                              icon: Icon(
                                  _hide
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 19),
                              onPressed: () => setState(() => _hide = !_hide),
                            ),
                            validator: (v) {
                              if ((v ?? '').isEmpty) {
                                return 'We need a password';
                              }
                              if (_signUp && v!.length < 8) {
                                return 'At least 8 characters';
                              }
                              return null;
                            },
                          ),
                          if (_signUp) ...[
                            const SizedBox(height: 14),
                            _label('Confirm password'),
                            _field(
                              controller: _confirm,
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscure: _hide,
                              validator: (v) => v != _password.text
                                  ? 'These do not match'
                                  : null,
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.09),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.4)),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline,
                                    size: 17, color: Colors.red),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          fontSize: 13, height: 1.4)),
                                ),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: F4L.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.3, color: Colors.white))
                                : Text(
                                    _signUp
                                        ? (isDay
                                            ? 'Get my day pass'
                                            : 'Create account')
                                        : 'Log in',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            _signUp
                                ? 'Already have an account?'
                                : "Don't have an account?",
                            style: TextStyle(fontSize: 14, color: mute)),
                        const SizedBox(width: 5),
                        InkWell(
                          onTap: _switchMode,
                          child: Text(_signUp ? 'Log in' : 'Create one',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: F4L.orange)),
                        ),
                      ],
                    ),
                    if (_signUp) ...[
                      const SizedBox(height: 16),
                      Text(
                        isDay
                            ? 'Your pass is sent to your email. Show it at '
                                'reception when you arrive.'
                            : 'By joining you agree to the SkillsForge360 '
                                'member terms. Your card can be frozen from '
                                'Profile if your phone is lost.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 12, height: 1.55, color: mute),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orDivider(BuildContext context, Color? mute) => Row(children: [
        Expanded(
            child: Divider(color: Theme.of(context).dividerColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Text('OR',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: mute)),
        ),
        Expanded(
            child: Divider(color: Theme.of(context).dividerColor, height: 1)),
      ]);

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t,
            style:
                const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    bool obscure = false,
    bool capitalise = false,
    Widget? suffix,
  }) =>
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboard,
        obscureText: obscure,
        autocorrect: false,
        textCapitalization:
            capitalise ? TextCapitalization.words : TextCapitalization.none,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 19),
          suffixIcon: suffix,
        ),
      );
}

/// Membership or a day pass.
///
/// Both create a real account with a password — a day visitor who comes back
/// next month signs in rather than starting again, and reception upgrades
/// them without a support ticket. The only difference is that the day card
/// expires tonight and earns no sparks.
class _JoinChoice extends StatelessWidget {
  const _JoinChoice({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _option(
            context,
            key: 'member',
            icon: Icons.local_fire_department_rounded,
            title: 'Membership',
            sub: 'Free · no expiry',
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _option(
            context,
            key: 'day',
            icon: Icons.confirmation_number_rounded,
            title: 'Day pass',
            sub: 'Just for today',
          ),
        ),
      ]);

  Widget _option(
    BuildContext context, {
    required String key,
    required IconData icon,
    required String title,
    required String sub,
  }) {
    final on = value == key;
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => onChanged(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          color: on ? F4L.orange.withValues(alpha: 0.09) : null,
          border: Border.all(
            color: on
                ? F4L.orange
                : Theme.of(context).dividerColor.withValues(alpha: 0.7),
            width: on ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: on ? F4L.orange : mute),
            const SizedBox(height: 7),
            Text(title,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w800)),
            Text(sub, style: TextStyle(fontSize: 11.5, color: mute)),
          ],
        ),
      ),
    );
  }
}

/// Google sign-in.
///
/// The button is here because the design has it, but it is NOT wired: Google
/// sign-in needs a Cloud project, an OAuth client per platform, and a release
/// SHA-1 fingerprint that does not exist until there is a keystore. Letting
/// people tap a button that silently does nothing is worse than saying so.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton();

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Google sign-in is coming. Use your email for now.')),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 19, height: 19, child: CustomPaint(painter: _G())),
              SizedBox(width: 11),
              Text('Continue with Google',
                  style:
                      TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

/// The four-colour G, drawn rather than shipped as an asset.
class _G extends CustomPainter {
  const _G();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final stroke = size.width * 0.27;

    for (final (start, sweep, colour) in [
      (-0.55, 1.0, const Color(0xFF4285F4)),
      (0.55, 1.35, const Color(0xFF34A853)),
      (1.95, 1.35, const Color(0xFFFBBC05)),
      (3.35, 1.35, const Color(0xFFEA4335)),
    ]) {
      canvas.drawArc(
        r.deflate(stroke / 2),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = colour,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(
          size.width * 0.5, size.height * 0.38, size.width * 0.5, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
