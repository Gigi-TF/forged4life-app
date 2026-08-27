import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

class ShelfItem {
  ShelfItem({
    required this.id,
    required this.title,
    required this.price,
    required this.format,
    required this.condition,
    this.author,
    this.category,
    this.cover,
    this.secondHand = false,
    this.description,
  });

  final int id;
  final String title;
  final double price;
  final String format;      // physical | digital
  final String condition;   // new | good | fair
  final String? author;
  final String? category;
  final String? cover;
  final bool secondHand;
  final String? description;

  bool get isDigital => format == 'digital';

  String get conditionLabel => switch (condition) {
        'new' => 'New',
        'fair' => 'Well read',
        _ => 'Good condition',
      };

  factory ShelfItem.fromJson(Map<String, dynamic> j) => ShelfItem(
        id: j['id'] as int,
        title: j['title'] as String,
        price: (j['price'] as num).toDouble(),
        format: j['format'] as String? ?? 'physical',
        condition: j['condition'] as String? ?? 'good',
        author: j['author'] as String?,
        category: j['category'] as String?,
        cover: j['cover'] as String?,
        secondHand: j['second_hand'] as bool? ?? false,
        description: j['description'] as String?,
      );
}

class MyListing {
  MyListing(this.id, this.title, this.author, this.price, this.youGet,
      this.status, this.label, this.paidOut);

  final int id;
  final String title;
  final String? author;
  final double price;
  final double youGet;
  final String status;
  final String label;
  final bool paidOut;

  factory MyListing.fromJson(Map<String, dynamic> j) => MyListing(
        j['id'] as int,
        j['title'] as String,
        j['author'] as String?,
        (j['price'] as num).toDouble(),
        (j['you_get'] as num).toDouble(),
        j['status'] as String,
        j['label'] as String,
        j['paid_out'] as bool? ?? false,
      );
}

class Shelf {
  Shelf({
    required this.items,
    required this.categories,
    required this.commission,
    required this.holdDays,
  });

  final List<ShelfItem> items;
  final List<String> categories;
  final int commission;
  final int holdDays;

  /// What a seller keeps, as a percentage.
  int get sellerShare => 100 - commission;
}

class ShelfApi {
  ShelfApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  Future<Map<String, String>> _headers() async {
    final t = await CardStore.readAuthToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<Shelf> browse({String? category, String? search}) async {
    final params = <String, String>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse('$baseUrl/api/f4l/shelf')
        .replace(queryParameters: params.isEmpty ? null : params);

    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode >= 400) throw Exception('Could not load The Shelf.');

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return Shelf(
      items: (j['items'] as List)
          .map((e) => ShelfItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories:
          (j['categories'] as List).map((e) => e.toString()).toList(),
      commission: (j['commission'] as num).toInt(),
      holdDays: (j['hold_days'] as num).toInt(),
    );
  }

  Future<String> reserve(int id) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/f4l/shelf/$id/reserve'),
        headers: await _headers());

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not reserve that.');
    }
    return j['message']?.toString() ?? 'Reserved.';
  }

  Future<String> offer({
    required String title,
    String? author,
    String? category,
    required String condition,
    required double price,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/shelf/offer'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        if (author != null && author.isNotEmpty) 'author': author,
        if (category != null && category.isNotEmpty) 'category': category,
        'condition': condition,
        'price': price,
        if (description != null && description.isNotEmpty)
          'description': description,
      }),
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not list that.');
    }
    return j['message']?.toString() ?? 'Listed.';
  }

  Future<List<MyListing>> myListings() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/shelf/mine'),
        headers: await _headers());

    if (res.statusCode >= 400) return [];

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['items'] as List)
        .map((e) => MyListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> withdraw(int id) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/f4l/shelf/$id/withdraw'),
        headers: await _headers());

    if (res.statusCode >= 400) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(j['message']?.toString() ?? 'Could not withdraw that.');
    }
  }
}
