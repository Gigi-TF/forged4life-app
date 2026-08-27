import 'package:flutter/material.dart';

import '../services/cafeteria_api.dart';
import '../services/prices.dart';
import '../theme/f4l_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<FoodOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = CafeteriaApi().myOrders();
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = CafeteriaApi().myOrders());
              await _future;
            },
            child: FutureBuilder<List<FoodOrder>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snap.data ?? [];
                if (orders.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(28),
                    children: [
                      const SizedBox(height: 70),
                      Text('No orders yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: mute)),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                  itemCount: orders.length,
                  itemBuilder: (_, i) => _OrderCard(order: orders[i]),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final FoodOrder order;

  Color _statusColour() => switch (order.status) {
        'placed' => F4L.tealMid,
        'preparing' => F4L.orange,
        'ready' || 'on_the_way' => F4L.teal,
        'cancelled' => Colors.red,
        _ => F4L.tealDeep,
      };

  String _modeLabel() => switch (order.fulfilment) {
        'eat_in' => 'Eat in',
        'delivery' => 'Delivery',
        _ => 'Collect',
      };

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(order.number,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColour(),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(order.statusLabel.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
                '${_modeLabel()} · ${order.items.length} item'
                '${order.items.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12.5, color: mute)),
            const SizedBox(height: 10),
            ...order.items.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(children: [
                    Text('${i.quantity}×  ',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: mute)),
                    Expanded(
                        child: Text(i.name,
                            style: const TextStyle(fontSize: 13.5))),
                    if (Prices.show)
                      Text(Prices.of(i.total),
                          style: const TextStyle(fontSize: 13)),
                  ]),
                )),
            const Divider(height: 20),
            Row(children: [
              if (order.discountPercent > 0)
                Text(
                    Prices.show
                        ? '${order.discountPercent}% member discount — saved '
                            '${Prices.of(order.discountAmount)}'
                        : '${order.discountPercent}% member discount applied',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: F4L.teal)),
              const Spacer(),
              Text(Prices.show ? Prices.of(order.total) : 'Pay at counter',
                  style: TextStyle(
                      fontSize: Prices.show ? 17 : 13,
                      fontWeight: FontWeight.w800)),
            ]),
          ],
        ),
      ),
    );
  }
}
