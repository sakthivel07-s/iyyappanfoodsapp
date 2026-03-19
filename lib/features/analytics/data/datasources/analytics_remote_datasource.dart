import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../domain/entities/sales_report.dart';

abstract class AnalyticsRemoteDataSource {
  Future<Either<Failure, SalesReport>> getSalesReport(DateRangeModel dateRange, {String? customerId});
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final FirebaseFirestore _firestore;
  AnalyticsRemoteDataSourceImpl(this._firestore);

  @override
  Future<Either<Failure, SalesReport>> getSalesReport(DateRangeModel dateRange, {String? customerId}) async {
    try {
      var query = _firestore
          .collection('bookings')
          .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('bookingDate', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
          .where('status', isNotEqualTo: 'cancelled');

      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }

      final snap = await query.orderBy('status').orderBy('bookingDate').get();

      if (snap.docs.isEmpty) return const Right(SalesReport.empty);

      double totalRevenue = 0;
      int totalOrders = snap.docs.length;
      final Set<String> uniqueCustomers = {};

      final Map<String, Map<String, dynamic>> productMap = {};
      final Map<String, Map<String, dynamic>> customerMap = {};
      final Map<String, DailySales> dailyMap = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        final grandTotal = (data['grandTotal'] as num?)?.toDouble() ?? 0.0;
        final customerId = data['customerId'] as String? ?? '';
        final customerName = data['customerName'] as String? ?? '';
        final customerPhone = data['customerPhone'] as String? ?? '';
        final bookingDate = (data['bookingDate'] as Timestamp).toDate();
        final dateKey = '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';

        totalRevenue += grandTotal;
        uniqueCustomers.add(customerId);

        // Daily breakdown
        if (dailyMap.containsKey(dateKey)) {
          final existing = dailyMap[dateKey]!;
          dailyMap[dateKey] = DailySales(
            date: existing.date,
            revenue: existing.revenue + grandTotal,
            orders: existing.orders + 1,
          );
        } else {
          dailyMap[dateKey] = DailySales(
            date: bookingDate,
            revenue: grandTotal,
            orders: 1,
          );
        }

        // Customer analytics
        if (!customerMap.containsKey(customerId)) {
          customerMap[customerId] = {
            'name': customerName,
            'phone': customerPhone,
            'spent': 0.0,
            'count': 0,
            'lastOrder': bookingDate,
          };
        }
        customerMap[customerId]!['spent'] =
            (customerMap[customerId]!['spent'] as double) + grandTotal;
        customerMap[customerId]!['count'] =
            (customerMap[customerId]!['count'] as int) + 1;

        // Product analytics
        final items = data['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final productId = item['productId'] as String? ?? '';
          final productName = item['productName'] as String? ?? '';
          final unit = item['unit'] as String? ?? '';
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          final totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;

          if (!productMap.containsKey(productId)) {
            productMap[productId] = {
              'name': productName,
              'revenueByUnit': <String, double>{},
              'quantityByUnit': <String, int>{},
              'total': 0.0,
              'totalQty': 0,
            };
          }

          final revenueByUnit = productMap[productId]!['revenueByUnit'] as Map<String, double>;
          final quantityByUnit = productMap[productId]!['quantityByUnit'] as Map<String, int>;

          revenueByUnit[unit] = (revenueByUnit[unit] ?? 0) + totalPrice;
          quantityByUnit[unit] = (quantityByUnit[unit] ?? 0) + qty;

          productMap[productId]!['total'] =
              (productMap[productId]!['total'] as double) + totalPrice;
          productMap[productId]!['totalQty'] =
              (productMap[productId]!['totalQty'] as int) + qty;
        }
      }

      final topProducts = productMap.entries
          .map((e) => ProductAnalytics(
                productId: e.key,
                productName: e.value['name'] as String,
                revenueByUnit: e.value['revenueByUnit'] as Map<String, double>,
                quantityByUnit: e.value['quantityByUnit'] as Map<String, int>,
                totalRevenue: e.value['total'] as double,
                totalQuantity: e.value['totalQty'] as int,
              ))
          .toList()
        ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      final topCustomers = customerMap.entries
          .map((e) => CustomerAnalytics(
                customerId: e.key,
                customerName: e.value['name'] as String,
                customerPhone: e.value['phone'] as String,
                orderCount: e.value['count'] as int,
                totalSpent: e.value['spent'] as double,
                lastOrderDate: e.value['lastOrder'] as DateTime,
              ))
          .toList()
        ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

      final dailyBreakdown = dailyMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return Right(SalesReport(
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        avgOrderValue: totalOrders > 0 ? totalRevenue / totalOrders : 0,
        totalCustomers: uniqueCustomers.length,
        topProducts: topProducts,
        topCustomers: topCustomers,
        dailyBreakdown: dailyBreakdown,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
