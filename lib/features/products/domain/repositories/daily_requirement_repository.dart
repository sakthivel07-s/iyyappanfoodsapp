import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_requirement.dart';

abstract class DailyRequirementRepository {
  Stream<Either<Failure, List<DailyRequirement>>> getDailyRequirements(DateTime date);
  Future<Either<Failure, void>> saveDailyRequirement(DailyRequirement requirement);
}
