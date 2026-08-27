import 'dart:convert';
import 'package:http/http.dart' as http;

class BlogPost {
  BlogPost({
    required this.slug,
    required this.title,
    this.excerpt,
    this.image,
    this.author,
    this.tags = const [],
    this.publishedAt,
    this.readMinutes = 1,
    this.body,
    this.url,
  });

  final String slug;
  final String title;
  final String? excerpt;
  final String? image;
  final String? author;
  final List<String> tags;
  final DateTime? publishedAt;
  final int readMinutes;
  final String? body;   // HTML, only on the detail response
  final String? url;

  factory BlogPost.fromJson(Map<String, dynamic> j) => BlogPost(
        slug: j['slug'] as String,
        title: j['title'] as String? ?? '',
        excerpt: j['excerpt'] as String?,
        image: j['image'] as String?,
        author: j['author'] as String?,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        publishedAt: j['published_at'] == null
            ? null
            : DateTime.tryParse(j['published_at'] as String),
        readMinutes: (j['read_minutes'] as num?)?.toInt() ?? 1,
        body: j['body'] as String?,
        url: j['url'] as String?,
      );

  String get dateLabel {
    if (publishedAt == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${publishedAt!.day} ${m[publishedAt!.month - 1]} ${publishedAt!.year}';
  }
}

/// Reads the website's blog. Public — no token needed, so the app can show
/// stories before anyone signs up.
class BlogApi {
  BlogApi({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  Future<List<BlogPost>> list() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/f4l/blog'),
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode >= 400) {
      throw Exception('Could not load the blog.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['posts'] as List)
        .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BlogPost> read(String slug) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/f4l/blog/$slug'),
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode >= 400) {
      throw Exception('Could not load that story.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return BlogPost.fromJson(data['post'] as Map<String, dynamic>);
  }
}
