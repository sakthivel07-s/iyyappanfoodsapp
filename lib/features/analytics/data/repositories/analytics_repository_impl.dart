import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource _dataSource;
  AnalyticsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, SalesReport>> getSalesReport(DateRangeModel dateRange, {String? customerId}) {
    return _dataSource.getSalesReport(dateRange, customerId: customerId);
  }
}
