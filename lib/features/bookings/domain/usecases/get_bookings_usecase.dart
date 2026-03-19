import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class GetBookingsUseCase {
  final BookingRepository _repository;
  GetBookingsUseCase(this._repository);
  Stream<Either<Failure, List<Booking>>> call({DateRangeModel? dateRange, String? status, String? customerId}) =>
      _repository.getBookings(dateRange: dateRange, status: status, customerId: customerId);
}
