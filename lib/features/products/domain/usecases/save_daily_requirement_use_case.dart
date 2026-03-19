import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_requirement.dart';
import '../repositories/daily_requirement_repository.dart';

class SaveDailyRequirementUseCase {
  final DailyRequirementRepository _repository;
  SaveDailyRequirementUseCase(this._repository);

  Future<Either<Failure, void>> call(DailyRequirement requirement) {
    return _repository.saveDailyRequirement(requirement);
  }
}
