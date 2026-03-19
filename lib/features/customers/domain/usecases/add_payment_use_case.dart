import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class AddPaymentUseCase {
  final PaymentRepository _repository;

  AddPaymentUseCase(this._repository);

  Future<Either<Failure, Unit>> call(Payment payment) {
    return _repository.addPayment(payment);
  }
}
