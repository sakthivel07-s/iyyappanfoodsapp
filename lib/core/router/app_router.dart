import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/products/presentation/screens/add_edit_product_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/stock_management_screen.dart';
import '../../features/customers/presentation/screens/customer_list_screen.dart';
import '../../features/customers/presentation/screens/add_edit_customer_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/domain/entities/customer.dart';
import '../../features/bookings/presentation/screens/booking_list_screen.dart';
import '../../features/bookings/presentation/screens/create_booking_screen.dart';
import '../../features/bookings/presentation/screens/booking_detail_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/analytics/presentation/screens/customer_analytics_screen.dart';
import '../../features/customers/presentation/screens/customer_ledger_screen.dart';
import '../../features/products/presentation/screens/daily_stock_planner_screen.dart';
import '../widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/products',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProductListScreen()),
        ),
        GoRoute(
          path: '/customers',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerListScreen()),
        ),
        GoRoute(
          path: '/bookings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: BookingListScreen()),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AnalyticsScreen()),
        ),
      ],
    ),
    // Full-screen routes (outside shell)
    GoRoute(
      path: '/products/add',
      builder: (context, state) => const AddEditProductScreen(),
    ),
    GoRoute(
      path: '/products/edit/:id',
      builder: (context, state) => AddEditProductScreen(
        productId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/stock',
      builder: (context, state) => const StockManagementScreen(),
    ),
    GoRoute(
      path: '/stock-planner',
      builder: (context, state) => const DailyStockPlannerScreen(),
    ),
    GoRoute(
      path: '/products/:id',
      builder: (context, state) => ProductDetailScreen(
        productId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/customers/add',
      builder: (context, state) => const AddEditCustomerScreen(),
    ),
    GoRoute(
      path: '/customers/edit/:id',
      builder: (context, state) => AddEditCustomerScreen(
        customerId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/customers/:id',
      builder: (context, state) => CustomerDetailScreen(
        customerId: state.pathParameters['id']!,
      ),
      routes: [
        GoRoute(
          path: 'analytics',
          builder: (context, state) => CustomerAnalyticsScreen(
            customerId: state.pathParameters['id']!,
            customerName: state.uri.queryParameters['name'] ?? 'Customer',
          ),
        ),
        GoRoute(
          path: 'ledger',
          builder: (context, state) => CustomerLedgerScreen(
            customer: state.extra as Customer,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/bookings/create',
      builder: (context, state) => const CreateBookingScreen(),
    ),
    GoRoute(
      path: '/bookings/:id',
      builder: (context, state) => BookingDetailScreen(
        bookingId: state.pathParameters['id']!,
      ),
    ),
  ],
);
