import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class QuotationScreen extends StatefulWidget {
  @override
  _QuotationScreenState createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final _recipientController = TextEditingController();
  final _signatoryController = TextEditingController();
  final _paymentTermsController = TextEditingController(); // New controller

  List<Map<String, dynamic>> items = [
    {'item': '', 'description': '', 'quantity': 1, 'unitCost': 0.0, 'amount': 0.0},
  ];

  DateTime _quotationDate = DateTime.now();
  double _totalAmount = 0.0; // Variable to store total amount

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Quotation',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[100], // Light blue-gray background
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        color: Colors.blueGrey[50], // Slightly lighter background
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Recipient input field
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 10),

              // Payment Terms input field
              TextFormField(
                controller: _paymentTermsController,
                decoration: InputDecoration(
                  labelText: 'Payment Terms',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 10),

              // Horizontal divider
              Divider(color: Colors.grey[400]),

              // Data Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDataTable(),
              ),

              // Horizontal divider
              Divider(color: Colors.grey[400]),

              // Display total amount
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: Ksh ${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 10),

              // Add New Item Button
              ElevatedButton(
                onPressed: _addNewItem,
                child: Text('Add New Item'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.teal[400], // Teal button color
                ),
              ),

              SizedBox(height: 10),

              // Signatory input field
              TextFormField(
                controller: _signatoryController,
                decoration: InputDecoration(
                  labelText: 'Signatory Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),

              // Save and Share Quotation Buttons
              ElevatedButton(
                onPressed: _generateAndSavePdf,
                child: Text('Save Quotation Locally'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.teal[400], // Teal button color
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sharePdf,
                child: Text('Share Quotation'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.teal[400], // Teal button color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      columns: [
        DataColumn(label: Text('Item')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('Unit Cost (Ksh)')),
        DataColumn(label: Text('Amount (Ksh)')),
      ],
      rows: items.map((item) {
        return DataRow(cells: [
          DataCell(TextFormField(
            onChanged: (value) {
              setState(() {
                item['item'] = value;
              });
            },
          )),
          DataCell(TextFormField(
            onChanged: (value) {
              setState(() {
                item['description'] = value;
              });
            },
          )),
          DataCell(TextFormField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                item['quantity'] = int.tryParse(value) ?? 1;
                _updateAmount(item);
              });
            },
          )),
          DataCell(TextFormField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                item['unitCost'] = double.tryParse(value) ?? 0.0;
                _updateAmount(item);
              });
            },
          )),
          DataCell(Text(item['amount'].toStringAsFixed(2))),
        ]);
      }).toList(),
    );
  }

  void _updateAmount(Map<String, dynamic> item) {
    setState(() {
      item['amount'] = item['quantity'] * item['unitCost'];
      _calculateTotalAmount();
    });
  }

  void _calculateTotalAmount() {
    _totalAmount = items.fold(0.0, (sum, item) => sum + item['amount']);
  }

  void _addNewItem() {
    setState(() {
      items.add({'item': '', 'description': '', 'quantity': 1, 'unitCost': 0.0, 'amount': 0.0});
    });
  }

  Future<void> _generateAndSavePdf() async {
    final pdf = pw.Document();
    double totalAmount = 0;

    // Generate the PDF layout
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Quotation', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 10),
              pw.Text('To: ${_recipientController.text}'),
              pw.Text('Date: ${_quotationDate.toString().substring(0, 10)}'),
              pw.SizedBox(height: 10),
              pw.Text('Payment Terms: ${_paymentTermsController.text}'), // Add payment terms
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Item', 'Description', 'Quantity', 'Unit Cost (Ksh)', 'Amount (Ksh)'],
                data: items.map((item) {
                  totalAmount += item['amount'];
                  return [
                    item['item'],
                    item['description'],
                    item['quantity'].toString(),
                    item['unitCost'].toString(),
                    item['amount'].toStringAsFixed(2),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total Amount: Ksh ${totalAmount.toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Text('Signatory: ${_signatoryController.text}'),
            ],
          );
        },
      ),
    );

    // Save the file locally
    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/quotation_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Show a snackbar indicating the file has been saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quotation saved at: ${file.path}')),
    );
  }

  Future<void> _sharePdf() async {
    final output = await getApplicationDocumentsDirectory();
    final filePath = "${output.path}/quotation_${DateTime.now().millisecondsSinceEpoch}.pdf";

    // Generate PDF and save it
    await _generateAndSavePdf();

    // Share the PDF via available platforms (WhatsApp, Gmail, etc.)
    await Share.shareFiles([filePath], text: 'Here is the quotation.');
  }
}

void main() {
  runApp(MaterialApp(home: QuotationScreen()));
}
