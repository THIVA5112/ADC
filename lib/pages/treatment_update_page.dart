import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/constants/api_base.dart';

class TreatmentUpdatePage extends StatefulWidget {
  const TreatmentUpdatePage({super.key});

  @override
  State<TreatmentUpdatePage> createState() => _TreatmentUpdatePageState();
}

class _TreatmentUpdatePageState extends State<TreatmentUpdatePage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPatient;
  String? _error;
  bool _loading = false;

  // Treatment form controllers
  final TextEditingController _treatmentTypeController = TextEditingController();
  final TextEditingController _treatmentDescController = TextEditingController();
  final TextEditingController _treatmentEstimateController = TextEditingController();

  // Chief Complaints
  final TextEditingController _chiefComplaintsController = TextEditingController();

  // Treatment types
  final List<String> _treatmentTypes = [
    'CONSULTATION',
    'SCANNING AND X-RAYS',
    'ROOT CANAL TREATMENT',
    'CROWNS BRIDGES',
    'IMPLANTS',
    'ALIGNERS',
    'BRACES',
    'FILLING',
    'EXTRACTION',
    'MINOR SURGERY',
    'FULL MOUTH ORAL PROFILE ACCESS',
    'VENEERS',
    'WHITENING AND BLEACHING',
    'DENTURES',
    'CURETTAGE',
    'LASER TREATMENTS',
    'OTHERS'
    
  ];

  // Track selected treatments and their details
  final Map<String, bool> _selectedTreatments = {};
  final Map<String, TextEditingController> _descControllers = {};
  final Map<String, TextEditingController> _estimateControllers = {};

  @override
  void initState() {
    super.initState();
    for (var type in _treatmentTypes) {
      _selectedTreatments[type] = false;
      _descControllers[type] = TextEditingController();
      _estimateControllers[type] = TextEditingController();
    }
  }

 

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

  void _selectPatient(Map<String, dynamic> patient) async {
    // If patientId exists, fetch full details from backend
    if (patient['patientId'] != null) {
      setState(() {
        _loading = true;
        _error = null;
      });
      final response = await http.get(Uri.parse('$apiBaseUrl/patients/${patient['patientId']}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          setState(() {
            _selectedPatient = data;
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'Patient not found.';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Error fetching patient details.';
          _loading = false;
        });
      }
    } else {
      // Fallback: use the patient object directly
      setState(() {
        _selectedPatient = patient;
      });
    }
    // Optionally clear treatment fields
    _treatmentTypeController.clear();
    _treatmentDescController.clear();
    _treatmentEstimateController.clear();
  }

  Future<void> updateTreatment() async {
    if (_selectedPatient == null || _selectedPatient!['patientId'] == null) {
      setState(() {
        _error = 'Please select a patient with a valid Patient ID before updating treatment.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    // Collect selected treatments
    final selectedTreatments = _treatmentTypes.where((type) => _selectedTreatments[type] == true).map((type) {
      return {
        'type': type,
        'description': _descControllers[type]?.text.trim() ?? '',
        'estimate': _estimateControllers[type]?.text.trim().isNotEmpty == true
            ? double.tryParse(_estimateControllers[type]!.text.trim())
            : null,
      };
    }).toList();

    final treatmentData = {
      'chiefComplaints': _chiefComplaintsController.text.trim(),
      'treatments': selectedTreatments,
    };

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/patients/${_selectedPatient!['patientId']}/treatments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(treatmentData),
      );
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Treatment updated successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  final patientId = _selectedPatient?['patientId'];
                  if (patientId != null) {
                    Navigator.pushNamed(
                      context,
                      '/paymentdetails',
                      arguments: patientId,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Patient ID not found!')),
                    );
                  }
                  setState(() {
                    _chiefComplaintsController.clear();
                    for (var type in _treatmentTypes) {
                      _selectedTreatments[type] = false;
                      _descControllers[type]!.clear();
                      _estimateControllers[type]!.clear();
                    }
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
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

  Future<void> addTreatment() async {
    if (_selectedPatient == null || _selectedPatient!['patientId'] == null) {
      setState(() {
        _error = 'Please select a patient with a valid Patient ID before adding treatment.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    // Collect selected treatments
    final selectedTreatments = _treatmentTypes.where((type) => _selectedTreatments[type] == true).map((type) {
      return {
        'type': type,
        'description': _descControllers[type]?.text.trim() ?? '',
        'estimate': _estimateControllers[type]?.text.trim() ?? '',
        'date': DateTime.now().toIso8601String(), // Record the date of this treatment
      };
    }).toList();

    if (selectedTreatments.isEmpty) {
      setState(() {
        _error = 'Please select at least one treatment to add.';
        _loading = false;
      });
      return;
    }

    final treatmentData = {
      'chiefComplaints': _chiefComplaintsController.text.trim(),
      'treatments': selectedTreatments,
    };

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/patients/${_selectedPatient!['patientId']}/add-treatment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(treatmentData),
      );
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Treatment added successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _chiefComplaintsController.clear();
                    for (var type in _treatmentTypes) {
                      _selectedTreatments[type] = false;
                      _descControllers[type]!.clear();
                      _estimateControllers[type]!.clear();
                    }
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ?? 'Add treatment failed.';
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

  void _resetFields() {
    _chiefComplaintsController.clear();
    for (var type in _treatmentTypes) {
      _selectedTreatments[type] = false;
      _descControllers[type]?.clear();
      _estimateControllers[type]?.clear();
    }
    setState(() {});
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final patientId = ModalRoute.of(context)?.settings.arguments;
    if (patientId != null && patientId is int) {
      // Pass int directly to searchByPatientId
      searchByPatientId(patientId);
    }
  }

  void searchByPatientId(dynamic patientId) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedPatient = null;
      _searchResults = [];
    });
    // patientId is int, use directly
    final response = await http.get(Uri.parse('$apiBaseUrl/patients/$patientId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) {
        setState(() {
          _selectedPatient = data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Patient not found.';
          _loading = false;
        });
      }
    } else {
      setState(() {
        _error = 'Error fetching patient details.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Treatment Details')),
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
                  Text('Name: ${_selectedPatient!['name'] ?? ""}'),
                  const SizedBox(height: 8),
                  Text('Phone: ${_selectedPatient!['phone'] ?? ""}'),
                  const SizedBox(height: 16),
                  // Chief Complaints Tab
                  const Text('Chief Complaints:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _chiefComplaintsController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  // Display previous treatments (moved here)
                  if (_selectedPatient!['treatments'] != null && (_selectedPatient!['treatments'] as List).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text('Previous Treatments:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Description')),
                              DataColumn(label: Text('Estimate')),
                            ],
                            rows: (_selectedPatient!['treatments'] as List).map<DataRow>((t) {
                              return DataRow(cells: [
                                DataCell(Text('${t['type'] ?? ''}')),
                                DataCell(Text('${t['description'] ?? ''}')),
                                DataCell(Text('${t['estimate'] ?? ''}')),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Treatments Section
                  const Text('Treatments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._treatmentTypes.map((type) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(type),
                            value: _selectedTreatments[type],
                            onChanged: (val) {
                              setState(() {
                                _selectedTreatments[type] = val ?? false;
                              });
                            },
                          ),
                          if (_selectedTreatments[type] == true) ...[
                            TextField(
                              controller: _descControllers[type],
                              decoration: const InputDecoration(labelText: 'Description'),
                            ),
                            TextField(
                              controller: _estimateControllers[type],
                              decoration: const InputDecoration(labelText: 'Estimate'),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // Add this note above the buttons
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'For Old Patients Use Add treatments, Update Treatments for Editing the Existing Treatments',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _loading ? null : updateTreatment,
                        child: const Text('Update Treatment'),
                      ),
                      ElevatedButton(
                        onPressed: _loading ? null : addTreatment,
                        child: const Text('Add Treatment'),
                      ),
                      OutlinedButton(
                        onPressed: _loading ? null : _resetFields,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}