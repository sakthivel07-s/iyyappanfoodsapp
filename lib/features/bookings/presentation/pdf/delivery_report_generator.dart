import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../domain/entities/booking.dart';

class DeliveryReportGenerator {
  static Future<Uint8List> generate({
    required List<Booking> bookings,
    required String dateRangeLabel,
  }) async {
    final pdf = pw.Document();

    // 1. Group by customer
    final Map<String, List<Booking>> customerBookings = {};
    for (final booking in bookings) {
      if (!customerBookings.containsKey(booking.customerName)) {
        customerBookings[booking.customerName] = [];
      }
      customerBookings[booking.customerName]!.add(booking);
    }

    // 2. Consolidated Load Summary
    final Map<String, double> consolidatedItems = {}; // Key: "ProductName (Unit)"
    for (final booking in bookings) {
      for (final item in booking.items) {
        final key = '${item.productName} (${item.unit})';
        consolidatedItems[key] = (consolidatedItems[key] ?? 0) + item.quantity;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(dateRangeLabel),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildLoadSummary(consolidatedItems),
          pw.SizedBox(height: 24),
          pw.Divider(thickness: 2, color: PdfColors.orange800),
          pw.SizedBox(height: 16),
          pw.Text('CUSTOMER-WISE DELIVERY DETAILS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
          pw.SizedBox(height: 12),
          ..._buildCustomerDetails(customerBookings),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String range) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(AppStrings.appName.toUpperCase(),
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
            pw.Text('DELIVERY REPORT',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text('Period: $range', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
        pw.Text('Generated on: ${AppDateUtils.formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildLoadSummary(Map<String, double> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const pw.BoxDecoration(color: PdfColors.orange100),
          child: pw.Text('TOTAL VEHICLE LOAD SUMMARY',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Item Description', 'Total Quantity'],
          data: items.entries.map((e) => [e.key, e.value.toStringAsFixed(1)]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellHeight: 25,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  static List<pw.Widget> _buildCustomerDetails(Map<String, List<Booking>> grouped) {
    List<pw.Widget> widgets = [];
    
    final sortedCustomers = grouped.keys.toList()..sort();

    for (final customer in sortedCustomers) {
      final bookings = grouped[customer]!;
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 12, bottom: 4),
          padding: const pw.EdgeInsets.all(6),
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          child: pw.Row(
            children: [
              pw.Text(customer.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.Spacer(),
              pw.Text('${bookings.length} Order(s)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ),
      );

      final Map<String, double> customerTotalItems = {};
      for (final b in bookings) {
        for (final item in b.items) {
          final key = '${item.productName} (${item.unit})';
          customerTotalItems[key] = (customerTotalItems[key] ?? 0) + item.quantity;
        }
      }

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, bottom: 8),
          child: pw.Column(
            children: customerTotalItems.entries.map((e) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.Text('•', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(width: 6),
                    pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                    pw.Spacer(),
                    pw.Text(e.value.toStringAsFixed(1), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
    return widgets;
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    );
  }
}
