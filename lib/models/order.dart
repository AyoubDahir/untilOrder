import 'package:flutter/foundation.dart';

enum OrderStatus {
  draft,
  paid,
  done,
  invoiced,
  cancelled
}

class Order {
  final String id;
  final String reference;
  final double total;
  final DateTime date;
  final OrderStatus status;
  final String customerName;

  Order({
    required this.id,
    required this.reference,
    required this.total,
    required this.date,
    required this.status,
    required this.customerName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      reference: json['pos_reference'] ?? '',
      total: (json['amount_total'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date_order'] ?? DateTime.now().toIso8601String()),
      status: _parseStatus(json['state'] ?? ''),
      customerName: json['partner_id'] != null && json['partner_id'] is List 
          ? json['partner_id'][1] ?? 'Walk-in Customer'
          : 'Walk-in Customer',
    );
  }

  static OrderStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return OrderStatus.draft;
      case 'paid':
        return OrderStatus.paid;
      case 'done':
        return OrderStatus.done;
      case 'invoiced':
        return OrderStatus.invoiced;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.draft;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pos_reference': reference,
      'amount_total': total,
      'date_order': date.toIso8601String(),
      'state': describeEnum(status),
      'partner_id': [0, customerName],
    };
  }
}

class OrderItem {
  final int productId;
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  }) : subtotal = price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      quantity: json['qty']?.toInt() ?? 0,
      price: (json['price_unit'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'qty': quantity,
      'price_unit': price,
      'price_subtotal': subtotal,
    };
  }
}
