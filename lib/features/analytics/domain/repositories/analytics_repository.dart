import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../domain/entities/sales_report.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, SalesReport>> getSalesReport(DateRangeModel dateRange, {String? customerId});
}
