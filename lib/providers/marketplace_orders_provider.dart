import 'dart:async';

import 'package:flutter/material.dart';

import '../models/marketplace_order_model.dart';
import '../services/database_service.dart';

class MarketplaceOrdersProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<MarketplaceOrder> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<MarketplaceOrder>>? _subscription;

  List<MarketplaceOrder> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasOrders => _orders.isNotEmpty;

  void startListening(String parentId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _dbService.getMarketplaceOrdersForParent(parentId).listen(
      (data) {
        _orders = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _orders = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  MarketplaceOrder? orderById(String? id) {
    if (id == null) return null;
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }
}
