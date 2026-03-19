import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _dataSource;
  BookingRepositoryImpl(this._dataSource);

  @override
  Stream<Either<Failure, List<Booking>>> getBookings({
    DateRangeModel? dateRange,
    String? status,
    String? customerId,
  }) =>
      _dataSource.getBookings(dateRange: dateRange, status: status, customerId: customerId);

  @override
  Future<Either<Failure, Booking>> getBookingById(String id) =>
      _dataSource.getBookingById(id);

  @override
  Future<Either<Failure, String>> createBooking(Booking booking) {
    final model = BookingModel(
      id: booking.id.isEmpty ? const Uuid().v4() : booking.id,
      customerId: booking.customerId,
      customerName: booking.customerName,
      customerPhone: booking.customerPhone,
      items: booking.items,
      subtotal: booking.subtotal,
      discount: booking.discount,
      grandTotal: booking.grandTotal,
      status: 'confirmed',
      notes: booking.notes,
      bookingDate: booking.bookingDate,
      createdAt: DateTime.now(),
    );
    return _dataSource.createBooking(model);
  }

  @override
  Future<Either<Failure, void>> updateBookingStatus(String id, String status) =>
      _dataSource.updateBookingStatus(id, status);

  @override
  Future<Either<Failure, List<Booking>>> getBookingsForAnalytics(DateRangeModel dateRange) =>
      _dataSource.getBookingsForAnalytics(dateRange);
}
