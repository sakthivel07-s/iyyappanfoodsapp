import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Either<Failure, Unit>> addPayment(Payment payment);
  Stream<Either<Failure, List<Payment>>> getCustomerPayments(String customerId);
}
