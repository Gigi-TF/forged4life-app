import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/blog_api.dart';
import '../theme/f4l_theme.dart';

/// A single story. The body arrives as HTML from the website, so it renders
/// through flutter_html rather than being re-authored for the app.
class BlogPostScreen extends StatefulWidget {
  const BlogPostScreen({super.key, required this.slug, this.preview});

  final String slug;

  /// The list card we came from — lets the title and image paint immediately
  /// while the full body loads.
  final BlogPost? preview;

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  late Future<BlogPost> _future;

  @override
  void initState() {
    super.initState();
    _future = BlogApi().read(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final ink = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        actions: [
          FutureBuilder<BlogPost>(
            future: _future,
            builder: (c, s) => IconButton(
              tooltip: 'Open on the website',
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: s.data?.url == null
                  ? null
                  : () => launchUrl(Uri.parse(s.data!.url!),
                      mode: LaunchMode.externalApplication),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: FutureBuilder<BlogPost>(
            future: _future,
            builder: (context, snap) {
              final post = snap.data ?? widget.preview;

              if (post == null) {
                return snap.hasError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text('Could not load that story.',
                              style: TextStyle(color: mute)),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  Text(
                    [
                      post.dateLabel,
                      if (post.tags.isNotEmpty) post.tags.first,
                    ].where((s) => s.isNotEmpty).join(' · ').toUpperCase(),
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: mute),
                  ),
                  const SizedBox(height: 8),
                  Text(post.title,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.22)),
                  const SizedBox(height: 10),
                  Row(children: [
                    if (post.author != null) ...[
                      Text(post.author!,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: mute)),
                      const SizedBox(width: 8),
                    ],
                    Text('${post.readMinutes} min read',
                        style: TextStyle(fontSize: 13, color: mute)),
                  ]),
                  const SizedBox(height: 18),

                  if (post.image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(post.image!,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  const SizedBox(height: 20),

                  if (post.body != null)
                    Html(
                      data: post.body!,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(15.5),
                          lineHeight: LineHeight.number(1.68),
                          color: ink,
                        ),
                        'p': Style(margin: Margins.only(bottom: 16)),
                        'h2': Style(
                          fontSize: FontSize(20),
                          fontWeight: FontWeight.w800,
                          margin: Margins.only(top: 22, bottom: 8),
                        ),
                        'h3': Style(
                          fontSize: FontSize(17),
                          fontWeight: FontWeight.w800,
                          margin: Margins.only(top: 18, bottom: 6),
                        ),
                        'blockquote': Style(
                          margin: Margins.symmetric(vertical: 18),
                          padding: HtmlPaddings.only(left: 16),
                          border: const Border(
                              left: BorderSide(color: F4L.orange, width: 3)),
                          fontStyle: FontStyle.italic,
                          color: mute,
                        ),
                        'a': Style(color: F4L.orange),
                        'img': Style(margin: Margins.symmetric(vertical: 12)),
                      },
                      onLinkTap: (url, _, __) {
                        if (url != null) {
                          launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
