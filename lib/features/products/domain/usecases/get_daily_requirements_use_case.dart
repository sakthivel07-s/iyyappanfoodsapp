import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_requirement.dart';
import '../repositories/daily_requirement_repository.dart';

class GetDailyRequirementsUseCase {
  final DailyRequirementRepository _repository;
  GetDailyRequirementsUseCase(this._repository);

  Stream<Either<Failure, List<DailyRequirement>>> call(DateTime date) {
    return _repository.getDailyRequirements(date);
  }
}
