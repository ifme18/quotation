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
  final _paymentTermsController = TextEditingController();

  List<Map<String, dynamic>> items = [
    {'item': '', 'description': '', 'quantity': 1, 'unitCost': 0.0, 'amount': 0.0},
  ];

  DateTime _quotationDate = DateTime.now();
  double _totalAmount = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Quotation',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[100],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        color: Colors.blueGrey[50],
        child: SingleChildScrollView(
          child: Column(
            children: [
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
              Divider(color: Colors.grey[400]),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDataTable(),
              ),
              Divider(color: Colors.grey[400]),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: Ksh ${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addNewItem,
                child: Text('Add New Item'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.teal[400],
                ),
              ),
              SizedBox(height: 10),
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
              ElevatedButton(
                onPressed: _generateAndSavePdf,
                child: Text('Save Quotation Locally'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.teal[400],
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
                  backgroundColor: Colors.teal[400],
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

  Future<String> _generateAndSavePdf() async {
    final pdf = pw.Document();
    double totalAmount = 0;

    // Generate the PDF layout
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Letterhead
              _buildLetterHead(),
              pw.SizedBox(height: 10),
              pw.Text('To: ${_recipientController.text}'),
              pw.Text('Date: ${_quotationDate.toString().substring(0, 10)}'),
              pw.SizedBox(height: 10),
              pw.Text('Payment Terms: ${_paymentTermsController.text}'),
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
              pw.SizedBox(height: 20),
              _buildFooter(), // Footer section
            ],
          );
        },
      ),
    );

    // Save the file locally
    final output = await getApplicationDocumentsDirectory();
    final filePath = "${output.path}/quotation_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  // Letterhead section
  pw.Widget _buildLetterHead() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'GEOPLAN KENYA LTD',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('Kigio Plaza - Thika, 1st floor, No. K.1.16'),
        pw.Text('Uniafric House - Nairobi, 4th floor, No. 458'),
        pw.Text('P.O Box 522 - 00100 Thika'),
        pw.Text('Tel: +254 721 256 135 / +254 724 404 133'),
        pw.Text('Email: geoplankenya1@gmail.com, info@geoplankenya.co.ke'),
        pw.Text('www.geoplankenya.co.ke'),
      ],
    );
  }

  // Footer section
  pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.Text(
          'GEOPLAN KENYA LTD - Registered Land & Engineering Surveyors, Planning & Land Consultants',
          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
        ),
      ],
    );
  }

  Future<void> _sharePdf() async {
    final filePath = await _generateAndSavePdf();
    await Share.shareFiles([filePath], text: 'Here is the quotation.');
  }
}

void main() {
  runApp(MaterialApp(home: QuotationScreen()));
}


