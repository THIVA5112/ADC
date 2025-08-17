import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/constants/api_base.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _patient;
  String? _error;
  bool _loading = false;

  Future<void> _fetchPatient(String patientId) async {
    setState(() {
      _loading = true;
      _error = null;
      _patient = null;
    });

    final url = '$apiBaseUrl/patients/$patientId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _patient = data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ?? 'Patient not found.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect to server.\n$e';
        _loading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final patientId = ModalRoute.of(context)?.settings.arguments as int?;
    if (patientId != null) {
      // Use patientId to fetch payment details for this patient
      _fetchPatient(patientId.toString());
    }
  }

  Future<void> searchPatient() async {
    setState(() {
      _loading = true;
      _error = null;
      _patient = null;
    });

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _error = 'Please enter a name, ID, or phone number.';
        _loading = false;
      });
      return;
    }

    final url = '$apiBaseUrl/patients?query=$query'; // <-- Use ?query= not ?search=

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          // If multiple patients found, let user pick one
          if (data.length == 1) {
            setState(() {
              _patient = data[0];
              _loading = false;
            });
          } else {
            final selected = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Select Patient'),
                children: data.map<Widget>((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, p),
                  child: Text('${p['name']} (ID: ${p['patientId']}, Phone: ${p['phone']})'),
                )).toList(),
              ),
            );
            if (selected != null) {
              setState(() {
                _patient = selected;
                _loading = false;
              });
            } else {
              setState(() {
                _loading = false;
              });
            }
          }
        } else {
          setState(() {
            _error = 'No patient found.';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ?? 'Patient not found.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect to server.\n$e';
        _loading = false;
      });
    }
  }

  Future<void> _generateAndDownloadInvoice(String invoiceNo) async {
    if (_patient == null) return;
    final patientId = _patient!['patientId'];
    final url = '$apiBaseUrl/bill/print/$patientId/$invoiceNo';

    if (kIsWeb) {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch PDF URL')),
        );
      }
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/invoice_${patientId}_$invoiceNo.pdf';

        final dio = Dio();
        final response = await dio.download(
          url,
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice downloaded! Opening PDF...')),
          );
          await OpenFile.open(filePath);
          await searchPatient();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download invoice PDF')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildInvoiceTable() {
    final bills = (_patient?['bills'] as List?) ?? [];
    if (bills.isEmpty) {
      return const SizedBox(); // No message shown
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bills.map((bill) {
        final treatments = (bill['treatments'] as List?) ?? [];
        final payments = (bill['payments'] as List?) ?? [];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice No: ${bill['invoiceNo'] ?? bill['billId'] ?? ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Date: ${bill['date'] != null ? bill['date'].toString().substring(0, 10) : ""}'),
                const SizedBox(height: 8),
                const Text('Treatments:', style: TextStyle(decoration: TextDecoration.underline)),
                Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(4),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('Estimate', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...treatments.map<TableRow>((t) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text('${t['type'] ?? ''}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text('${t['description'] ?? ''}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text('INR${t['estimate'] ?? 0}'),
                        ),
                      ],
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Payments:', style: TextStyle(decoration: TextDecoration.underline)),
                Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(2),
                  },
                  children: [
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...payments.map<TableRow>((p) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text('₹${p['amount'] ?? 0}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(p['date'] != null ? p['date'].toString().substring(0, 10) : ''),
                        ),
                      ],
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total Estimate: ₹${bill['totalEstimate'] ?? 0}'),
                Text('Total Paid: ₹${bill['totalPaid'] ?? 0}'),
                Text('Balance: ₹${(bill['totalEstimate'] ?? 0) - (bill['totalPaid'] ?? 0)}'),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download PDF'),
                  onPressed: () {
                    final invoiceNo = bill['invoiceNo'] ?? bill['billId'] ?? "";
                    _generateAndDownloadInvoice(invoiceNo);
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice / Bill')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by Name / ID / Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => searchPatient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : searchPatient,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_patient != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient ID: ${_patient!['patientId'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Name: ${_patient!['name'] ?? ""}'),
                  Text('Phone: ${_patient!['phone'] ?? ""}'),
                  Text('Address: ${_patient!['address'] ?? ""}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final payments = _patient!['payments'] as List? ?? [];
                      if (payments.isNotEmpty) {
                        final latestPayment = payments.last;
                        final invoiceNo = latestPayment['invoiceNo'] ?? latestPayment['paymentId'] ?? "";
                        _generateAndDownloadInvoice(invoiceNo);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No bills found for this patient.')),
                        );
                      }
                    },
                   
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate Invoice (PDF)'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Invoices:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildInvoiceTable(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}