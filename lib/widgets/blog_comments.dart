import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/comments_api.dart';
import '../theme/f4l_theme.dart';

/// Comments under a post.
///
/// The same `comments` table the website uses, so a conversation under a post
/// is one conversation rather than two that cannot see each other.
class BlogComments extends StatefulWidget {
  const BlogComments({
    super.key,
    required this.slug,
    required this.memberName,
    required this.signedIn,
  });

  final String slug;
  final String memberName;
  final bool signedIn;

  @override
  State<BlogComments> createState() => _BlogCommentsState();
}

class _BlogCommentsState extends State<BlogComments> {
  final _body = TextEditingController();

  List<BlogComment> _approved = [];
  List<BlogComment> _mine = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final approved = await CommentsApi().forPost(widget.slug);

    final mine = widget.signedIn
        ? await CommentsApi().mine(widget.slug, widget.memberName)
        : <BlogComment>[];

    if (mounted) {
      setState(() {
        _approved = approved;
        // Only the ones still waiting — an approved one is already in the
        // list above, and showing it twice looks like a bug.
        _mine = mine.where((c) => !c.approved).toList();
        _loading = false;
      });
    }
  }

  Future<void> _post() async {
    final text = _body.text.trim();
    if (text.length < 2) return;

    setState(() => _busy = true);

    try {
      final msg = await CommentsApi().post(widget.slug, text);
      _body.clear();
      await _load();

      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final total = _approved.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 34),
        Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
        const SizedBox(height: 22),

        Text(
          total == 0
              ? 'No comments yet'
              : total == 1
                  ? '1 comment'
                  : '$total comments',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        ..._approved.map((c) => _Comment(comment: c)),

        // Waiting for approval. Shown to the author only, so they know it
        // landed — a comment that disappears gets posted again.
        ..._mine.map((c) => _Comment(comment: c, pending: true)),

        const SizedBox(height: 18),

        if (widget.signedIn) ...[
          TextField(
            controller: _body,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Add your thoughts…',
              counterStyle: TextStyle(fontSize: 11, color: mute),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: Text(
                'Posting as ${widget.memberName}. Comments appear once '
                'checked.',
                style: TextStyle(fontSize: 11.5, height: 1.45, color: mute),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _busy ? null : _post,
              style: FilledButton.styleFrom(
                backgroundColor: F4L.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Post',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: F4L.teal.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Sign in to join the conversation.',
              style: TextStyle(fontSize: 13.5, color: mute),
            ),
          ),
      ],
    );
  }
}

class _Comment extends StatelessWidget {
  const _Comment({required this.comment, this.pending = false});

  final BlogComment comment;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    final initials = comment.name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Opacity(
        opacity: pending ? 0.62 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: F4L.teal.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: F4L.teal)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(comment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    if (comment.at != null) ...[
                      const SizedBox(width: 8),
                      Text(DateFormat('j MMM').format(comment.at!),
                          style: TextStyle(fontSize: 11.5, color: mute)),
                    ],
                    if (pending) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: F4L.orange.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('AWAITING CHECK',
                            style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: F4L.orange)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 5),
                  Text(comment.body,
                      style: const TextStyle(fontSize: 14.5, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
