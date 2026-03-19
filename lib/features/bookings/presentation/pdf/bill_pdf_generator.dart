import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../domain/entities/booking.dart';

class BillPdfGenerator {
  static Future<Uint8List> generate(Booking booking) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(booking),
                pw.SizedBox(height: 32),
                _buildCustomerInfo(booking),
                pw.SizedBox(height: 32),
                _buildInvoiceTable(booking),
                pw.SizedBox(height: 32),
                _buildSummary(booking),
                pw.Spacer(),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Booking booking) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(AppStrings.appName.toUpperCase(),
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
            pw.Text('Fresh & Healthy Food Supplies', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Order ID: ${booking.id.substring(0, 8).toUpperCase()}'),
            pw.Text('Date: ${AppDateUtils.formatDate(booking.bookingDate)}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(Booking booking) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(booking.customerName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(booking.customerPhone),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceTable(Booking booking) {
    const headers = ['Product', 'Unit', 'Qty', 'Price', 'Total'];

    final data = booking.items.map((item) {
      return [
        item.productName,
        item.unit,
        item.quantity.toString(),
        CurrencyFormatter.format(item.unitPrice),
        CurrencyFormatter.format(item.totalPrice),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildSummary(Booking booking) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _summaryRow('Subtotal', CurrencyFormatter.format(booking.subtotal)),
            pw.SizedBox(height: 4),
            if (booking.discount > 0) ...[
              _summaryRow('Discount', '- ${CurrencyFormatter.format(booking.discount)}', color: PdfColors.green700),
              pw.SizedBox(height: 4),
            ],
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text('Grand Total:  ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(CurrencyFormatter.format(booking.grandTotal),
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryRow(String label, String value, {PdfColor? color}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label:  '),
        pw.Text(value, style: pw.TextStyle(color: color)),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text('Thank you for your business!',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
        ),
      ],
    );
  }
}
