import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/usecases/get_sales_analytics_usecase.dart';
import '../../../../core/utils/app_date_utils.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class AnalyticsEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadAnalyticsEvent extends AnalyticsEvent {
  final DateRangeModel dateRange;
  final String? customerId;
  LoadAnalyticsEvent(this.dateRange, {this.customerId});
  @override List<Object?> get props => [dateRange, customerId];
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class AnalyticsState extends Equatable {
  @override List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}
class AnalyticsLoading extends AnalyticsState {}
class AnalyticsLoaded extends AnalyticsState {
  final SalesReport report;
  final DateRangeModel dateRange;
  AnalyticsLoaded({required this.report, required this.dateRange});
  @override List<Object?> get props => [report, dateRange];
}
class AnalyticsError extends AnalyticsState {
  final String message;
  AnalyticsError(this.message);
  @override List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final GetSalesAnalyticsUseCase getSalesAnalyticsUseCase;

  AnalyticsBloc({required this.getSalesAnalyticsUseCase}) : super(AnalyticsInitial()) {
    on<LoadAnalyticsEvent>(_onLoad);
  }

  void _onLoad(LoadAnalyticsEvent event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    final result = await getSalesAnalyticsUseCase(event.dateRange, customerId: event.customerId);
    result.fold(
      (f) => emit(AnalyticsError(f.message)),
      (report) => emit(AnalyticsLoaded(report: report, dateRange: event.dateRange)),
    );
  }
}
