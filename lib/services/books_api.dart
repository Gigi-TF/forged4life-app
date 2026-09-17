import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'card_store.dart';

class BookOffer {
  BookOffer(this.type, this.titles, this.quantity, this.status, this.label,
      this.at);

  final String type;
  final String titles;
  final int? quantity;
  final String status;
  final String label;
  final DateTime? at;

  bool get isDonation => type == 'donate';

  factory BookOffer.fromJson(Map<String, dynamic> j) => BookOffer(
        j['type'] as String? ?? 'sell',
        j['titles'] as String? ?? '',
        (j['quantity'] as num?)?.toInt(),
        j['status'] as String? ?? '',
        j['label'] as String? ?? '',
        j['at'] == null ? null : DateTime.tryParse(j['at'] as String)?.toLocal(),
      );
}

/// Selling and donating books.
///
/// Both land in the same `book_offers` table the website form writes to, so
/// staff see one list rather than two.
class BooksApi {
  BooksApi({this.baseUrl = Api.base});
  final String baseUrl;

  Future<Map<String, String>> _headers() async => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      };

  Future<String> sell({
    required String titles,
    int? quantity,
    String? condition,
    double? askingPrice,
    String? location,
    String? notes,
  }) async =>
      _post('books/sell', {
        'titles': titles,
        if (quantity != null) 'quantity': quantity,
        if (condition != null && condition.isNotEmpty) 'condition': condition,
        if (askingPrice != null) 'asking_price': askingPrice,
        if (location != null && location.isNotEmpty) 'location': location,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

  Future<String> donate({
    required String titles,
    int? quantity,
    String? location,
    String? notes,
  }) async =>
      _post('books/donate', {
        'titles': titles,
        if (quantity != null) 'quantity': quantity,
        if (location != null && location.isNotEmpty) 'location': location,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

  Future<List<BookOffer>> mine() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/f4l/books/mine'),
          headers: await _headers());

      if (res.statusCode >= 400) return [];

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return (j['offers'] as List)
          .map((e) => BookOffer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      final errors = j['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        throw Exception((errors.values.first as List).first.toString());
      }
      throw Exception(j['message']?.toString() ?? 'Could not send that.');
    }

    return j['message']?.toString() ?? 'Thank you.';
  }
}
