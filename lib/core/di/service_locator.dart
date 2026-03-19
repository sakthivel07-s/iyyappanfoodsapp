import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/products/data/datasources/product_remote_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_products_usecase.dart';
import '../../features/products/domain/usecases/add_product_usecase.dart';
import '../../features/products/domain/usecases/update_product_usecase.dart';
import '../../features/products/domain/usecases/update_stock_usecase.dart';
import '../../features/products/domain/usecases/add_stock_usecase.dart';
import '../../features/products/domain/usecases/delete_product_usecase.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';
import '../../features/products/data/datasources/daily_requirement_remote_datasource.dart';
import '../../features/products/data/repositories/daily_requirement_repository_impl.dart';
import '../../features/products/domain/repositories/daily_requirement_repository.dart';
import '../../features/products/domain/usecases/get_daily_requirements_use_case.dart';
import '../../features/products/domain/usecases/save_daily_requirement_use_case.dart';
import '../../features/products/presentation/bloc/stock_planner_bloc.dart';
import '../../features/customers/data/datasources/customer_remote_datasource.dart';
import '../../features/customers/data/repositories/customer_repository_impl.dart';
import '../../features/customers/domain/repositories/customer_repository.dart';
import '../../features/customers/domain/usecases/get_customers_usecase.dart';
import '../../features/customers/domain/usecases/add_customer_usecase.dart';
import '../../features/customers/domain/usecases/update_customer_usecase.dart';
import '../../features/customers/domain/usecases/delete_customer_usecase.dart';
import '../../features/customers/domain/usecases/update_customer_stats_usecase.dart';
import '../../features/customers/presentation/bloc/customer_bloc.dart';
import '../../features/bookings/data/datasources/booking_remote_datasource.dart';
import '../../features/bookings/data/repositories/booking_repository_impl.dart';
import '../../features/bookings/domain/repositories/booking_repository.dart';
import '../../features/bookings/domain/usecases/create_booking_usecase.dart';
import '../../features/bookings/domain/usecases/get_bookings_usecase.dart';
import '../../features/bookings/domain/usecases/update_booking_status_usecase.dart';
import '../../features/bookings/domain/usecases/get_booking_by_id_usecase.dart';
import '../../features/customers/domain/usecases/get_customer_by_id_usecase.dart';
import '../../features/bookings/presentation/bloc/booking_bloc.dart';
import '../../features/analytics/data/datasources/analytics_remote_datasource.dart';
import '../../features/analytics/data/repositories/analytics_repository_impl.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/analytics/domain/usecases/get_sales_analytics_usecase.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../features/customers/data/datasources/payment_remote_datasource.dart';
import '../../features/customers/data/repositories/payment_repository_impl.dart';
import '../../features/customers/domain/repositories/payment_repository.dart';
import '../../features/customers/domain/usecases/add_payment_use_case.dart';
import '../../features/customers/domain/usecases/get_customer_ledger_use_case.dart';
import '../../features/customers/presentation/bloc/ledger_bloc.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // External
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // ---------- Products ----------
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateStockUseCase(sl()));
  sl.registerLazySingleton(() => AddStockUseCase(sl()));
  sl.registerLazySingleton(() => DeductStockUseCase(sl()));
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
    ),
  );

  // ---------- Daily Stock Planner ----------
  sl.registerLazySingleton<DailyRequirementRemoteDataSource>(
    () => DailyRequirementRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<DailyRequirementRepository>(
    () => DailyRequirementRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetDailyRequirementsUseCase(sl()));
  sl.registerLazySingleton(() => SaveDailyRequirementUseCase(sl()));
  sl.registerFactory(
    () => StockPlannerBloc(
      getCustomersUseCase: sl(),
      getDailyRequirementsUseCase: sl(),
      saveDailyRequirementUseCase: sl(),
      addStockUseCase: sl(),
      createBookingUseCase: sl(),
      getProductsUseCase: sl(),
      deductStockUseCase: sl(),
      updateCustomerStatsUseCase: sl(),
    ),
  );

  // ---------- Customers ----------
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));
  sl.registerLazySingleton(() => AddCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerStatsUseCase(sl()));
  sl.registerFactory(
    () => CustomerBloc(
      getCustomersUseCase: sl(),
      addCustomerUseCase: sl(),
      updateCustomerUseCase: sl(),
      deleteCustomerUseCase: sl(),
    ),
  );

  // ---------- Bookings ----------
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => CreateBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBookingStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerByIdUseCase(sl()));
  sl.registerFactory(
    () => BookingBloc(
      createBookingUseCase: sl(),
      getBookingsUseCase: sl(),
      updateBookingStatusUseCase: sl(),
      getProductsUseCase: sl(),
      updateCustomerStatsUseCase: sl(),
      getBookingByIdUseCase: sl(),
      getCustomerByIdUseCase: sl(),
    ),
  );

  // ---------- Analytics ----------
  sl.registerLazySingleton<AnalyticsRemoteDataSource>(
    () => AnalyticsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetSalesAnalyticsUseCase(sl()));
  sl.registerFactory(
    () => AnalyticsBloc(getSalesAnalyticsUseCase: sl()),
  );

  // ---------- Ledger & Payments ----------
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => AddPaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerLedgerUseCase(sl(), sl()));
  sl.registerFactory(
    () => LedgerBloc(
      getCustomerLedgerUseCase: sl(),
      addPaymentUseCase: sl(),
    ),
  );
}
