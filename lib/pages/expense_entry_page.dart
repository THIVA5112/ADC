import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/constants/api_base.dart';

class ExpenseEntryPage extends StatefulWidget {
  const ExpenseEntryPage({super.key});

  @override
  State<ExpenseEntryPage> createState() => _ExpenseEntryPageState();
}

class _ExpenseEntryPageState extends State<ExpenseEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _expenseType;
  String _paymentMode = 'Cash';
  DateTime? _selectedDate;
  late String _txnId;
  String _branch = 'Trichy Branch'; // default branch

  final List<String> _expenseTypes = [
    'Lab payment',
    'Salary payment',
    'Misc exp',
    'Tea snack exp',
    'Rent',
    'Electricity',
    'Recharge',
    'Fixed assets exp',
    'Pharmacy medicine exp',
    'Dispensary exp',
    'Non dispensary exp',
    'Bio Medical waste exp',
  ];

  final List<String> _branches = ['Trichy Branch', 'Lalgudi Branch'];
  List<Map<String, dynamic>> _expenses = [];

  // Filters
  String? _filterBranch;
  DateTime? _filterDate;
  int? _filterMonth;
  int? _filterYear;

  bool _hasSearched = false; // Track if search has been performed

  @override
  void initState() {
    super.initState();
    _generateTxnId();
    _selectedDate = DateTime.now(); // Set default to today
  }

  void _generateTxnId() {
    final now = DateTime.now();
    final random = Random().nextInt(10000);
    _txnId = 'EXP${now.millisecondsSinceEpoch}$random';
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _descController.clear();
    _amountController.clear();
    setState(() {
      _expenseType = null;
      _paymentMode = 'Cash';
      _selectedDate = null;
      _branch = 'Trichy Branch';
      _generateTxnId();
    });
  }

  Future<void> _submitExpense() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }
    final expense = {
      'txnId': _txnId,
      'branch': _branch,
      'type': _expenseType,
      'description': _descController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim()) ?? 0,
      'paymentMode': _paymentMode,
      'date': _selectedDate!.toLocal().toString().substring(0, 10), // <-- Fix here
    };
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/expenses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(expense),
      );
      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Expense Added'),
            content: Text('Txn ID: ${expense['txnId']}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add expense: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchExpenses() async {
    String url = '$apiBaseUrl/expenses?';
    if (_filterBranch != null) url += 'branch=${Uri.encodeComponent(_filterBranch!)}&';
    if (_filterDate != null) url += 'date=${_filterDate!.toIso8601String().substring(0, 10)}&';
    if (_filterMonth != null) url += 'month=$_filterMonth&';
    if (_filterYear != null) url += 'year=$_filterYear&';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _expenses = List<Map<String, dynamic>>.from(data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch expenses')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildExpensesTable() {
    if (_expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No expenses found.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Branch')),
          DataColumn(label: Text('Txn ID')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Mode')),
        ],
        rows: _expenses.map((e) {
          return DataRow(cells: [
            DataCell(Text(e['date'] != null
                ? e['date'].toString().substring(0, 10)
                : '')),
            DataCell(Text(e['branch'] ?? '')),
            DataCell(Text(e['txnId'] ?? '')),
            DataCell(Text(e['type'] ?? '')),
            DataCell(Text(e['description'] ?? '')),
            DataCell(Text('₹${e['amount'] ?? ''}')),
            DataCell(Text(e['paymentMode'] ?? '')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Branch filter
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              value: _filterBranch,
              decoration: const InputDecoration(
                labelText: 'Branch',
                border: OutlineInputBorder(),
              ),
              items: _branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (val) => setState(() => _filterBranch = val),
              isExpanded: true,
            ),
          ),
          const SizedBox(width: 8),
          // Date filter
          SizedBox(
            width: 120,
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_filterDate == null
                  ? 'Date'
                  : _filterDate!.toLocal().toString().substring(0, 10)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _filterDate = picked);
              },
            ),
          ),
          const SizedBox(width: 8),
          // Month filter
          SizedBox(
            width: 100,
            child: DropdownButtonFormField<int>(
              value: _filterMonth,
              decoration: const InputDecoration(
                labelText: 'Month',
                border: OutlineInputBorder(),
              ),
              items: List.generate(12, (i) => i + 1)
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('${m.toString().padLeft(2, '0')}'),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _filterMonth = val),
              isExpanded: true,
            ),
          ),
          const SizedBox(width: 8),
          // Year filter
          SizedBox(
            width: 100,
            child: DropdownButtonFormField<int>(
              value: _filterYear,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              items: List.generate(6, (i) => DateTime.now().year - i)
                  .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (val) => setState(() => _filterYear = val),
              isExpanded: true,
            ),
          ),
          const SizedBox(width: 8),
          // Search icon
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () async {
              await _fetchExpenses();
              setState(() {
                _hasSearched = true;
              });
            },
          ),
          // Reset button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _filterBranch = null;
                _filterDate = null;
                _filterMonth = null;
                _filterYear = null;
                _expenses = [];      // Clear the table data
                _hasSearched = false; // Hide the table
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Entry')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Txn ID: $_txnId', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _expenseType,
                      decoration: const InputDecoration(
                        labelText: 'Expense Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _expenseTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) => setState(() => _expenseType = val),
                      validator: (val) => val == null ? 'Select expense type' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter amount' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Cash'),
                            leading: Radio<String>(
                              value: 'Cash',
                              groupValue: _paymentMode,
                              onChanged: (val) => setState(() => _paymentMode = val!),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Online'),
                            leading: Radio<String>(
                              value: 'Online',
                              groupValue: _paymentMode,
                              onChanged: (val) => setState(() => _paymentMode = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_selectedDate == null
                          ? 'Select Date'
                          : 'Date: ${_selectedDate!.toLocal().toString().substring(0, 10)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _branch,
                      decoration: const InputDecoration(
                        labelText: 'Branch',
                        border: OutlineInputBorder(),
                      ),
                      items: _branches
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (val) => setState(() => _branch = val!),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitExpense,
                            child: const Text('Add Expense'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetForm,
                            child: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 40),
              _buildExpenseFilters(),
              const SizedBox(height: 16),
              if (_hasSearched) _buildExpensesTable(),
            ],
          ),
        ),
      ),
    );
  }
}