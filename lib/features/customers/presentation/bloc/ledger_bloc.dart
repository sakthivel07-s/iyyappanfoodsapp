import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:iyyappan_foods/features/customers/domain/entities/ledger_entry.dart';
import 'package:iyyappan_foods/features/customers/domain/entities/payment.dart';
import 'package:iyyappan_foods/features/customers/domain/usecases/add_payment_use_case.dart';
import 'package:iyyappan_foods/features/customers/domain/usecases/get_customer_ledger_use_case.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class LedgerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadLedgerEvent extends LedgerEvent {
  final String customerId;
  final DateTime start;
  final DateTime end;

  LoadLedgerEvent({
    required this.customerId,
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [customerId, start, end];
}

class RecordPaymentEvent extends LedgerEvent {
  final Payment payment;
  RecordPaymentEvent(this.payment);

  @override
  List<Object?> get props => [payment];
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class LedgerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LedgerInitial extends LedgerState {}
class LedgerLoading extends LedgerState {}
class LedgerLoaded extends LedgerState {
  final List<LedgerEntry> entries;
  final double totalBilled;
  final double totalPaid;
  final double pendingBalance;

  LedgerLoaded({
    required this.entries,
    required this.totalBilled,
    required this.totalPaid,
    required this.pendingBalance,
  });

  @override
  List<Object?> get props => [entries, totalBilled, totalPaid, pendingBalance];
}

class PaymentSuccess extends LedgerState {}
class LedgerError extends LedgerState {
  final String message;
  LedgerError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  final GetCustomerLedgerUseCase getCustomerLedgerUseCase;
  final AddPaymentUseCase addPaymentUseCase;

  StreamSubscription? _ledgerSubscription;

  LedgerBloc({
    required this.getCustomerLedgerUseCase,
    required this.addPaymentUseCase,
  }) : super(LedgerInitial()) {
    on<LoadLedgerEvent>(_onLoadLedger);
    on<RecordPaymentEvent>(_onRecordPayment);
  }

  void _onLoadLedger(LoadLedgerEvent event, Emitter<LedgerState> emit) async {
    emit(LedgerLoading());
    
    await _ledgerSubscription?.cancel();
    
    await emit.forEach<dynamic>(
      getCustomerLedgerUseCase(event.customerId, event.start, event.end),
      onData: (result) {
        return result.fold(
          (failure) => LedgerError(failure.message),
          (entries) {
            double billed = 0;
            double paid = 0;
            for (final e in (entries as List<LedgerEntry>)) {
              if (e.type == LedgerEntryType.booking) {
                billed += e.amount;
              } else {
                paid += e.amount;
              }
            }
            return LedgerLoaded(
              entries: entries,
              totalBilled: billed,
              totalPaid: paid,
              pendingBalance: billed - paid,
            );
          },
        );
      },
    );
  }

  void _onRecordPayment(RecordPaymentEvent event, Emitter<LedgerState> emit) async {
    final result = await addPaymentUseCase(event.payment);
    result.fold(
      (failure) => emit(LedgerError(failure.message)),
      (_) {
        emit(PaymentSuccess());
        add(LoadLedgerEvent(
          customerId: event.payment.customerId,
          start: DateTime.now().subtract(const Duration(days: 365)),
          end: DateTime.now(),
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _ledgerSubscription?.cancel();
    return super.close();
  }
}
