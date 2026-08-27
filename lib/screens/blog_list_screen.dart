import 'package:flutter/material.dart';

import '../services/blog_api.dart';
import '../theme/f4l_theme.dart';
import 'blog_post_screen.dart';

/// Sparks from the Forge — the website's blog, in the app.
class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  late Future<List<BlogPost>> _future;

  @override
  void initState() {
    super.initState();
    _future = BlogApi().list();
  }

  Future<void> _refresh() async {
    setState(() => _future = BlogApi().list());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Sparks from the Forge')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<BlogPost>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return ListView(
                    padding: const EdgeInsets.all(28),
                    children: [
                      const SizedBox(height: 60),
                      Icon(Icons.cloud_off, size: 34, color: mute),
                      const SizedBox(height: 12),
                      const Text('Could not load the stories.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Pull down to try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: mute)),
                    ],
                  );
                }

                final posts = snap.data ?? [];
                if (posts.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(28),
                    children: [
                      const SizedBox(height: 60),
                      Text('No stories published yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: mute)),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                  itemCount: posts.length,
                  itemBuilder: (context, i) => _PostCard(
                    post: posts[i],
                    featured: i == 0,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, this.featured = false});

  final BlogPost post;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BlogPostScreen(slug: post.slug, preview: post),
        )),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.image != null)
                AspectRatio(
                  aspectRatio: featured ? 1.9 : 2.4,
                  child: Image.network(
                    post.image!,
                    fit: BoxFit.cover,
                    // A broken image should collapse quietly, not throw a red
                    // box across the story list.
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    loadingBuilder: (c, w, p) => p == null
                        ? w
                        : Container(
                            color: F4L.teal.withValues(alpha: 0.06)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        post.dateLabel,
                        if (post.tags.isNotEmpty) post.tags.first,
                      ].where((s) => s.isNotEmpty).join(' · ').toUpperCase(),
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                          color: mute),
                    ),
                    const SizedBox(height: 7),
                    Text(post.title,
                        style: TextStyle(
                            fontSize: featured ? 20 : 17,
                            fontWeight: FontWeight.w800,
                            height: 1.25)),
                    if (post.excerpt != null) ...[
                      const SizedBox(height: 6),
                      Text(post.excerpt!,
                          maxLines: featured ? 4 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13.5, height: 1.55, color: mute)),
                    ],
                    const SizedBox(height: 10),
                    Row(children: [
                      if (post.author != null) ...[
                        Text(post.author!,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: mute)),
                        const SizedBox(width: 8),
                      ],
                      Text('${post.readMinutes} min read',
                          style: TextStyle(fontSize: 12, color: mute)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
