import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/constants/api_base.dart';

class PatientFormPage extends StatefulWidget {
  const PatientFormPage({super.key});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _gender;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _hasComplication = false;
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedBranch;
  final List<String> _branches = ['Lalgudi Branch', 'Trichy Branch'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Registration')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Age is required';
                  final age = int.tryParse(value);
                  if (age == null || age <= 0) return 'Enter a valid age';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) => setState(() => _gender = value),
                validator: (value) => value == null ? 'Gender is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Phone number is required';
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Enter a valid 10-digit phone number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                decoration: const InputDecoration(
                  labelText: 'Branch',
                  border: OutlineInputBorder(),
                ),
                items: _branches
                    .map((branch) => DropdownMenuItem(
                          value: branch,
                          child: Text(branch),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedBranch = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Medical Complication?'),
                value: _hasComplication,
                onChanged: (val) => setState(() => _hasComplication = val),
              ),
              if (_hasComplication)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) {
                    if (_hasComplication && (value == null || value.trim().isEmpty)) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final patientData = {
                      'name': _nameController.text.trim(),
                      'age': int.parse(_ageController.text.trim()),
                      'gender': _gender,
                      'address': _addressController.text.trim(),
                      'phone': int.parse(_phoneController.text.trim()), // <-- changed here
                      'hasComplication': _hasComplication,
                      'description': _hasComplication ? _descriptionController.text.trim() : '',
                      'branch': _selectedBranch,
                    };

                    try {
                      final response = await http.post(
                        Uri.parse('$apiBaseUrl/patients'), // Use your PC IP if on device
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(patientData),
                      );

                      if (response.statusCode == 201) {
                        // Success, decode as JSON if needed
                        final responseData = jsonDecode(response.body);
                        final patientId = responseData['patientId']; // Should be int
                        _showPatientIdAndNavigate(context, patientId);
                      } else {
                        // Print the response for debugging
                        print('Status: ${response.statusCode}');
                        print('Body: ${response.body}');
                        String msg;
                        try {
                          msg = jsonDecode(response.body)['message'] ?? 'Registration failed';
                        } catch (e) {
                          msg = 'Registration failed. Server response: ${response.body}';
                        }
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Error'),
                            content: Text(msg),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: Text('Failed to connect to server.\n$e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // After successful registration and receiving patientId from backend:
  void _showPatientIdAndNavigate(BuildContext context, int patientId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Text('Patient ID: $patientId'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamed(
                context,
                '/treatmentupdate',
                arguments: patientId, // Pass as int
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}