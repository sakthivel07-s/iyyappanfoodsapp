import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Stream<Either<Failure, List<Booking>>> getBookings({
    DateRangeModel? dateRange,
    String? status,
    String? customerId,
  });
  Future<Either<Failure, Booking>> getBookingById(String id);
  Future<Either<Failure, String>> createBooking(BookingModel booking);
  Future<Either<Failure, void>> updateBookingStatus(String id, String status);
  Future<Either<Failure, List<Booking>>> getBookingsForAnalytics(DateRangeModel dateRange);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'bookings';

  BookingRemoteDataSourceImpl(this._firestore);

  @override
  Stream<Either<Failure, List<Booking>>> getBookings({
    DateRangeModel? dateRange,
    String? status,
    String? customerId,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(_collection);

    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    if (dateRange != null) {
      query = query
          .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('bookingDate', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end));
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query
        .orderBy('bookingDate', descending: true)
        .limit(200)
        .snapshots()
        .map<Either<Failure, List<Booking>>>((snap) {
      final list = snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
      return Right(list);
    }).handleError((e) => Left(ServerFailure(e.toString())));
  }

  @override
  Future<Either<Failure, Booking>> getBookingById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return const Left(NotFoundFailure());
      return Right(BookingModel.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createBooking(BookingModel booking) async {
    try {
      await _firestore.collection(_collection).doc(booking.id).set(booking.toFirestore());
      return Right(booking.id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookingStatus(String id, String status) async {
    try {
      await _firestore.collection(_collection).doc(id).update({'status': status});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getBookingsForAnalytics(DateRangeModel dateRange) async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('bookingDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('bookingDate',
              isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
          .where('status', isNotEqualTo: 'cancelled')
          .orderBy('status')
          .orderBy('bookingDate', descending: true)
          .get();

      final list = snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
