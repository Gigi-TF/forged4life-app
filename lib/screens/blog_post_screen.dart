import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/blog_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/blog_comments.dart';

/// A single story.
///
/// The body is plain text with blank lines between paragraphs — the Filament
/// field is a Textarea, not a rich editor — so there is no HTML or Markdown
/// to parse. The work here is typography: matching the website's measure,
/// line height and rhythm so the same words read the same way in both places.
class BlogPostScreen extends StatefulWidget {
  const BlogPostScreen({
    super.key,
    required this.slug,
    this.memberName = '',
    this.signedIn = true,
  });

  final String slug;
  final String memberName;
  final bool signedIn;

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  BlogPost? _post;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await BlogApi().read(widget.slug);
      if (mounted) setState(() { _post = p; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final p = _post;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : p == null
              ? _failed(context, mute)
              : CustomScrollView(
                  slivers: [
                    // The image as the header, the way the website opens a
                    // story — it sets the tone before a word is read.
                    SliverAppBar(
                      expandedHeight: p.image != null ? 260 : 0,
                      pinned: true,
                      backgroundColor:
                          Theme.of(context).colorScheme.surface,
                      flexibleSpace: p.image == null
                          ? null
                          : FlexibleSpaceBar(
                              background: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(p.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: F4L.teal)),
                                  // A scrim, so the back arrow stays legible
                                  // whatever the photograph happens to be.
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.center,
                                        colors: [Colors.black54,
                                                 Colors.transparent],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          // The website's measure. Prose wider than this is
                          // tiring to read, and a phone in landscape or a
                          // tablet would otherwise run the full width.
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(22, 26, 22, 50),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p.tags.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 7,
                                    runSpacing: 7,
                                    children: p.tags
                                        .take(4)
                                        .map((t) => _Tag(t))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                Text(p.title,
                                    style: const TextStyle(
                                        fontSize: 29,
                                        fontWeight: FontWeight.w800,
                                        height: 1.22,
                                        letterSpacing: -0.3)),

                                const SizedBox(height: 14),

                                Row(children: [
                                  if (p.author != null) ...[
                                    Text(p.author!,
                                        style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: mute)),
                                    Text('  ·  ',
                                        style: TextStyle(color: mute)),
                                  ],
                                  if (p.publishedAt != null) ...[
                                    Text(
                                        DateFormat('j MMMM yyyy')
                                            .format(p.publishedAt!),
                                        style: TextStyle(
                                            fontSize: 13.5, color: mute)),
                                    Text('  ·  ',
                                        style: TextStyle(color: mute)),
                                  ],
                                  Text('${p.readMinutes} min read',
                                      style: TextStyle(
                                          fontSize: 13.5, color: mute)),
                                ]),

                                const SizedBox(height: 22),

                                if (p.excerpt != null &&
                                    p.excerpt!.isNotEmpty) ...[
                                  // The standfirst, set apart the way a
                                  // magazine does — larger, with a rule.
                                  Container(
                                    padding:
                                        const EdgeInsets.only(left: 16),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                            color: F4L.orange, width: 3),
                                      ),
                                    ),
                                    child: Text(p.excerpt!,
                                        style: TextStyle(
                                            fontSize: 17,
                                            height: 1.62,
                                            fontStyle: FontStyle.italic,
                                            color: mute)),
                                  ),
                                  const SizedBox(height: 26),
                                ],

                                ..._paragraphs(p.body ?? ''),

                                const SizedBox(height: 30),
                                _ReadOnWeb(slug: p.slug),

                                BlogComments(
                                  slug: p.slug,
                                  memberName: widget.memberName,
                                  signedIn: widget.signedIn,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Blank-line-separated paragraphs, which is all the source contains.
  ///
  /// A short line on its own, with no sentence-ending punctuation, is treated
  /// as a subheading — that is how the writers are using the plain textarea,
  /// and rendering it as body text would lose the structure they intended.
  List<Widget> _paragraphs(String body) {
    final blocks = body
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'\n\s*\n'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty);

    return blocks.map<Widget>((block) {
      final oneLine = !block.contains('\n');
      final short = block.length < 70;
      final noStop = !RegExp(r'[.!?:]$').hasMatch(block);

      if (oneLine && short && noStop) {
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 10),
          child: Text(block,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  color: F4L.teal)),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(block,
            style: const TextStyle(
                fontSize: 16.5,
                height: 1.75,          // the website's line height
                letterSpacing: 0.1)),
      );
    }).toList();
  }

  Widget _failed(BuildContext context, Color? mute) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 30, color: mute),
              const SizedBox(height: 12),
              const Text('Could not load that story.',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: F4L.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label.trim().toUpperCase(),
            style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: F4L.teal)),
      );
}

class _ReadOnWeb extends StatelessWidget {
  const _ReadOnWeb({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return InkWell(
      onTap: () => launchUrl(
        Uri.parse('https://skillsforge360.org/blog/$slug'),
        mode: LaunchMode.externalApplication,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(Icons.open_in_new, size: 15, color: mute),
          const SizedBox(width: 8),
          Text('Read this on the website',
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: mute)),
        ]),
      ),
    );
  }
}
