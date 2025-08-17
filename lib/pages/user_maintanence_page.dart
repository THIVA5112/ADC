import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/constants/api_base.dart';

class UserMaintenancePage extends StatefulWidget {
  const UserMaintenancePage({super.key});

  @override
  State<UserMaintenancePage> createState() => _UserMaintenancePageState();
}

class _UserMaintenancePageState extends State<UserMaintenancePage> {
  List<Map<String, dynamic>> users = [];
  bool loading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  int capabilityLevel = 1; // 1: User, 2: Admin, 3: Manager
  String? editingUserId;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    final response = await http.get(Uri.parse('$apiBaseUrl/users'));
    if (response.statusCode == 200) {
      setState(() {
        users = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    }
    setState(() => loading = false);
  }

  Future<void> addUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    final body = jsonEncode({
      'email': email,
      'password': password,
      'capabilityLevel': capabilityLevel, // This is an int
    });

    final response = await http.post(
      Uri.parse('$apiBaseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added')),
      );
      fetchUsers();
      emailController.clear();
      passwordController.clear();
      capabilityLevel = 1;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await http.delete(Uri.parse('$apiBaseUrl/users/$id'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted')),
      );
      fetchUsers();
    }
  }

  Future<void> updateUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty) return;

    final body = jsonEncode({
      'email': email,
      'capabilityLevel': capabilityLevel,
      if (password.isNotEmpty) 'password': password,
    });

    final response = await http.put(
      Uri.parse('$apiBaseUrl/users/$editingUserId'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated')),
      );
      fetchUsers();
      setState(() {
        editingUserId = null;
        emailController.clear();
        passwordController.clear();
        capabilityLevel = 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  String getCapabilityLabel(int level) {
    switch (level) {
      case 2: return 'Admin';
      case 3: return 'Doctor';
      default: return 'Attender';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Maintenance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Add user form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Mail ID'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: capabilityLevel,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Attender')),
                        DropdownMenuItem(value: 2, child: Text('Admin')),
                        DropdownMenuItem(value: 3, child: Text('Doctor')),
                      ],
                      onChanged: (val) {
                        setState(() => capabilityLevel = val ?? 1);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: editingUserId == null ? addUser : updateUser,
                          child: Text(editingUserId == null ? 'Add User' : 'Update User'),
                        ),
                        if (editingUserId != null)
                          const SizedBox(width: 12),
                        if (editingUserId != null)
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                editingUserId = null;
                                emailController.clear();
                                passwordController.clear();
                                capabilityLevel = 1;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // User list
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: users.map((user) {
                        return Card(
                          child: ListTile(
                            title: Text(user['email'] ?? ''),
                            subtitle: Text('Capability: ${getCapabilityLabel(user['capabilityLevel'] ?? 1)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      editingUserId = user['_id'];
                                      emailController.text = user['email'] ?? '';
                                      passwordController.clear();
                                      capabilityLevel = user['capabilityLevel'] ?? 1;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deleteUser(user['_id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}