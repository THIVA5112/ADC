import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/constants/api_base.dart';

class TreatmentHistoryPage extends StatefulWidget {
  const TreatmentHistoryPage({super.key});

  @override
  State<TreatmentHistoryPage> createState() => _TreatmentHistoryPageState();
}

class _TreatmentHistoryPageState extends State<TreatmentHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPatient;
  String? _error;
  bool _loading = false;

  Future<void> _searchPatient() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _searchResults = [];
      _selectedPatient = null;
    });
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/patients?query=$query'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'No patients found.';
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

  Widget _buildTreatmentHistory() {
    final treatments = _selectedPatient?['treatments'] as List<dynamic>?;

    if (treatments == null || treatments.isEmpty) {
      return const Text('No treatment history found.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: treatments.length,
      itemBuilder: (context, index) {
        final treatment = treatments[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text('Type: ${treatment['type'] ?? "N/A"}'),
            subtitle: Text('Description: ${treatment['description'] ?? "No details"}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treatment History')),
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
                      labelText: 'Search by Name / Phone / Patient ID',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchPatient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _searchPatient,
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
                  DropdownButton<Map<String, dynamic>>(
                    isExpanded: true,
                    value: _selectedPatient,
                    hint: const Text('Select Patient'),
                    items: _searchResults.map((patient) {
                      return DropdownMenuItem(
                        value: patient,
                        child: Text('${patient['name']} (${patient['patientId']})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPatient = val;
                        print(_selectedPatient);
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (_selectedPatient != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient ID: ${_selectedPatient!['patientId'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Name: ${_selectedPatient!['name'] ?? ""}',style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Phone Number: ${_selectedPatient!['phone'] ?? ""}',style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Address: ${_selectedPatient!['address'] ?? ""}'),
                  
                  const SizedBox(height: 16),
                  const Text('Treatment History:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Chief Complaints: ${_selectedPatient!['chiefComplaints'] ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Medical Complication: ${_selectedPatient!['hasComplication'] == true ? "Yes" : "No"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_selectedPatient!['hasComplication'] == true)
                    Text('Complication Details: ${_selectedPatient!['description'] ?? ""}', style: const TextStyle(color: Colors.red)),
                  _buildTreatmentHistory(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}