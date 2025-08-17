import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/constants/api_base.dart';

class WarrantySearchPage extends StatefulWidget {
  const WarrantySearchPage({super.key});

  @override
  State<WarrantySearchPage> createState() => _WarrantySearchPageState();
}

class _WarrantySearchPageState extends State<WarrantySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Future<void> _searchWarranty() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    final response = await http.get(Uri.parse('$apiBaseUrl/lab-warranty/search?query=$query'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _results = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } else {
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Warranty')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Name / Phone / Patient ID / Warranty ID',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchWarranty(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchWarranty,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading && _results.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Warranty ID')),
                      DataColumn(label: Text('Patient Name')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Patient ID')),
                      DataColumn(label: Text('Address')),
                      DataColumn(label: Text('Branch')),
                      DataColumn(label: Text('Treatment')),
                      DataColumn(label: Text('Material')),
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Lab Name')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Warranty Years')),
                    ],
                    rows: _results.map((w) => DataRow(cells: [
                      DataCell(Text(w['warrantyId'] ?? '')),
                      DataCell(Text(w['patientName'] ?? '')),
                      DataCell(Text(w['patientPhone'] != null ? w['patientPhone'].toString() : '')), // Ensure number as string
                      DataCell(Text(w['patientId'] != null ? w['patientId'].toString() : '')),       // Ensure number as string
                      DataCell(Text(w['address'] ?? '')),
                      DataCell(Text(w['branch'] ?? '')),
                      DataCell(Text(w['treatmentType'] ?? '')),
                      DataCell(Text(w['material'] ?? '')),
                      DataCell(Text(w['product'] ?? '')),
                      DataCell(Text(w['labName'] ?? '')),
                      DataCell(Text(w['date'] ?? '')),
                      DataCell(Text(w['warrantyYears'] != null ? w['warrantyYears'].toString() : '')), // Ensure number as string
                    ])).toList(),
                  ),
                ),
              ),
            if (!_loading && _results.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Text('No warranty found.'),
              ),
          ],
        ),
      ),
    );
  }
}