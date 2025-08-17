import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/constants/api_base.dart';
import 'package:myapp/pages/warranty_search_page.dart';

class PatientLabWarrantyPage extends StatefulWidget {
  const PatientLabWarrantyPage({super.key});

  @override
  State<PatientLabWarrantyPage> createState() => _PatientLabWarrantyPageState();
}

class _PatientLabWarrantyPageState extends State<PatientLabWarrantyPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _labNameController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  Map<String, dynamic>? selectedPatient;
  Map<String, dynamic>? selectedTreatment;
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> treatments = [];

  String warrantyId = '';

  int? _warrantyYears;

  void _generateWarrantyId() {
    final random = Random();
    final id = 'ADC${DateTime.now().millisecondsSinceEpoch}${random.nextInt(1000)}';
    setState(() {
      warrantyId = id;
    });
  }

  Future<void> _searchPatient() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final response = await http.get(Uri.parse('$apiBaseUrl/patients?query=$query'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        searchResults = List<Map<String, dynamic>>.from(data);
        selectedPatient = null;
        treatments = [];
        selectedTreatment = null;
      });
    } else {
      setState(() {
        searchResults = [];
        selectedPatient = null;
        treatments = [];
        selectedTreatment = null;
      });
    }
  }

  Future<void> _fetchTreatments(dynamic patientId) async {
    final response = await http.get(Uri.parse('$apiBaseUrl/patients/$patientId/treatment-types'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        treatments = List<Map<String, dynamic>>.from(data);
        selectedTreatment = null;
      });
    } else {
      setState(() {
        treatments = [];
        selectedTreatment = null;
      });
    }
  }

  Future<void> _resetForm() async {
    setState(() {
      _materialController.clear();
      _productController.clear();
      _labNameController.clear();
      _selectedDate = DateTime.now();
      warrantyId = '';
      selectedPatient = null;
      selectedTreatment = null;
      treatments = [];
      searchResults = [];
      _searchController.clear();
    });
  }

  Future<void> _saveWarranty() async {
    if (selectedPatient == null ||
        selectedTreatment == null ||
        _materialController.text.isEmpty ||
        _productController.text.isEmpty ||
        _labNameController.text.isEmpty ||
        _selectedDate == null ||
        _warrantyYears == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    _generateWarrantyId();
    final warrantyData = {
      'warrantyId': warrantyId,
      'patientId': selectedPatient!['patientId'],
      'patientName': selectedPatient!['name'],
      'patientPhone': selectedPatient!['phone'],
      'patientAddress': selectedPatient!['address'],
      'treatmentType': selectedTreatment!['type'],
      'material': _materialController.text.trim(),
      'product': _productController.text.trim(),
      'labName': _labNameController.text.trim(),
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'warrantyYears': _warrantyYears, // <-- Add this line
    };
    final response = await http.post(
      Uri.parse('$apiBaseUrl/lab-warranty'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(warrantyData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Warranty Saved'),
          content: Text('Warranty saved successfully!\nWarranty ID: $warrantyId'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save warranty')));
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Lab Warranty')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Add this tile ---
              ListTile(
                tileColor: const Color.fromARGB(255, 242, 145, 226),
                leading: const Icon(Icons.search),
                title: const Text('Search Warranty'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WarrantySearchPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Search
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search by Name / Phone / Patient ID',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _searchPatient(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _searchPatient,
                    child: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Patient selection
              if (searchResults.isNotEmpty)
                DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  value: selectedPatient,
                  hint: const Text('Select Patient'),
                  items: searchResults.map((patient) {
                    return DropdownMenuItem(
                      value: patient,
                      child: Text('${patient['name']} (${patient['patientId'] ?? patient['_id']})'),
                    );
                  }).toList(),
                  onChanged: (val) async {
                    setState(() {
                      selectedPatient = val;
                      treatments = [];
                      selectedTreatment = null;
                    });
                    if (val != null && val['patientId'] != null) {
                      await _fetchTreatments(val['patientId']);
                    }
                  },
                ),
              const SizedBox(height: 16),
              // Treatment selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Treatment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<Map<String, dynamic>>(
                    isExpanded: true,
                    value: selectedTreatment,
                    hint: const Text('Select Treatment'),
                    items: treatments.map((treat) {
                      return DropdownMenuItem(
                        value: treat,
                        child: Text('${treat['type']}'),
                      );
                    }).toList(),
                    onChanged: treatments.isEmpty
                        ? null
                        : (val) {
                            setState(() {
                              selectedTreatment = val;
                            });
                          },
                  ),
                  if (treatments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'No treatments found for this patient.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Warranty ID
              if (warrantyId.isNotEmpty)
                Text('Warranty ID: $warrantyId', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Material
              TextField(
                controller: _materialController,
                decoration: const InputDecoration(
                  labelText: 'Material Details',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Product
              TextField(
                controller: _productController,
                decoration: const InputDecoration(
                  labelText: 'Product Details',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Lab Name
              TextField(
                controller: _labNameController,
                decoration: const InputDecoration(
                  labelText: 'Lab Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Date
              Row(
                children: [
                  const Text('Date:'),
                  const SizedBox(width: 8),
                  Text(_selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : ''),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Warranty Years
              DropdownButtonFormField<int>(
                value: _warrantyYears,
                decoration: const InputDecoration(
                  labelText: 'Warranty Years',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(10, (i) => i + 1)
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text('$year'),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _warrantyYears = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _saveWarranty,
                    child: const Text('Save Warranty'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _resetForm,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 247, 241, 241)),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}