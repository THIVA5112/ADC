import 'package:flutter/material.dart';
import 'package:myapp/pages/login_page.dart';
import 'package:myapp/pages/patient_appointment_page.dart';
import 'package:myapp/pages/patient_reg.dart';
import 'package:myapp/pages/patient_form.dart';
import 'package:myapp/pages/patient_search_page.dart';
import 'package:myapp/pages/patient_update_page.dart'; // adjust the path as needed
import 'package:myapp/pages/payment_details.dart';
import 'package:myapp/pages/bill_page.dart';
import 'pages/treatment_update_page.dart';
import 'pages/treatment_history_page.dart';
import 'package:myapp/pages/dashboard_page.dart';
import 'package:myapp/pages/user_maintanence_page.dart';
import 'package:myapp/pages/expense_entry_page.dart'; // Add this import
import 'package:myapp/pages/patientlab_warranty_page.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ADC', // App name for Flutter
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/patientreg': (context) => PatientReg(capabilityLevel: 1, email: ''),
        '/patientform': (context) => PatientFormPage(),
        '/patientsearch': (context) => const PatientSearchPage(),
        '/patientupdate': (context) => const PatientUpdatePage(),
        '/treatmentupdate': (context) => const TreatmentUpdatePage(),
        '/treatmenthistory': (context) => const TreatmentHistoryPage(),
        '/paymentdetails': (context) => const PaymentDetailsPage(),
        '/billpage': (context) => const BillPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/scheduleappointment': (context) => const PatientAppointmentPage(),
        '/user_maintanence_page': (context) => const UserMaintenancePage(),
        '/expense-entry': (context) => const ExpenseEntryPage(), // Add this route
        '/labwarranty': (context) => const PatientLabWarrantyPage(), // <-- Add this line
      },
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 32,
          ),
          const SizedBox(width: 8),
          const Text('ADC'),
        ],
      ),
      // ...other AppBar properties...
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
