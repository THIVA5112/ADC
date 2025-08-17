import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myapp/constants/api_base.dart';

class PatientAppointmentPage extends StatefulWidget {
  const PatientAppointmentPage({super.key});

  @override
  State<PatientAppointmentPage> createState() => _PatientAppointmentPageState();
}

class _PatientAppointmentPageState extends State<PatientAppointmentPage> {
  final TextEditingController searchController = TextEditingController();
  DateTime? selectedDate;
  int? selectedMonth;
  int? selectedYear;
  List<Map<String, dynamic>> searchResults = [];
  bool searching = false;

  // Appointment scheduling
  Map<String, dynamic>? selectedPatient;
  String? selectedTreatment;
  DateTime? appointmentDate;
  TimeOfDay? appointmentTime;
  bool scheduling = false;

  // Treatments for dropdown
  List<String> treatmentOptions = [];

  // View appointments
  DateTime? viewAppointmentsDate;
  List<Map<String, dynamic>> appointmentsForDate = [];

  @override
  void initState() {
    super.initState();
    fetchMasterTreatments();
  }

  Future<void> fetchMasterTreatments() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/treatments'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        treatmentOptions = data.map((t) => t['name'].toString()).toList();
      });
    }
  }

  Future<void> fetchAppointmentsForDate() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(viewAppointmentsDate!);
    final response = await http.get(Uri.parse('$apiBaseUrl/appointments?date=$dateStr'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() => appointmentsForDate = List<Map<String, dynamic>>.from(data));
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No appointments found for this date.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching appointments.')),
      );
    }
  }

  // Filters UI
  Widget _buildFilters() {
    final isSmallScreen = MediaQuery.of(context).size.width < 500;
    if (isSmallScreen) {
      // Use Column for small screens
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(selectedDate == null
                  ? 'Date'
                  : DateFormat('yyyy-MM-dd').format(selectedDate!)),
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
            width: double.infinity,
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
            width: double.infinity,
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  onPressed: () async {
                    await searchPatients(searchController.text);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  onPressed: () {
                    setState(() {
                      selectedDate = null;
                      selectedMonth = null;
                      selectedYear = null;
                      searchController.clear();
                      searchResults.clear();
                      selectedPatient = null;
                      selectedTreatment = null;
                      appointmentDate = null;
                      appointmentTime = null;
                      treatmentOptions = [];
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Use Row for larger screens
      return Row(
        children: [
          SizedBox(
            width: 140,
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(selectedDate == null
                  ? 'Date'
                  : DateFormat('yyyy-MM-dd').format(selectedDate!)),
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
            icon: const Icon(Icons.search),
            label: const Text('Search'),
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
                selectedPatient = null;
                selectedTreatment = null;
                appointmentDate = null;
                appointmentTime = null;
                treatmentOptions = [];
              });
            },
          ),
        ],
      );
    }
  }

  // Search patients
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
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No patients found.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching patients.')),
      );
    }
    setState(() => searching = false);
  }

  // Appointment scheduling UI
  Widget _buildScheduleSection() {
    if (selectedPatient == null) return const SizedBox();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schedule Appointment for ${selectedPatient!['name']} (ID: ${selectedPatient!['patientId']})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
                      TextField(
            decoration: const InputDecoration(
              labelText: 'Treatment Description',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() => selectedTreatment = val);
            },
          ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(appointmentDate == null
                  ? 'Select Date'
                  : DateFormat('yyyy-MM-dd').format(appointmentDate!)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: appointmentDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => appointmentDate = picked);
                }
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.access_time),
              label: Text(appointmentTime == null
                  ? 'Select Time'
                  : appointmentTime!.format(context)),
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: appointmentTime ?? TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() => appointmentTime = picked);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: scheduling
                      ? null
                      : () async {
                          if (selectedTreatment == null ||
                              appointmentDate == null ||
                              appointmentTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Select treatment, date, and time')),
                            );
                            return;
                          }
                          setState(() => scheduling = true);
                          final response = await http.post(
                            Uri.parse('$apiBaseUrl/appointments'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'patientId': selectedPatient!['patientId'],
                              'name': selectedPatient!['name'],
                              'phone': selectedPatient!['phone'],
                              'age': selectedPatient!['age'],
                              'address': selectedPatient!['address'],
                              'appointmentDate': DateFormat('yyyy-MM-dd').format(appointmentDate!),
                              'appointmentTime': appointmentTime!.format(context),
                              'treatment': selectedTreatment,
                            }),
                          );
                          setState(() => scheduling = false);
                          if (response.statusCode == 201) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Appointment scheduled!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${response.body}')),
                            );
                          }
                        },
                  child: const Text('Schedule'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedPatient = null;
                      selectedTreatment = null;
                      appointmentDate = null;
                      appointmentTime = null;
                      treatmentOptions = [];
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // For results table
  Widget _buildResultsTable() {
    if (searchResults.isEmpty) return const SizedBox();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Patient ID')),
              DataColumn(label: Text('Select')), // <-- Move Select here
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
                DataCell(
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedPatient = p;
                        treatmentOptions = treatments.map((t) => t['type']?.toString() ?? '').toSet().toList();
                        selectedTreatment = null;
                        appointmentDate = null;
                        appointmentTime = null;
                      });
                    },
                    child: const Text('Select'),
                  ),
                ),
                DataCell(Text(p['name'] ?? '')),
                DataCell(Text('${p['age'] ?? ''}')),
                DataCell(Text('${p['phone'] ?? ''}')),
                DataCell(Text(p['address'] ?? '')),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: treatments.map((t) => Text(
                    '${t['type'] ?? ''}: ₹${t['estimate'] ?? 0}'
                  )).toList(),
                )),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: payments.map((pay) => Text(
                    '₹${pay['amount'] ?? 0} (${pay['mode'] ?? ''})'
                  )).toList(),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // View appointments filter UI
  Widget _buildViewAppointmentsFilter() {
    final isSmallScreen = MediaQuery.of(context).size.width < 500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'View Appointments by Date',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (isSmallScreen)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(viewAppointmentsDate == null
                      ? 'View Appointments Date'
                      : DateFormat('yyyy-MM-dd').format(viewAppointmentsDate!)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: viewAppointmentsDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => viewAppointmentsDate = picked);
                    }
                  },
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('View Appointments'),
                onPressed: () async {
                  if (viewAppointmentsDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a date to view appointments')),
                    );
                    return;
                  }
                  await fetchAppointmentsForDate();
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                onPressed: () {
                  setState(() {
                    appointmentsForDate.clear();
                    viewAppointmentsDate = null;
                  });
                },
              ),
            ],
          )
        else
          Row(
            children: [
              SizedBox(
                width: 140,
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(viewAppointmentsDate == null
                      ? 'Search by Date'
                      : DateFormat('yyyy-MM-dd').format(viewAppointmentsDate!)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: viewAppointmentsDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => viewAppointmentsDate = picked);
                    }
                  },
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('View Appointments'),
                onPressed: () async {
                  if (viewAppointmentsDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a date to view appointments')),
                    );
                    return;
                  }
                  await fetchAppointmentsForDate();
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                onPressed: () {
                  setState(() {
                    appointmentsForDate.clear();
                    viewAppointmentsDate = null;
                  });
                },
              ),
            ],
          ),
      ],
    );
  }

  // Appointments table
  Widget _buildAppointmentsTable() {
    if (appointmentsForDate.isEmpty) return const SizedBox();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Treatment')),
          DataColumn(label: Text('Time')),
        ],
        rows: appointmentsForDate.map((a) => DataRow(cells: [
          DataCell(Text(a['name'] ?? '')),
          DataCell(Text(a['phone'] ?? '')),
          DataCell(Text(a['treatment'] ?? '')),
          DataCell(Text(a['appointmentTime'] ?? '')),
        ])).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Appointment Scheduler')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilters(),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by Name / Phone / Patient ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => searchPatients(searchController.text),
                ),
                const SizedBox(height: 12),
                _buildResultsTable(),
                _buildScheduleSection(),
                const SizedBox(height: 12),
                _buildViewAppointmentsFilter(),
                const SizedBox(height: 12),
                _buildAppointmentsTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}