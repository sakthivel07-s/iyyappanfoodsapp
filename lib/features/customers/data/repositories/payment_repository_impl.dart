import 'package:dartz/dartz.dart';
import 'package:iyyappan_foods/core/errors/failures.dart';
import 'package:iyyappan_foods/features/customers/data/datasources/payment_remote_datasource.dart';
import 'package:iyyappan_foods/features/customers/domain/entities/payment.dart';
import 'package:iyyappan_foods/features/customers/data/models/payment_model.dart';
import 'package:iyyappan_foods/features/customers/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;

  PaymentRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, Unit>> addPayment(Payment payment) async {
    try {
      final model = PaymentModel(
        id: payment.id,
        customerId: payment.customerId,
        amount: payment.amount,
        date: payment.date,
        paymentMethod: payment.paymentMethod,
        notes: payment.notes,
      );
      await _remoteDataSource.addPayment(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Payment>>> getCustomerPayments(String customerId) {
    return _remoteDataSource.getCustomerPayments(customerId).map(
      (models) => Right<Failure, List<Payment>>(models),
    ).handleError((e) => Left(ServerFailure(e.toString())));
  }
}
