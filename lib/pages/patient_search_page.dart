import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myapp/constants/api_base.dart';

class PatientSearchPage extends StatefulWidget {
  const PatientSearchPage({super.key});

  @override
  State<PatientSearchPage> createState() => _PatientSearchPageState();
}

class _PatientSearchPageState extends State<PatientSearchPage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool searching = false;
  DateTime? selectedDate;
  int? selectedMonth;
  int? selectedYear;

  Future<void> searchPatients(String query) async {
    setState(() => searching = true);
    String url = '$apiBaseUrl/patients?query=$query';
    if (selectedDate != null) {
      url += '&date=${selectedDate!.toIso8601String().substring(0, 10)}';
    } else if (selectedMonth != null && selectedYear != null) {
      url += '&month=$selectedMonth&year=$selectedYear';
    } else if (selectedYear != null) {
      url += '&year=$selectedYear';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() => searchResults = List<Map<String, dynamic>>.from(data));
    }
    setState(() => searching = false);
  }

  Widget _buildFilters() {
    final isSmallScreen = MediaQuery.of(context).size.width < 500;
    if (isSmallScreen) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(selectedDate == null
                  ? 'Filter by Date'
                  : 'Date: ${selectedDate!.toLocal().toString().substring(0, 10)}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    selectedMonth = null;
                    selectedYear = null;
                  });
                }
              },
            ),
          ),
          DropdownButton<int>(
            value: selectedMonth,
            hint: const Text('Month'),
            isExpanded: true,
            items: List.generate(12, (i) => i + 1)
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(DateFormat('MMMM').format(DateTime(2020, m))),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                selectedMonth = val;
                selectedDate = null;
              });
            },
          ),
          DropdownButton<int>(
            value: selectedYear,
            hint: const Text('Year'),
            isExpanded: true,
            items: List.generate(6, (i) => 2020 + i)
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (val) {
              setState(() {
                selectedYear = val;
                selectedDate = null;
              });
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Submit'),
            onPressed: () async {
              await searchPatients(searchController.text);
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            onPressed: () {
              setState(() {
                selectedDate = null;
                selectedMonth = null;
                selectedYear = null;
                searchController.clear();
                searchResults.clear();
              });
            },
          ),
        ],
      );
    } else {
      // Original Row for larger screens
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(selectedDate == null
                  ? 'Filter by Date'
                  : 'Date: ${selectedDate!.toLocal().toString().substring(0, 10)}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    selectedMonth = null;
                    selectedYear = null;
                  });
                }
              },
            ),
          ),
          SizedBox(
            width: 120,
            child: DropdownButton<int>(
              value: selectedMonth,
              hint: const Text('Month'),
              isExpanded: true,
              items: List.generate(12, (i) => i + 1)
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(DateFormat('MMMM').format(DateTime(2020, m))),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedMonth = val;
                  selectedDate = null;
                });
              },
            ),
          ),
          SizedBox(
            width: 90,
            child: DropdownButton<int>(
              value: selectedYear,
              hint: const Text('Year'),
              isExpanded: true,
              items: List.generate(6, (i) => 2020 + i)
                  .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedYear = val;
                  selectedDate = null;
                });
              },
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Submit'),
            onPressed: () async {
              await searchPatients(searchController.text);
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            onPressed: () {
              setState(() {
                selectedDate = null;
                selectedMonth = null;
                selectedYear = null;
                searchController.clear();
                searchResults.clear();
              });
            },
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Search')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search by Name, Phone, or Patient ID',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onFieldSubmitted: (query) async {
                          await searchPatients(query);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                      onPressed: () async {
                        await searchPatients(searchController.text);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (searching) const LinearProgressIndicator(),
                if (searchResults.isNotEmpty)
                  searchResults.length == 1
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4, // Limit height for scroll
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Patient ID')),
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Age')),
                                  DataColumn(label: Text('Phone')),
                                  DataColumn(label: Text('Address')),
                                  DataColumn(label: Text('Treatments')),
                                  DataColumn(label: Text('Payments')),
                                ],
                                rows: searchResults.map((p) {
                                  final treatments = (p['treatments'] as List?) ?? [];
                                  final payments = (p['payments'] as List?) ?? [];
                                  return DataRow(cells: [
                                    DataCell(Text('${p['patientId'] ?? ''}')),
                                    DataCell(Text(p['name'] ?? '')),
                                    DataCell(Text('${p['age'] ?? ''}')),
                                    DataCell(Text('${p['phone'] ?? ''}')),
                                    DataCell(Text(p['address'] ?? '')),
                                    DataCell(
                                      SizedBox(
                                        height: 100,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: treatments.map((t) => Text(
                                              '${t['type'] ?? ''}: ₹${t['estimate'] ?? 0}'
                                            )).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        height: 100,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: payments.map((pay) => Text(
                                              '₹${pay['amount'] ?? 0} (${pay['mode'] ?? ''})'
                                            )).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            const Text(
                              'Multiple patients found. Please select one:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            SizedBox(
                              height: 300, // Limit height to avoid overflow
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final p = searchResults[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                          '${p['name']} (ID: ${p['patientId']})'),
                                      subtitle: Text('Phone: ${p['phone']}'),
                                      onTap: () {
                                        setState(() {
                                          searchResults = [p];
                                          searchController.text = p['name'] ?? '';
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                if (!searching && searchResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No patients found.'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}