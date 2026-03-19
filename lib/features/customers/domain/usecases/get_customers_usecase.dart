import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class GetCustomersUseCase {
  final CustomerRepository _repository;
  GetCustomersUseCase(this._repository);
  Stream<Either<Failure, List<Customer>>> call() => _repository.getCustomers();
}
