import 'package:equatable/equatable.dart';

class ProductAnalytics extends Equatable {
  final String productId;
  final String productName;
  final Map<String, double> revenueByUnit;   // unit -> revenue
  final Map<String, int> quantityByUnit;     // unit -> qty sold
  final double totalRevenue;
  final int totalQuantity;

  const ProductAnalytics({
    required this.productId,
    required this.productName,
    required this.revenueByUnit,
    required this.quantityByUnit,
    required this.totalRevenue,
    required this.totalQuantity,
  });

  @override
  List<Object?> get props => [productId];
}

class CustomerAnalytics extends Equatable {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final int orderCount;
  final double totalSpent;
  final DateTime? lastOrderDate;

  const CustomerAnalytics({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.orderCount,
    required this.totalSpent,
    this.lastOrderDate,
  });

  @override
  List<Object?> get props => [customerId];
}

class SalesReport extends Equatable {
  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;
  final int totalCustomers;
  final List<ProductAnalytics> topProducts;
  final List<CustomerAnalytics> topCustomers;
  final List<DailySales> dailyBreakdown;

  const SalesReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.totalCustomers,
    required this.topProducts,
    required this.topCustomers,
    required this.dailyBreakdown,
  });

  static const SalesReport empty = SalesReport(
    totalRevenue: 0,
    totalOrders: 0,
    avgOrderValue: 0,
    totalCustomers: 0,
    topProducts: [],
    topCustomers: [],
    dailyBreakdown: [],
  );

  @override
  List<Object?> get props => [totalRevenue, totalOrders];
}

class DailySales extends Equatable {
  final DateTime date;
  final double revenue;
  final int orders;

  const DailySales({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  @override
  List<Object?> get props => [date, revenue, orders];
}
