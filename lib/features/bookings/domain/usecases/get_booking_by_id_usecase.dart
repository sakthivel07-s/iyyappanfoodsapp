import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class GetBookingByIdUseCase {
  final BookingRepository repository;

  GetBookingByIdUseCase(this.repository);

  Future<Either<Failure, Booking?>> call(String id) {
    return repository.getBookingById(id);
  }
}
