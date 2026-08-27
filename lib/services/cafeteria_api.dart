import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.emoji,
    this.available = true,
    this.prep = 15,
  });

  final int id;
  final String name;
  final double price;
  final String? description;
  final String? emoji;
  final bool available;
  final int prep;

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'] as int,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        description: j['description'] as String?,
        emoji: j['emoji'] as String?,
        available: j['available'] as bool? ?? true,
        prep: (j['prep'] as num?)?.toInt() ?? 15,
      );
}

class MenuSection {
  MenuSection({required this.name, required this.items});
  final String name;
  final List<MenuItem> items;

  factory MenuSection.fromJson(Map<String, dynamic> j) => MenuSection(
        name: j['name'] as String,
        items: (j['items'] as List)
            .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Menu {
  Menu({
    required this.sections,
    required this.deliveryFee,
    required this.open,
    required this.hours,
    required this.showPrices,
  });

  final List<MenuSection> sections;
  final double deliveryFee;
  final bool open;
  final String hours;
  final bool showPrices;
}

class FoodOrder {
  FoodOrder({
    required this.number,
    required this.status,
    required this.statusLabel,
    required this.fulfilment,
    required this.total,
    required this.discountPercent,
    required this.discountAmount,
    required this.items,
    this.placedAt,
  });

  final String number;
  final String status;
  final String statusLabel;
  final String fulfilment;
  final double total;
  final int discountPercent;
  final double discountAmount;
  final List<({String name, int quantity, double total})> items;
  final DateTime? placedAt;

  factory FoodOrder.fromJson(Map<String, dynamic> j) => FoodOrder(
        number: j['number'] as String,
        status: j['status'] as String,
        statusLabel: j['status_label'] as String,
        fulfilment: j['fulfilment'] as String,
        total: (j['total'] as num).toDouble(),
        discountPercent: (j['discount_percent'] as num?)?.toInt() ?? 0,
        discountAmount: (j['discount_amount'] as num?)?.toDouble() ?? 0,
        placedAt: j['placed_at'] == null
            ? null
            : DateTime.tryParse(j['placed_at'] as String),
        items: (j['items'] as List)
            .map((e) => (
                  name: e['name'] as String,
                  quantity: (e['quantity'] as num).toInt(),
                  total: (e['total'] as num).toDouble(),
                ))
            .toList(),
      );
}

class CafeteriaApi {
  CafeteriaApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  Future<Map<String, String>> _headers({bool auth = true}) async => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (auth)
          'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      };

  Future<Menu> menu() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/cafeteria/menu'),
        headers: await _headers(auth: false));

    if (res.statusCode >= 400) throw Exception('Could not load the menu.');

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return Menu(
      sections: (j['categories'] as List)
          .map((e) => MenuSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryFee: (j['delivery_fee'] as num).toDouble(),
      open: j['open'] as bool? ?? true,
      hours: j['hours'] as String? ?? '',
      showPrices: j['show_prices'] as bool? ?? false,
    );
  }

  Future<FoodOrder> placeOrder({
    required String fulfilment,
    required Map<int, int> quantities,
    String? tableNumber,
    String? address,
    String? notes,
    String? phone,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/cafeteria/order'),
      headers: await _headers(),
      body: jsonEncode({
        'fulfilment': fulfilment,
        'items': quantities.entries
            .map((e) => {'id': e.key, 'quantity': e.value})
            .toList(),
        if (tableNumber != null && tableNumber.isNotEmpty)
          'table_number': tableNumber,
        if (address != null && address.isNotEmpty) 'delivery_address': address,
        if (notes != null && notes.isNotEmpty) 'delivery_notes': notes,
        if (phone != null && phone.isNotEmpty) 'contact_phone': phone,
      }),
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not place the order.');
    }

    return FoodOrder.fromJson(j['order'] as Map<String, dynamic>);
  }

  Future<List<FoodOrder>> myOrders() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/cafeteria/orders'),
        headers: await _headers());

    if (res.statusCode >= 400) throw Exception('Could not load your orders.');

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['orders'] as List)
        .map((e) => FoodOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
