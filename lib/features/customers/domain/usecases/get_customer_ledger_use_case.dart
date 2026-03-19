import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';
import 'package:iyyappan_foods/core/errors/failures.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/domain/repositories/booking_repository.dart';
import '../entities/ledger_entry.dart';
import 'package:iyyappan_foods/features/customers/domain/entities/payment.dart';
import 'package:iyyappan_foods/features/customers/domain/repositories/payment_repository.dart';

class GetCustomerLedgerUseCase {
  final BookingRepository _bookingRepository;
  final PaymentRepository _paymentRepository;

  GetCustomerLedgerUseCase(this._bookingRepository, this._paymentRepository);

  Stream<Either<Failure, List<LedgerEntry>>> call(String customerId, DateTime start, DateTime end) {
    // We combine bookings stream and payments stream
    final bookingsStream = _bookingRepository.getBookings(customerId: customerId);
    final paymentsStream = _paymentRepository.getCustomerPayments(customerId);

    return CombineLatestStream.combine2<Either<Failure, List<Booking>>, Either<Failure, List<Payment>>, Either<Failure, List<LedgerEntry>>>(
      bookingsStream,
      paymentsStream,
      (bookingsResult, paymentsResult) {
        return bookingsResult.fold(
          (f) => Left(f),
          (bookings) {
            return paymentsResult.fold(
              (f) => Left(f),
              (payments) {
                // Filter and merge
                final List<LedgerEntry> entries = [];
                
                // Add bookings as entries
                for (final b in bookings) {
                  if (b.bookingDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
                      b.bookingDate.isBefore(end.add(const Duration(days: 1)))) {
                    entries.add(LedgerEntry(
                      id: b.id,
                      customerId: b.customerId,
                      amount: b.grandTotal,
                      date: b.bookingDate,
                      title: 'Order Summary',
                      subtitle: '${b.items.length} item(s)',
                      type: LedgerEntryType.booking,
                    ));
                  }
                }

                // Add payments as entries
                for (final p in payments) {
                  if (p.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
                      p.date.isBefore(end.add(const Duration(days: 1)))) {
                    entries.add(LedgerEntry(
                      id: p.id,
                      customerId: p.customerId,
                      amount: p.amount,
                      date: p.date,
                      title: 'Payment Received',
                      subtitle: p.paymentMethod + (p.notes != null ? ': ${p.notes}' : ''),
                      type: LedgerEntryType.payment,
                    ));
                  }
                }

                // Sort by date descending
                entries.sort((a, b) => b.date.compareTo(a.date));
                return Right(entries);
              },
            );
          },
        );
      },
    );
  }
}
