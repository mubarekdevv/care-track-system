import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_branding.dart';

class MarketplaceOrder {
  final String? id;
  final String parentId;
  final String parentName;
  final String email;
  final String phone;
  final String deliveryAddress;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final DateTime createdAt;
  final String status;

  const MarketplaceOrder({
    this.id,
    required this.parentId,
    required this.parentName,
    required this.email,
    required this.phone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.createdAt,
    this.status = 'pending',
  });

  int get itemCount =>
      items.fold(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1));

  String get shortId => id != null && id!.length >= 6 ? id!.substring(0, 6).toUpperCase() : '------';

  String get formattedDate => DateFormat('MMM d, yyyy • h:mm a').format(createdAt);

  /// Demo progression for tracking UI when status stays `pending` in Firestore.
  String get trackingStatus {
    if (status != 'pending') return status;
    final age = DateTime.now().difference(createdAt);
    if (age.inHours >= 48) return 'delivered';
    if (age.inHours >= 24) return 'shipped';
    if (age.inMinutes >= 30) return 'confirmed';
    return 'pending';
  }

  String get statusLabel {
    switch (trackingStatus) {
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  Color statusColor(BuildContext context) {
    switch (trackingStatus) {
      case 'confirmed':
        return const Color(0xFF4A90E2);
      case 'shipped':
        return const Color(0xFF9013FE);
      case 'delivered':
        return const Color(0xFF7ED321);
      case 'cancelled':
        return Colors.redAccent;
      default:
        return const Color(0xFFE2894A);
    }
  }

  static List<(String, String, String)> get trackingSteps => [
    ('pending', 'Order placed', 'We received your ${AppBranding.shopName} order'),
    ('confirmed', 'Confirmed', 'Items are being prepared for delivery'),
    ('shipped', 'Shipped', 'Your package is on the way'),
    ('delivered', 'Delivered', 'Order arrived at your address'),
  ];

  int get trackingStepIndex {
    final index = trackingSteps.indexWhere((step) => step.$1 == trackingStatus);
    return index >= 0 ? index : 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'parentName': parentName,
      'email': email,
      'phone': phone,
      'deliveryAddress': deliveryAddress,
      'items': items,
      'subtotal': subtotal,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory MarketplaceOrder.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime createdAt = DateTime.now();
    final raw = map['createdAt'];
    if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? createdAt;
    } else if (raw is DateTime) {
      createdAt = raw;
    }

    final rawItems = map['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    return MarketplaceOrder(
      id: documentId,
      parentId: map['parentId']?.toString() ?? '',
      parentName: map['parentName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      items: items,
      subtotal: (map['subtotal'] is num) ? (map['subtotal'] as num).toDouble() : 0,
      createdAt: createdAt,
      status: map['status']?.toString() ?? 'pending',
    );
  }
}
