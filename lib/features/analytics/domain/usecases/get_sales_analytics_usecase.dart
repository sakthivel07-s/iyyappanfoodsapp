import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../entities/sales_report.dart';
import '../repositories/analytics_repository.dart';

class GetSalesAnalyticsUseCase {
  final AnalyticsRepository _repository;
  GetSalesAnalyticsUseCase(this._repository);

  Future<Either<Failure, SalesReport>> call(DateRangeModel dateRange, {String? customerId}) {
    return _repository.getSalesReport(dateRange, customerId: customerId);
  }
}
