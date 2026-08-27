import 'package:flutter/material.dart';
import '../widgets/forge_icon.dart';

/// The five cohort schools and everything inside them.
///
/// Transcribed from the website's cohorts section — this is the authoritative
/// list. Nineteen programmes, not the thirteen an earlier draft guessed at.
/// Kept in Dart for now; when `programmes` and `cohorts` are exposed over the
/// API this becomes the fallback for offline.
class Forge {
  const Forge({
    required this.name,
    required this.forWhom,
    required this.spec,
    required this.programmes,
  });

  final String name;
  final String forWhom;
  final (IconData, ForgeTone) spec;
  final List<Programme> programmes;
}

class Programme {
  const Programme(this.slug, this.name, this.blurb, this.spec, {this.audience});

  /// Matches a key in `Interest::PROGRAMME_CATALOG` on the server, which is
  /// what decides which curriculum PDF gets emailed. If a slug here has no
  /// match there, the server logs it and skips that programme rather than
  /// failing the whole submission.
  final String slug;

  final String name;
  final String blurb;
  final (IconData, ForgeTone) spec;

  /// Who it is for, when that is worth stating separately from the blurb.
  final String? audience;
}

const forges = <Forge>[
  // ---------------------------------------------------------------
  Forge(
    name: 'FORGE Launch',
    forWhom: 'For young people entering adulthood',
    spec: (Icons.rocket_launch_rounded, ForgeTone.sea),
    programmes: [
      Programme(
        'launchpad',
        'LaunchPad',
        'Identity and purpose, independent living, budgeting and financial '
            'literacy, career readiness, digital skills, wellbeing, and the '
            'emotional resilience to make the move well.',
        (Icons.school_rounded, ForgeTone.sea),
        audience: 'Post-A Level school leavers, 16–18, preparing for '
            'university, work, or life abroad',
      ),
      Programme(
        'bridge',
        'Bridge',
        'Workplace etiquette, professional communication, personal financial '
            'management, promotability, and the working habits that turn a '
            'first job into a lasting career.',
        (Icons.swap_horiz_rounded, ForgeTone.teal),
        audience: 'University graduates, 21–26, stepping into their first '
            'professional roles',
      ),
    ],
  ),

  // ---------------------------------------------------------------
  Forge(
    name: 'FORGE Professional',
    forWhom: 'Building workplace and professional capability',
    spec: (Icons.work_rounded, ForgeTone.teal),
    programmes: [
      Programme(
        'apex',
        'Apex',
        'Team management, business finance, and legal literacy.',
        (Icons.star_rounded, ForgeTone.gold),
        audience: 'Technical professionals stepping into leadership',
      ),
      Programme(
        'measure',
        'Measure',
        'Donor-ready monitoring, evaluation, and learning.',
        (Icons.bar_chart_rounded, ForgeTone.sea),
        audience: 'NGO professionals',
      ),
      Programme(
        'grants-master',
        'Grants Master',
        'Grant compliance and financial stewardship.',
        (Icons.description_rounded, ForgeTone.teal),
        audience: 'NGO professionals',
      ),
      Programme(
        'people-edge',
        'People Edge',
        'Strategic human capital management.',
        (Icons.groups_rounded, ForgeTone.moss),
        audience: 'HR professionals',
      ),
      Programme(
        'toastmasters',
        'Toastmasters',
        'Public speaking mastery for confident communicators.',
        (Icons.mic_rounded, ForgeTone.ember),
      ),
      Programme(
        'leo',
        'LEO',
        'Competitive debate, argumentation, and rhetoric.',
        (Icons.forum_rounded, ForgeTone.gold),
      ),
      Programme(
        'retail',
        'Retail Management Training',
        'Stock, floor operations, and staff supervision.',
        (Icons.storefront_rounded, ForgeTone.sea),
        audience: 'Retail managers',
      ),
      Programme(
        'customer-care',
        'Customer Care',
        'Frontline customer engagement and service excellence.',
        (Icons.support_agent_rounded, ForgeTone.moss),
      ),
    ],
  ),

  // ---------------------------------------------------------------
  Forge(
    name: 'FORGE Leadership',
    forWhom: 'Governance, risk and leadership excellence',
    spec: (Icons.shield_rounded, ForgeTone.moss),
    programmes: [
      Programme(
        'sentinel',
        'Sentinel',
        'Applied enterprise risk management — moving from siloed compliance '
            'to a strategic seat.',
        (Icons.gpp_good_rounded, ForgeTone.teal),
        audience: 'Corporate risk professionals',
      ),
      Programme(
        'governance-plus',
        'Governance Plus',
        'Modern board governance, accountability, and the duties that come '
            'with the seat.',
        (Icons.account_balance_rounded, ForgeTone.moss),
        audience: 'Board members and senior leaders',
      ),
      Programme(
        'capital-edge',
        'Capital Edge',
        'Personal and institutional investment mastery.',
        (Icons.trending_up_rounded, ForgeTone.gold),
        audience: 'Finance professionals, investors, and leaders who never '
            'studied finance',
      ),
      Programme(
        'team-forge',
        'Team Forge',
        'Genuine cohesion built through experiential work and honest '
            'diagnostics, not away-day theatre.',
        (Icons.diversity_3_rounded, ForgeTone.ember),
        audience: 'Corporate teams',
      ),
    ],
  ),

  // ---------------------------------------------------------------
  Forge(
    name: 'FORGE Life',
    forWhom: 'Life transitions and legacy planning',
    spec: (Icons.wb_sunny_rounded, ForgeTone.ember),
    programmes: [
      Programme(
        'during-beyond-the-game',
        'During & Beyond the Game',
        'Financial discipline, income planning, and the psychological '
            'readiness for the day the game ends and the next chapter begins.',
        (Icons.bolt_rounded, ForgeTone.ember),
        audience: 'Professional and elite athletes while still active in sport',
      ),
      Programme(
        'legacy',
        'Legacy',
        'Succession planning, personal finance, and a lasting legacy blueprint '
            'for the people and institutions who come after them.',
        (Icons.auto_stories_rounded, ForgeTone.gold),
        audience: 'Artists, pastors, and social leaders carrying influence '
            'worth protecting',
      ),
      Programme(
        'transition-ready',
        'Transition Ready',
        'Financial runway, legal readiness, and the identity work that makes '
            'retirement a beginning rather than a loss.',
        (Icons.change_circle_rounded, ForgeTone.moss),
        audience: 'Professionals aged 45–65 approaching a planned or sudden '
            'career exit',
      ),
    ],
  ),

  // ---------------------------------------------------------------
  Forge(
    name: 'FORGE Experience',
    forWhom: 'Lifelong learning and engagement',
    spec: (Icons.auto_awesome_rounded, ForgeTone.gold),
    programmes: [
      Programme(
        'chess',
        'Chess',
        'Strategic thinking, concentration, patience, and mentorship through '
            'structured play, coaching, and friendly competition throughout '
            'the year, for beginners and experienced players alike.',
        (Icons.extension_rounded, ForgeTone.teal),
        audience: 'A standalone cognitive-fitness programme, open to every age',
      ),
      Programme(
        'forge-silver',
        'FORGE Silver',
        'Continued purpose, connection, and engagement through regular '
            'gatherings, shared learning, creative activity, coaching, '
            'mentoring the next generation, and the company of people in the '
            'very same season of life.',
        (Icons.spa_rounded, ForgeTone.moss),
        audience: 'An ongoing post-career community for retirees aged 55 and '
            'over',
      ),
    ],
  ),
];
