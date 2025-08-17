import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:myapp/constants/api_base.dart';

class PaymentDetailsPage extends StatefulWidget {
  const PaymentDetailsPage({super.key});

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  DateTime? _selectedDate;
  Map<String, dynamic>? _patient;
  List<dynamic> _treatments = [];
  List<bool> _selectedTreatments = [];
  List<dynamic> _payments = [];
  int _totalEstimate = 0;
  int _totalPaid = 0;

  // Change this to your backend URL
  final String baseUrl = '$apiBaseUrl';

  String _paymentMode = 'Cash'; // Default
  String? _transactionId;

  // Helper to generate a unique 6-digit transaction ID
  String generateTransactionId() {
    final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return random.toString();
  }

  Future<void> _fetchPatient(String query) async {
    setState(() {
      _patient = null;
      _treatments = [];
      _selectedTreatments = [];
      _payments = [];
      _totalEstimate = 0;
      _totalPaid = 0;
    });

    final response = await http.get(Uri.parse('$baseUrl/patients?query=$query'));
    if (response.statusCode == 200) {
      final List patients = json.decode(response.body);
      if (patients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No patient found')),
        );
        return;
      }
      if (patients.length == 1) {
        final patient = patients[0];
        setState(() {
          _patient = patient;
          _treatments = patient['treatments'] ?? [];
          _selectedTreatments = List.filled(_treatments.length, true);
          _payments = patient['payments'] ?? [];
          _totalEstimate = _treatments.fold<int>(0, (sum, t) => sum + (int.tryParse('${t['estimate'] ?? 0}') ?? 0));
          _totalPaid = _payments.fold<int>(0, (sum, p) => sum + (int.tryParse('${p['amount'] ?? 0}') ?? 0));
        });
      } else {
        // Multiple patients found, prompt user to select one
        final selected = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Patient'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final p = patients[index];
                  return ListTile(
                    title: Text('${p['name']} (ID: ${p['patientId']})'),
                    subtitle: Text('Phone: ${p['phone']}'),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ),
        );
        if (selected != null) {
          setState(() {
            _patient = selected;
            _treatments = selected['treatments'] ?? [];
            _selectedTreatments = List.filled(_treatments.length, true);
            _payments = selected['payments'] ?? [];
            _totalEstimate = _treatments.fold<int>(0, (sum, t) => sum + (int.tryParse('${t['estimate'] ?? 0}') ?? 0));
            _totalPaid = _payments.fold<int>(0, (sum, p) => sum + (int.tryParse('${p['amount'] ?? 0}') ?? 0));
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching patient')),
      );
    }
  }

  Future<void> _addPayment() async {
    if (_paymentController.text.isEmpty || _patient == null) return;

    // Add this validation for date
    if (_selectedDate == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Date'),
          content: const Text('Please select a date for the payment.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final amount = int.tryParse(_paymentController.text);
    if (amount == null) return;
    final transactionId = generateTransactionId();
    final response = await http.post(
      Uri.parse('$baseUrl/patients/${_patient!['patientId']}/payments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amount': amount,
        'date': _selectedDate!.toIso8601String(),
        'mode': _paymentMode,
        'transactionId': transactionId,
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        _payments.add({
          'amount': amount,
          'date': _selectedDate!.toIso8601String(),
          'mode': _paymentMode,
          'transactionId': transactionId,
        });
        _totalPaid += amount;
        _paymentController.clear();
        _selectedDate = null;
        _transactionId = transactionId;
      });
      // Navigate to bill page after payment update
      Navigator.pushNamed(
        context,
        '/billpage',
        arguments: _patient!['patientId'],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding payment')),
      );
    }
  }

  Future<void> _printBill() async {
    if (_patient == null) return;
    final url = '$baseUrl/bill/print/${_patient!['patientId']}';
    // For demo: just show the URL. In production, use url_launcher or a download package.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download bill PDF: $url')),
    );
  }

  Future<void> _updateTreatmentEstimate(int treatmentIdx) async {
    final treatment = _treatments[treatmentIdx];
    final controller = TextEditingController(text: treatment['estimate'].toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Estimate Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Estimate Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (result != null && _patient != null) {
      final response = await http.put(
        Uri.parse('$baseUrl/patients/${_patient!['patientId']}/treatments/$treatmentIdx'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'estimate': result}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _treatments[treatmentIdx]['estimate'] = result;
          _totalEstimate = _treatments.fold<int>(0, (sum, t) => sum + ((t['estimate'] ?? 0) as int));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating estimate')));
      }
    }
  }

  Future<void> _updatePaymentAmount(int paymentIdx) async {
    final payment = _payments[paymentIdx];
    final controller = TextEditingController(text: payment['amount'].toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Payment Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Payment Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (result != null && _patient != null) {
      final response = await http.put(
        Uri.parse('$baseUrl/patients/${_patient!['patientId']}/payments/$paymentIdx'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': result}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _totalPaid = _totalPaid - (_payments[paymentIdx]['amount'] as int) + result;
          _payments[paymentIdx]['amount'] = result;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating payment')));
      }
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
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Payment Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Search
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search Patient by Name/ID/Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _fetchPatient(_searchController.text),
                      child: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_patient != null) ...[
                  Card(
                    child: ListTile(
                      title: Text('${_patient!['name']} (${_patient!['age']} yrs, ${_patient!['gender']})'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Address: ${_patient!['address']}'),
                          Text('Phone: ${_patient!['phone']}'),
                          Text('Description: ${_patient!['description']}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Treatments & Estimates:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._treatments.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var t = entry.value;
                    return ListTile(
                      leading: Checkbox(
                        value: _selectedTreatments[idx],
                        onChanged: (val) {
                          setState(() {
                            _selectedTreatments[idx] = val ?? false;
                          });
                        },
                      ),
                      title: Text('${t['type']} - ${t['description']}'),
                      subtitle: Text('Estimate: ₹${t['estimate']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _updateTreatmentEstimate(idx),
                        tooltip: 'Update Estimate',
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text('Add Part Bill Payment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isSmallScreen = constraints.maxWidth < 500;
                      return isSmallScreen
                          ? Column(
                              children: [
                                TextField(
                                  controller: _paymentController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) setState(() => _selectedDate = picked);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(_selectedDate == null
                                        ? 'Select Date'
                                        : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _paymentMode == 'Cash',
                                      onChanged: (val) {
                                        setState(() {
                                          _paymentMode = 'Cash';
                                        });
                                      },
                                    ),
                                    const Text('Cash'),
                                    Checkbox(
                                      value: _paymentMode == 'Online',
                                      onChanged: (val) {
                                        setState(() {
                                          _paymentMode = 'Online';
                                        });
                                      },
                                    ),
                                    const Text('Online'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _addPayment,
                                  child: const Text('Add'),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _paymentController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Amount',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) setState(() => _selectedDate = picked);
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Date',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(_selectedDate == null
                                          ? 'Select Date'
                                          : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _paymentMode == 'Cash',
                                          onChanged: (val) {
                                            setState(() {
                                              _paymentMode = 'Cash';
                                            });
                                          },
                                        ),
                                        const Text('Cash'),
                                        Checkbox(
                                          value: _paymentMode == 'Online',
                                          onChanged: (val) {
                                            setState(() {
                                              _paymentMode = 'Online';
                                            });
                                          },
                                        ),
                                        const Text('Online'),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addPayment,
                                  child: const Text('Add'),
                                ),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Payments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._payments.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var p = entry.value;
                    return ListTile(
                      title: Text('₹${p['amount']} (${p['mode'] ?? 'N/A'})'),
                      subtitle: Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(p['date']))}\n'
                        'Txn ID: ${p['transactionId'] ?? 'N/A'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _updatePaymentAmount(idx),
                        tooltip: 'Update Payment',
                      ),
                    );
                  }),
                  const Divider(),
                  ListTile(
                    title: const Text('Total Estimate'),
                    trailing: Text('₹$_totalEstimate'),
                  ),
                  ListTile(
                    title: const Text('Total Paid'),
                    trailing: Text('₹$_totalPaid'),
                  ),
                  ListTile(
                    title: const Text('Balance'),
                    trailing: Text('₹${_totalEstimate - _totalPaid}'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All payments submitted!')),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Submit'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}