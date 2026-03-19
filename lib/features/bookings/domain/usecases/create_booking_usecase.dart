import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  final BookingRepository _repository;
  CreateBookingUseCase(this._repository);
  Future<Either<Failure, String>> call(Booking booking) =>
      _repository.createBooking(booking);
}
