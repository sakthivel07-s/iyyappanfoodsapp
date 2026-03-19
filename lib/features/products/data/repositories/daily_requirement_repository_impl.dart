import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/daily_requirement.dart';
import '../../domain/repositories/daily_requirement_repository.dart';
import '../datasources/daily_requirement_remote_datasource.dart';
import '../models/daily_requirement_model.dart';

class DailyRequirementRepositoryImpl implements DailyRequirementRepository {
  final DailyRequirementRemoteDataSource _remoteDataSource;

  DailyRequirementRepositoryImpl(this._remoteDataSource);

  @override
  Stream<Either<Failure, List<DailyRequirement>>> getDailyRequirements(DateTime date) {
    return _remoteDataSource.getDailyRequirements(date);
  }

  @override
  Future<Either<Failure, void>> saveDailyRequirement(DailyRequirement requirement) {
    return _remoteDataSource.saveDailyRequirement(DailyRequirementModel(
      id: requirement.id,
      customerId: requirement.customerId,
      customerName: requirement.customerName,
      date: requirement.date,
      items: requirement.items,
      updatedAt: requirement.updatedAt,
    ));
  }
}
