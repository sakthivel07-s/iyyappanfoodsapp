import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerStatsUseCase {
  final CustomerRepository _repository;

  UpdateCustomerStatsUseCase(this._repository);

  Future<Either<Failure, void>> call(String customerId, double addedAmount) {
    return _repository.updateCustomerStats(customerId, addedAmount);
  }
}
