import 'package:flutter/material.dart';

class PatientReg extends StatelessWidget {
  final int capabilityLevel;
  final String email;
  const PatientReg({super.key, required this.capabilityLevel, required this.email});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    String userName = email.split('@')[0]; // Get part before '@'
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Welcome $userName', style: const TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          return GridView.count(
            crossAxisCount: screenWidth < 600 ? 2 : 3, // 2 columns for phones, 3 for tablets/laptops
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _DashboardTile(
                icon: Icons.person_add,
                label: "Register",
                onTap: () {
                  // Navigate to patient registration form
                  Navigator.pushNamed(context, '/patientform');
                },
              ),
              _DashboardTile(
                icon: Icons.edit,
                label: "Update",
                onTap: () {
                  // Navigate to update patient details
                  Navigator.pushNamed(context, '/patientupdate');
                },
              ),
              _DashboardTile(
                icon: Icons.search,
                label: "Search",
                onTap: () {
                  Navigator.pushNamed(context, '/patientsearch');
                },
              ),
              _DashboardTile(
                icon: Icons.medical_services,
                label: "Treatment Details",
                onTap: () {
                  // Navigate to treatment details
                  Navigator.pushNamed(context, '/treatmentupdate');
                },
              ),
              _DashboardTile(
                icon: Icons.history,
                label: "Treatment History",
                onTap: () {
                  // Navigate to patient history
                  Navigator.pushNamed(context, '/treatmenthistory');
                },
              ),
              _DashboardTile(
                icon: Icons.payments,
                label: "Payment Details",
                onTap: () {
                  // Navigate to payment details
                  Navigator.pushNamed(context, '/paymentdetails');
                },
              ),
              _DashboardTile(
                icon: Icons.receipt_long,
                label: "Bill / Invoice",
                onTap: () {
                  // Navigate to bill page
                  Navigator.pushNamed(context, '/billpage');
                },
              ),
              if (capabilityLevel == 2) // Only show for Admin
                _DashboardTile(
                  icon: Icons.dashboard,
                  label: "Dashboard",
                  onTap: () {
                    Navigator.pushNamed(context, '/dashboard');
                  },
                ),
              if (capabilityLevel == 2) // Only show for Admin
                _DashboardTile(
                  icon: Icons.manage_accounts,
                  label: "User Maintenance",
                  onTap: () {
                    Navigator.pushNamed(context, '/user_maintanence_page');
                  },
                ),
              _DashboardTile(
                icon: Icons.schedule_rounded,
                label: "Appointments",
                onTap: () {
                  // Navigate to schedule appointment page
                  Navigator.pushNamed(context, '/scheduleappointment');
                },
              ),
              _DashboardTile(
                icon: Icons.money_rounded,
                label: "Expense Entry",
                onTap: () {
                  Navigator.pushNamed(context, '/expense-entry');
                },
              ),
               _DashboardTile(
                icon: Icons.verified,
                label: "Warranty Details",
                onTap: () {
                  Navigator.pushNamed(context, '/labwarranty');
                },
              ),
            
              
            ],
          );
        },
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color.fromARGB(255, 255, 64, 175),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 8, 8, 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
