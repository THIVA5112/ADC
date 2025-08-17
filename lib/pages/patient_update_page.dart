import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/constants/api_base.dart';

class PatientUpdatePage extends StatefulWidget {
  const PatientUpdatePage({super.key});

  @override
  State<PatientUpdatePage> createState() => _PatientUpdatePageState();
}

class _PatientUpdatePageState extends State<PatientUpdatePage> {
  final TextEditingController _searchController = TextEditingController();

  // Form controllers for patient details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _hasComplication = false;

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPatient;
  String? _error;
  bool _loading = false;

  Future<void> _searchPatients() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _selectedPatient = null;
      _searchResults = [];
    });
    final response = await http.get(Uri.parse('$apiBaseUrl/patients?query=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'No patient found.';
          _loading = false;
        });
      }
    } else {
      setState(() {
        _error = 'Error searching patient.';
        _loading = false;
      });
    }
  }

  void _selectPatient(Map<String, dynamic> patient) {
    setState(() {
      _selectedPatient = patient;
      _nameController.text = patient['name'] ?? '';
      _ageController.text = patient['age']?.toString() ?? '';
      _genderController.text = patient['gender'] ?? '';
      _addressController.text = patient['address'] ?? '';
      _hasComplication = patient['hasComplication'] ?? false;
      _descriptionController.text = patient['description'] ?? '';
      _searchResults = [];
    });
  }

  Future<void> updatePatient() async {
    if (_selectedPatient == null || _selectedPatient!['patientId'] == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final updatedData = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'gender': _genderController.text.trim(),
      'address': _addressController.text.trim(),
      'hasComplication': _hasComplication,
      'description': _hasComplication ? _descriptionController.text.trim() : '',
    };

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/patients/patientid/${_selectedPatient!['patientId']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Patient details updated successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          _selectedPatient = null;
          _searchController.clear();
          _nameController.clear();
          _ageController.clear();
          _genderController.clear();
          _addressController.clear();
          _descriptionController.clear();
          _hasComplication = false;
        });
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ?? 'Update failed.';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Patient Details')),
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
                      labelText: 'Search Patient by Name/ID/Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _searchPatients,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_searchResults.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Patient:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._searchResults.map((p) => Card(
                    child: ListTile(
                      title: Text('${p['name']} (ID: ${p['patientId']})'),
                      subtitle: Text('Phone: ${p['phone']}'),
                      onTap: () => _selectPatient(p),
                    ),
                  )),
                ],
              ),
            if (_selectedPatient != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient ID: ${_selectedPatient!['patientId'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _genderController,
                    decoration: const InputDecoration(labelText: 'Gender'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Medical Complication?'),
                    value: _hasComplication,
                    onChanged: (val) => setState(() => _hasComplication = val),
                  ),
                  if (_hasComplication)
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : updatePatient,
                    child: const Text('Update'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}