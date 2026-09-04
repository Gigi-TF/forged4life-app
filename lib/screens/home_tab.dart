import 'package:flutter/material.dart';

import '../services/card_store.dart';
import '../services/loyalty_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/forge_icon.dart';
import 'day_pass_home.dart';
import 'my_codes_screen.dart';
import 'rewards_screen.dart';

/// Home, now about the sparks.
///
/// The card lives on its own tab, so it is not repeated here — what is left
/// is the balance, the tier, the one thing you can do today, and what your
/// sparks are worth.
///
/// A day visitor sees something else entirely: the upgrade pitch. Not a
/// zeroed version of this screen — a balance of 0 and a progress bar that
/// never moves reads as "you are failing" rather than "you have not joined".
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onJump});

  final ValueChanged<int> onJump;

  @override
  State<HomeTab> createState() => HomeTabState();
}

/// Public so the shell can call [refresh] when this tab becomes visible.
///
/// The tabs live in an IndexedStack, which keeps every one of them alive —
/// good for the card's rotating token, but it means initState runs once and
/// never again. Without something telling Home to look, a member who earns
/// sparks anywhere else sees a stale balance until they restart the app.
class HomeTabState extends State<HomeTab> with WidgetsBindingObserver {
  LoyaltySummary? _s;
  Map<String, dynamic>? _member;
  bool _loading = true;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readMember();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the background. Someone whose card was scanned at
  /// reception while the app sat in their pocket should see the points when
  /// they look at it, not the next time they force-quit.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  /// Called by the shell when Home becomes the visible tab.
  Future<void> refresh() async {
    // The member record is re-read too — upgrading from a day pass changes
    // member_type, and the drawer header would otherwise keep the old one.
    await _readMember();
    await _load();
  }

  Future<void> _readMember() async {
    final m = await CardStore.readMember();
    if (mounted) setState(() => _member = m);
  }

  Future<void> _load() async {
    try {
      final s = await LoyaltyApi().summary();
      if (mounted) {
        setState(() {
          _s = s;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    try {
      final msg = await LoyaltyApi().checkIn();
      await _load();
      if (mounted) {
        setState(() => _checkingIn = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checkingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final s = _s;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Anything opened from the drawer can spend or earn sparks — the café
      // and The Shelf both can — so reload when the drawer closes.
      onDrawerChanged: (open) {
        if (!open) _load();
      },
      drawer: AppDrawer(
        name: _member?['name'] as String? ?? 'Member',
        email: _member?['email'] as String? ?? '',
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 110),
                children: [
                  Row(children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu_rounded, size: 24),
                        tooltip: 'Everything else',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const Spacer(),
                    // A pill reading "0 SPARKS" on every screen is a daily
                    // reminder of something a day visitor is not in.
                    if (s != null && s.loyalty) _sparksPill(s),
                  ]),

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_greeting,',
                            style: TextStyle(fontSize: 15, color: mute)),
                        BlendText(
                          _member?['name']?.toString().split(' ').first ??
                              'there',
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (s == null)
                    _offline(context, mute)

                  // ---- day pass: the upgrade pitch, nothing else ----
                  else if (!s.loyalty)
                    DayPassHome(
                      perks: s.perks ?? MemberPerks.fallback(),
                      onUpgraded: refresh,
                    )

                  // ---- member: the loyalty stack ----
                  else ...[
                    _tierStrip(s, mute),
                    const SizedBox(height: 12),
                    _checkInCard(s, mute),
                    const SizedBox(height: 12),
                    _stats(s, mute),

                    if (s.unusedCodes > 0) ...[
                      const SizedBox(height: 12),
                      _codesStrip(s, mute),
                    ],

                    const SizedBox(height: 24),
                    _sectionHead(
                        'Recent activity', 'View all', () => widget.onJump(4)),
                    const SizedBox(height: 10),
                    if (s.recent.isEmpty)
                      _card(
                        context,
                        child: Row(children: [
                          ForgeIcons.card.tile(size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Nothing yet. Check in above, or show your card '
                              'at reception.',
                              style: TextStyle(
                                  fontSize: 13.5, height: 1.5, color: mute),
                            ),
                          ),
                        ]),
                      )
                    else
                      ...s.recent.map((e) => _activityRow(context, e, mute)),

                    if (s.featured.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionHead(
                          'What your sparks buy', 'Browse', _openStore),
                      const SizedBox(height: 10),
                      ...s.featured.map((r) => _rewardRow(context, r, s, mute)),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openStore() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const RewardsScreen()))
      .then((_) => _load());

  Widget _sparksPill(LoyaltySummary s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          gradient: F4L.blend,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Text('${s.points}',
              style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(width: 4),
          const Text('SPARKS',
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: Color(0xCCFFFFFF))),
        ]),
      );

  Widget _tierStrip(LoyaltySummary s, Color? mute) => _card(
        context,
        onTap: _openStore,
        child: Column(children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: F4L.blend,
                shape: BoxShape.circle,
              ),
              child: Text('${s.tier.rank}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.tier.label} tier',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  Text('${s.tier.discount}% discount unlocked',
                      style: TextStyle(fontSize: 12.5, color: mute)),
                ],
              ),
            ),
            if (s.next != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Next: ${s.next!.label}',
                      style: TextStyle(fontSize: 11.5, color: mute)),
                  Text('${s.next!.pointsToGo} to go',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: F4L.orange)),
                ],
              ),
          ]),
          if (s.next != null) ...[
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: s.next!.progress,
                minHeight: 7,
                backgroundColor:
                    Theme.of(context).dividerColor.withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation(F4L.orange),
              ),
            ),
          ],
        ]),
      );

  Widget _checkInCard(LoyaltySummary s, Color? mute) => _card(
        context,
        child: Row(children: [
          ForgeIcon(Icons.local_fire_department_rounded,
              tone: s.checkedInToday ? ForgeTone.slate : ForgeTone.ember,
              size: 42),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily forge check-in',
                    style:
                        TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                Text(
                    s.checkedInToday
                        ? 'Done today. Scanning in at reception earns '
                            '${s.visitPoints} more.'
                        : 'Earn ${s.checkInPoints} sparks every day you open the app',
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: mute)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: _checkingIn
                ? const Center(
                    child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2)))
                : FilledButton(
                    onPressed: s.checkedInToday ? null : _checkIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: F4L.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(s.checkedInToday ? 'Done' : 'Check in',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
          ),
        ]),
      );

  Widget _stats(LoyaltySummary s, Color? mute) => Row(children: [
        Expanded(
            child: _stat(context, Icons.trending_up_rounded, '${s.lifetime}',
                'LIFETIME', mute)),
        const SizedBox(width: 10),
        Expanded(
            child: _stat(context, Icons.auto_awesome_rounded, s.tier.label,
                'TIER', mute)),
        const SizedBox(width: 10),
        Expanded(
            child: _stat(context, Icons.card_giftcard_rounded,
                '${s.tier.discount}%', 'DISCOUNT', mute)),
      ]);

  Widget _stat(BuildContext c, IconData icon, String value, String label,
          Color? mute) =>
      _card(
        c,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(children: [
          Icon(icon, size: 20, color: F4L.orange),
          const SizedBox(height: 7),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: mute)),
        ]),
      );

  /// Only appears when there is something to show at a counter — an empty
  /// "you have no codes" row would just be noise.
  Widget _codesStrip(LoyaltySummary s, Color? mute) => _card(
        context,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const MyCodesScreen()))
            .then((_) => _load()),
        child: Row(children: [
          ForgeIcon(Icons.confirmation_number_rounded,
              tone: ForgeTone.gold, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${s.unusedCodes} reward'
                    '${s.unusedCodes == 1 ? '' : 's'} to collect',
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800)),
                Text('Show the code at reception',
                    style: TextStyle(fontSize: 12.5, color: mute)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 19),
        ]),
      );

  Widget _activityRow(BuildContext c, LedgerEntry e, Color? mute) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _card(
          c,
          padding: const EdgeInsets.all(13),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${e.reason} · ${e.dateLabel}',
                      style: TextStyle(fontSize: 11.5, color: mute)),
                ],
              ),
            ),
            Text('${e.delta >= 0 ? '+' : ''}${e.delta}',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: e.delta >= 0 ? F4L.teal : F4L.orange)),
          ]),
        ),
      );

  Widget _rewardRow(BuildContext c, Reward r, LoyaltySummary s, Color? mute) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _card(
          c,
          padding: const EdgeInsets.all(13),
          onTap: _openStore,
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(r.valueLabel,
                      style: TextStyle(fontSize: 12, color: mute)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: s.points >= r.cost
                    ? F4L.teal.withValues(alpha: 0.14)
                    : Theme.of(c).dividerColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('${r.cost}',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: s.points >= r.cost ? F4L.teal : mute)),
            ),
          ]),
        ),
      );

  Widget _offline(BuildContext c, Color? mute) => _card(
        c,
        child: Column(children: [
          Icon(Icons.cloud_off, size: 28, color: mute),
          const SizedBox(height: 10),
          const Text('Could not load your sparks.',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Your card still works — pull down to try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: mute)),
        ]),
      );

  Widget _sectionHead(String title, String action, VoidCallback onTap) => Row(
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6)),
          const Spacer(),
          InkWell(
            onTap: onTap,
            child: Text(action,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: F4L.orange)),
          ),
        ],
      );

  Widget _card(BuildContext c,
          {required Widget child,
          EdgeInsets padding = const EdgeInsets.all(15),
          VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(c).colorScheme.surface.withValues(alpha: 0.88),
            border: Border.all(
                color: Theme.of(c).dividerColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      );
}
