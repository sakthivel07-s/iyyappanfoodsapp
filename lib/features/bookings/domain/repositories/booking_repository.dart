import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../entities/booking.dart';

abstract class BookingRepository {
  Stream<Either<Failure, List<Booking>>> getBookings({DateRangeModel? dateRange, String? status, String? customerId});
  Future<Either<Failure, Booking>> getBookingById(String id);
  Future<Either<Failure, String>> createBooking(Booking booking);
  Future<Either<Failure, void>> updateBookingStatus(String id, String status);
  Future<Either<Failure, List<Booking>>> getBookingsForAnalytics(DateRangeModel dateRange);
}
