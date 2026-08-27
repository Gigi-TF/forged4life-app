import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'card_store.dart';

class PrintService {
  PrintService({
    required this.id,
    required this.slug,
    required this.name,
    required this.unit,
    required this.price,
    this.description,
    this.emoji,
    this.options = const {},
    this.upload = true,
  });

  final int id;
  final String slug;
  final String name;
  final String unit; // per_page | per_print | per_item | per_session
  final double price;
  final String? description;
  final String? emoji;
  final Map<String, List<String>> options;
  final bool upload;

  String get unitLabel => switch (unit) {
        'per_page' => 'per page',
        'per_print' => 'per print',
        'per_item' => 'each',
        _ => 'per sitting',
      };

  factory PrintService.fromJson(Map<String, dynamic> j) => PrintService(
        id: j['id'] as int,
        slug: j['slug'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String,
        price: (j['price'] as num).toDouble(),
        description: j['description'] as String?,
        emoji: j['emoji'] as String?,
        upload: j['upload'] as bool? ?? true,
        options: ((j['options'] as Map?) ?? {}).map(
          (k, v) => MapEntry(
              k.toString(), (v as List).map((e) => e.toString()).toList()),
        ),
      );
}

class PressCatalogue {
  PressCatalogue({
    required this.categories,
    required this.maxFileMb,
    required this.maxFiles,
    required this.purgeDays,
    required this.showPrices,
  });

  final Map<String, List<PrintService>> categories;
  final int maxFileMb;
  final int maxFiles;
  final int purgeDays;
  final bool showPrices;
}

class PressApi {
  PressApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  Future<PressCatalogue> services() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/press/services'),
        headers: {'Accept': 'application/json'});

    if (res.statusCode >= 400) throw Exception('Could not load The Press.');

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final cats = (j['categories'] as Map).map((k, v) => MapEntry(
          k.toString(),
          (v as List)
              .map((e) => PrintService.fromJson(e as Map<String, dynamic>))
              .toList(),
        ));

    return PressCatalogue(
      categories: cats,
      maxFileMb: (j['max_file_mb'] as num).toInt(),
      maxFiles: (j['max_files'] as num).toInt(),
      purgeDays: (j['purge_days'] as num).toInt(),
      showPrices: j['show_prices'] as bool? ?? false,
    );
  }

  /// Multipart, because files travel with the order in one request.
  Future<Map<String, dynamic>> placeOrder({
    required List<({int serviceId, int quantity, Map<String, String> options})>
        items,
    List<PlatformFile> files = const [],
    String? instructions,
  }) async {
    final req =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/f4l/press/order'))
          ..headers['Accept'] = 'application/json'
          ..headers['Authorization'] =
              'Bearer ${await CardStore.readAuthToken() ?? ''}';

    for (var i = 0; i < items.length; i++) {
      req.fields['items[$i][service_id]'] = items[i].serviceId.toString();
      req.fields['items[$i][quantity]'] = items[i].quantity.toString();
      items[i].options.forEach((k, v) {
        req.fields['items[$i][options][$k]'] = v;
      });
    }

    if (instructions != null && instructions.isNotEmpty) {
      req.fields['instructions'] = instructions;
    }

    for (final f in files) {
      if (f.bytes != null) {
        req.files.add(http.MultipartFile.fromBytes('files[]', f.bytes!,
            filename: f.name));
      } else if (f.path != null) {
        req.files.add(await http.MultipartFile.fromPath('files[]', f.path!,
            filename: f.name));
      }
    }

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    final j = jsonDecode(body) as Map<String, dynamic>;

    if (streamed.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not send the job.');
    }

    return j['order'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> slots(DateTime date) async {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final res = await http.get(
      Uri.parse('$baseUrl/api/f4l/press/studio/slots?date=$d'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      },
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['slots'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> bookStudio({
    required int serviceId,
    required String purpose,
    required DateTime date,
    required String time,
    String? country,
    int copies = 4,
  }) async {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/press/studio/book'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'purpose': purpose,
        'slot_date': d,
        'slot_time': time,
        'copies': copies,
        if (country != null && country.isNotEmpty) 'country': country,
      }),
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not book that slot.');
    }

    return j['booking'] as Map<String, dynamic>;
  }
}
