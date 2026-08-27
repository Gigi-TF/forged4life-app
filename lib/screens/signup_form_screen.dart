import 'package:flutter/material.dart';
import '../services/signup_draft.dart';
import '../theme/f4l_theme.dart';
import 'otp_screen.dart';

/// One form, fields swap by membership type.
class SignupFormScreen extends StatefulWidget {
  const SignupFormScreen({super.key, required this.draft});
  final SignupDraft draft;

  @override
  State<SignupFormScreen> createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends State<SignupFormScreen> {
  final _form = GlobalKey<FormState>();

  static const _ages = ['16-24', '25-39', '40-54', '55+'];
  static const _programmes = [
    'Transition Ready',
    'Grants Master',
    'Graduate Employability',
    'LaunchPad',
    'Athlete & Creative Transition',
    'Not sure yet',
  ];
  static const _silverInterests = [
    'Transition Ready',
    'FORGE Silver programme',
    'Chess, pottery, the studio',
    'Mentoring younger members',
    'Cafeteria and company',
  ];
  static const _stages = [
    'Still working, planning ahead',
    'Within a year of retiring',
    'Recently retired',
    'Retired some years ago',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.draft.isSilver) widget.draft.transitionStage = _stages.first;
  }

  void _continue() {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OtpScreen(draft: widget.draft),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: Text('Step 2 of 2 · ${d.label}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                BlendText(_title(d),
                    style: const TextStyle(
                        fontSize: 27, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(_sub(d),
                    style: TextStyle(fontSize: 15, height: 1.6, color: mute)),
                const SizedBox(height: 20),

                // ---- everyone ----
                _label('Full name'),
                TextFormField(
                  initialValue: d.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Chiedza Mutasa'),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'We need your name for the card'
                      : null,
                  onSaved: (v) => d.name = v!.trim(),
                ),
                const SizedBox(height: 14),

                _label('Email'),
                TextFormField(
                  initialValue: d.email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'We send your login code here';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                      return 'That does not look like an email address';
                    }
                    return null;
                  },
                  onSaved: (v) => d.email = v!.trim().toLowerCase(),
                ),
                const SizedBox(height: 14),

                _label('Mobile number'),
                TextFormField(
                  initialValue: d.phone,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(hintText: '+263 71 000 0000'),
                  onSaved: (v) => d.phone = (v ?? '').trim(),
                ),
                const SizedBox(height: 14),

                _label('Age group'),
                _Chips(
                  options: _ages,
                  selected: {d.ageGroup},
                  single: true,
                  onChanged: (s) => setState(() => d.ageGroup = s.first),
                ),
                const SizedBox(height: 14),

                // ---- day pass ----
                if (d.isDay) ...[
                  _label('Company or organisation'),
                  TextFormField(
                    initialValue: d.company,
                    decoration: const InputDecoration(
                        hintText: 'Talent Fusion Solutions'),
                    onSaved: (v) => d.company = (v ?? '').trim(),
                  ),
                  const SizedBox(height: 14),
                  _label('Programme'),
                  _Dropdown(
                    value: d.programme.isEmpty ? _programmes.first : d.programme,
                    items: const [
                      'Transition Ready',
                      'Grants Master',
                      'Graduate Employability',
                      'Private booking / meeting',
                    ],
                    onChanged: (v) => setState(() => d.programme = v),
                  ),
                  const SizedBox(height: 14),
                  _label('Training room'),
                  _Dropdown(
                    value: d.trainingRoom.isEmpty ? 'The Crucible' : d.trainingRoom,
                    items: const ['The Crucible', 'The Anvil', 'Quench Room'],
                    onChanged: (v) => setState(() => d.trainingRoom = v),
                  ),
                  const SizedBox(height: 14),
                  _label('Vehicle registration'),
                  TextFormField(
                    initialValue: d.vehicleReg,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                        hintText: 'ACD 1234 — leave blank if not driving'),
                    onSaved: (v) => d.vehicleReg = (v ?? '').trim(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Used by the gate to match you to your car. '
                    'Deleted 30 days after your visit.',
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: mute),
                  ),
                  const SizedBox(height: 14),
                ],

                // ---- full membership ----
                if (d.memberType == 'member') ...[
                  _label("Programmes I'm interested in"),
                  _Chips(
                    options: _programmes,
                    selected: d.interests.toSet(),
                    onChanged: (s) => setState(() => d.interests = s.toList()),
                  ),
                  const SizedBox(height: 14),
                ],

                // ---- forge silver ----
                if (d.isSilver) ...[
                  _label('Where are you in the transition?'),
                  _Dropdown(
                    value: d.transitionStage,
                    items: _stages,
                    onChanged: (v) => setState(() => d.transitionStage = v),
                  ),
                  const SizedBox(height: 14),
                  _label('What draws you here?'),
                  _Chips(
                    options: _silverInterests,
                    selected: d.interests.toSet(),
                    onChanged: (s) => setState(() => d.interests = s.toList()),
                  ),
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _continue,
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
                const SizedBox(height: 12),
                Text(
                  'By joining you agree to the SkillsForge360 member terms. '
                  'Your card can be frozen from Profile if your phone is lost.',
                  style: TextStyle(fontSize: 12.5, height: 1.6, color: mute),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(SignupDraft d) => switch (d.memberType) {
        'day' => 'Your visit today',
        'member' => 'Get forged.',
        'silver' => 'Welcome to Silver.',
        _ => 'Thirty seconds.',
      };

  String _sub(SignupDraft d) => switch (d.memberType) {
        'day' =>
          'Reception can fill this in for you at the desk if you would rather not type.',
        'member' =>
          'Membership is free. Your card is issued the moment you finish — no plastic, no waiting.',
        'silver' =>
          'Membership is free. Tell us where you are in the transition so we point you at the right things.',
        _ => 'Name, email, age group. That is the whole form.',
      };

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
      );
}

class _Dropdown extends StatelessWidget {
  const _Dropdown(
      {required this.value, required this.items, required this.onChanged});
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => v == null ? null : onChanged(v),
      );
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.single = false,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool single;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((o) {
          final on = selected.contains(o);
          return FilterChip(
            label: Text(o),
            selected: on,
            showCheckmark: false,
            selectedColor: F4L.orange,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              color: on ? Colors.white : null,
            ),
            onSelected: (v) {
              if (single) {
                onChanged({o});
              } else {
                final next = {...selected};
                v ? next.add(o) : next.remove(o);
                onChanged(next);
              }
            },
          );
        }).toList(),
      );
}
