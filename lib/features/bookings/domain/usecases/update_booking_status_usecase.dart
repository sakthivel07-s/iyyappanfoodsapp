import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/booking_repository.dart';

class UpdateBookingStatusUseCase {
  final BookingRepository _repository;
  UpdateBookingStatusUseCase(this._repository);
  Future<Either<Failure, void>> call(String id, String status) =>
      _repository.updateBookingStatus(id, status);
}
