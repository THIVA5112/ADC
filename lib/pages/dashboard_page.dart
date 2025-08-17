import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:myapp/constants/api_base.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Filters
  String regFilterType = 'date';
  DateTime regSelectedDate = DateTime.now();
  int? regSelectedMonth;
  int? regSelectedYear;

  String paidFilterType = 'date';
  DateTime paidSelectedDate = DateTime.now();
  int? paidSelectedMonth;
  int? paidSelectedYear;

  String modeFilterType = 'date';
  DateTime modeSelectedDate = DateTime.now();
  int? modeSelectedMonth;
  int? modeSelectedYear;

  String expenseFilterType = 'date';
  DateTime expenseSelectedDate = DateTime.now();
  int? expenseSelectedMonth;
  int? expenseSelectedYear;

  // Revenue vs Expense
  String revExpFilterType = 'date';
  DateTime revExpSelectedDate = DateTime.now();
  int? revExpSelectedMonth;
  int? revExpSelectedYear;

  // Data
  int registrations = 0;
  double totalPaid = 0;
  double totalEstimate = 0;
  double pipeline = 0;
  double modeCashTotal = 0;
  double modeOnlineTotal = 0;
  bool _loading = true;

  // Branch selection
  String? selectedBranch = 'All Branches';
  final List<String> branches = ['All Branches', 'Lalgudi Branch', 'Trichy Branch'];

  // Expense summary data
  Map<String, double> expenseTypeSummary = {};
  bool _expenseLoading = false;

  // Revenue vs Expense data
  double revenueTotal = 0;
  double expenseTotal = 0;
  double profitTotal = 0;
  bool _revExpLoading = false;

  // Profit/Revenue Growth
  int growthSelectedYear = DateTime.now().year;
  List<Map<String, dynamic>> growthData = [];
  bool _growthLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAllData();
    fetchExpenseTypeSummary();
    fetchRevenueExpenseData(); // Add this
  }

  Future<void> fetchAllData() async {
    setState(() => _loading = true);
    await Future.wait([
      fetchRegistrationsData(),
      fetchPaidPipelineData(),
      fetchModeData(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> fetchRegistrationsData() async {
    String url = '$apiBaseUrl/dashboard-summary?';
    if (regFilterType == 'date') {
      url += 'date=${DateFormat('yyyy-MM-dd').format(regSelectedDate)}';
    } else if (regFilterType == 'month' && regSelectedMonth != null && regSelectedYear != null) {
      url += 'month=$regSelectedMonth&year=$regSelectedYear';
    } else if (regFilterType == 'year' && regSelectedYear != null) {
      url += 'year=$regSelectedYear';
    }
    if (selectedBranch != null && selectedBranch != 'All Branches') {
      url += '&branch=${Uri.encodeComponent(selectedBranch!)}';
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          registrations = (data['registrations'] ?? 0) is int
              ? data['registrations']
              : int.tryParse('${data['registrations'] ?? 0}') ?? 0;
        });
      } else {
        setState(() => registrations = 0);
      }
    } catch (e) {
      setState(() => registrations = 0);
    }
  }

  Future<void> fetchPaidPipelineData() async {
    String url = '$apiBaseUrl/dashboard-summary?';
    if (paidFilterType == 'date') {
      url += 'date=${DateFormat('yyyy-MM-dd').format(paidSelectedDate)}';
    } else if (paidFilterType == 'month' && paidSelectedMonth != null && paidSelectedYear != null) {
      url += 'month=$paidSelectedMonth&year=$paidSelectedYear';
    } else if (paidFilterType == 'year' && paidSelectedYear != null) {
      url += 'year=$paidSelectedYear';
    }
    if (selectedBranch != null && selectedBranch != 'All Branches') {
      url += '&branch=${Uri.encodeComponent(selectedBranch!)}';
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalPaid = (data['totalPaid'] ?? 0) is num
              ? (data['totalPaid'] ?? 0).toDouble()
              : double.tryParse('${data['totalPaid'] ?? 0}') ?? 0;
          totalEstimate = (data['totalEstimate'] ?? 0) is num
              ? (data['totalEstimate'] ?? 0).toDouble()
              : double.tryParse('${data['totalEstimate'] ?? 0}') ?? 0;
          pipeline = (data['pipeline'] ?? totalEstimate) is num
              ? (data['pipeline'] ?? totalEstimate).toDouble()
              : double.tryParse('${data['pipeline'] ?? totalEstimate}') ?? 0;
        });
      } else {
        setState(() {
          totalPaid = 0;
          totalEstimate = 0;
          pipeline = 0;
        });
      }
    } catch (e) {
      setState(() {
        totalPaid = 0;
        totalEstimate = 0;
        pipeline = 0;
      });
    }
  }

  Future<void> fetchModeData() async {
    String url = '$apiBaseUrl/dashboard-summary?';
    if (modeFilterType == 'date') {
      url += 'date=${DateFormat('yyyy-MM-dd').format(modeSelectedDate)}';
    } else if (modeFilterType == 'month' && modeSelectedMonth != null && modeSelectedYear != null) {
      url += 'month=$modeSelectedMonth&year=$modeSelectedYear';
    } else if (modeFilterType == 'year' && modeSelectedYear != null) {
      url += 'year=$modeSelectedYear';
    }
    if (selectedBranch != null && selectedBranch != 'All Branches') {
      url += '&branch=${Uri.encodeComponent(selectedBranch!)}';
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          modeCashTotal = (data['cashTotal'] ?? 0) is num
              ? (data['cashTotal'] ?? 0).toDouble()
              : double.tryParse('${data['cashTotal'] ?? 0}') ?? 0;
          modeOnlineTotal = (data['onlineTotal'] ?? 0) is num
              ? (data['onlineTotal'] ?? 0).toDouble()
              : double.tryParse('${data['onlineTotal'] ?? 0}') ?? 0;
        });
      } else {
        setState(() {
          modeCashTotal = 0;
          modeOnlineTotal = 0;
        });
      }
    } catch (e) {
      setState(() {
        modeCashTotal = 0;
        modeOnlineTotal = 0;
      });
    }
  }

  Future<void> fetchExpenseTypeSummary() async {
    setState(() => _expenseLoading = true);
    String url = '$apiBaseUrl/expense-summary?';
    if (expenseFilterType == 'date') {
      url += 'date=${DateFormat('yyyy-MM-dd').format(expenseSelectedDate)}';
    } else if (expenseFilterType == 'month' && expenseSelectedMonth != null && expenseSelectedYear != null) {
      url += 'month=$expenseSelectedMonth&year=$expenseSelectedYear';
    } else if (expenseFilterType == 'year' && expenseSelectedYear != null) {
      url += 'year=$expenseSelectedYear';
    }
    if (selectedBranch != null && selectedBranch != 'All Branches') {
      url += '&branch=${Uri.encodeComponent(selectedBranch!)}';
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          expenseTypeSummary = Map<String, double>.from(
            (data as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
          );
        });
      } else {
        setState(() => expenseTypeSummary = {});
      }
    } catch (e) {
      setState(() => expenseTypeSummary = {});
    }
    setState(() => _expenseLoading = false);
  }

  Future<void> fetchRevenueExpenseData() async {
    setState(() => _revExpLoading = true);
    String url = '$apiBaseUrl/revenue-expense-summary?';
    if (revExpFilterType == 'date') {
      url += 'date=${DateFormat('yyyy-MM-dd').format(revExpSelectedDate)}';
    } else if (revExpFilterType == 'month' && revExpSelectedMonth != null && revExpSelectedYear != null) {
      url += 'month=$revExpSelectedMonth&year=$revExpSelectedYear';
    } else if (revExpFilterType == 'year' && revExpSelectedYear != null) {
      url += 'year=$revExpSelectedYear';
    }
    if (selectedBranch != null && selectedBranch != 'All Branches') {
      url += '&branch=${Uri.encodeComponent(selectedBranch!)}';
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          revenueTotal = (data['revenue'] ?? 0) is num
              ? (data['revenue'] ?? 0).toDouble()
              : double.tryParse('${data['revenue'] ?? 0}') ?? 0;
          expenseTotal = (data['expense'] ?? 0) is num
              ? (data['expense'] ?? 0).toDouble()
              : double.tryParse('${data['expense'] ?? 0}') ?? 0;
          profitTotal = revenueTotal - expenseTotal;
        });
      } else {
        setState(() {
          revenueTotal = 0;
          expenseTotal = 0;
          profitTotal = 0;
        });
      }
    } catch (e) {
      setState(() {
        revenueTotal = 0;
        expenseTotal = 0;
        profitTotal = 0;
      });
    }
    setState(() => _revExpLoading = false);
  }

  Future<void> fetchGrowthData() async {
    setState(() => _growthLoading = true);
    String url = '$apiBaseUrl/profit-revenue-growth?year=$growthSelectedYear';
    if (selectedBranch != null && selectedBranch != 'All Branches') {
      url += '&branch=${Uri.encodeComponent(selectedBranch!)}';
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          growthData = List<Map<String, dynamic>>.from(data);
        });
      } else {
        setState(() => growthData = []);
      }
    } catch (e) {
      setState(() => growthData = []);
    }
    setState(() => _growthLoading = false);
  }

  Widget buildFilterControls({
    required String filterType,
    required DateTime selectedDate,
    required int? selectedMonth,
    required int? selectedYear,
    required Function(String) onTypeChanged,
    required Function(DateTime) onDateChanged,
    required Function(int) onMonthChanged,
    required Function(int) onYearChanged,
    required VoidCallback onSearch,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    if (isSmallScreen) {
      // Use Wrap for small screens
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          DropdownButton<String>(
            value: filterType,
            items: const [
              DropdownMenuItem(value: 'date', child: Text('Date')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (val) => onTypeChanged(val!),
          ),
          if (filterType == 'date')
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) onDateChanged(picked);
              },
              child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
            ),
          if (filterType == 'month')
            DropdownButton<int>(
              value: selectedMonth,
              hint: const Text('Month'),
              items: List.generate(12, (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(DateFormat.MMMM().format(DateTime(0, i + 1))),
              )),
              onChanged: (val) => onMonthChanged(val!),
            ),
          if (filterType == 'month')
            DropdownButton<int>(
              value: selectedYear,
              hint: const Text('Year'),
              items: List.generate(6, (i) {
                int year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => onYearChanged(val!),
            ),
          if (filterType == 'year')
            DropdownButton<int>(
              value: selectedYear,
              hint: const Text('Year'),
              items: List.generate(6, (i) {
                int year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => onYearChanged(val!),
            ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      );
    } else {
      // Use Row for larger screens
      return Row(
        children: [
          DropdownButton<String>(
            value: filterType,
            items: const [
              DropdownMenuItem(value: 'date', child: Text('Date')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (val) => onTypeChanged(val!),
          ),
          const SizedBox(width: 8),
          if (filterType == 'date')
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) onDateChanged(picked);
              },
              child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
            ),
          if (filterType == 'month')
            Row(
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  hint: const Text('Month'),
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(DateFormat.MMMM().format(DateTime(0, i + 1))),
                  )),
                  onChanged: (val) => onMonthChanged(val!),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: selectedYear,
                  hint: const Text('Year'),
                  items: List.generate(6, (i) {
                    int year = DateTime.now().year - i;
                    return DropdownMenuItem(value: year, child: Text('$year'));
                  }),
                  onChanged: (val) => onYearChanged(val!),
                ),
              ],
            ),
          if (filterType == 'year')
            DropdownButton<int>(
              value: selectedYear,
              hint: const Text('Year'),
              items: List.generate(6, (i) {
                int year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => onYearChanged(val!),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      );
    }
  }

  Widget buildModeFilterControls() {
    return buildFilterControls(
      filterType: modeFilterType,
      selectedDate: modeSelectedDate,
      selectedMonth: modeSelectedMonth,
      selectedYear: modeSelectedYear,
      onTypeChanged: (val) {
        setState(() {
          modeFilterType = val;
          modeSelectedMonth = null;
          modeSelectedYear = null;
        });
      },
      onDateChanged: (date) {
        setState(() => modeSelectedDate = date);
      },
      onMonthChanged: (month) {
        setState(() => modeSelectedMonth = month);
      },
      onYearChanged: (year) {
        setState(() => modeSelectedYear = year);
      },
      onSearch: fetchModeData,
    );
  }

  Widget buildExpenseFilterControls() {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    if (isSmallScreen) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          DropdownButton<String>(
            value: expenseFilterType,
            items: const [
              DropdownMenuItem(value: 'date', child: Text('Date')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (val) => setState(() {
              expenseFilterType = val!;
              expenseSelectedMonth = null;
              expenseSelectedYear = null;
            }),
          ),
          if (expenseFilterType == 'date')
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: expenseSelectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => expenseSelectedDate = picked);
              },
              child: Text(DateFormat('yyyy-MM-dd').format(expenseSelectedDate)),
            ),
          if (expenseFilterType == 'month')
            DropdownButton<int>(
              value: expenseSelectedMonth,
              hint: const Text('Month'),
              items: List.generate(12, (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(DateFormat.MMMM().format(DateTime(0, i + 1))),
              )),
              onChanged: (val) => setState(() => expenseSelectedMonth = val),
            ),
          if (expenseFilterType == 'month')
            DropdownButton<int>(
              value: expenseSelectedYear,
              hint: const Text('Year'),
              items: List.generate(6, (i) {
                int year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => setState(() => expenseSelectedYear = val),
            ),
          if (expenseFilterType == 'year')
            DropdownButton<int>(
              value: expenseSelectedYear,
              hint: const Text('Year'),
              items: List.generate(6, (i) {
                int year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => setState(() => expenseSelectedYear = val),
            ),
          IconButton(
            onPressed: fetchExpenseTypeSummary,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      );
    } else {
      return Row(
        children: [
          DropdownButton<String>(
            value: expenseFilterType,
            items: const [
              DropdownMenuItem(value: 'date', child: Text('Date')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (val) => setState(() {
              expenseFilterType = val!;
              expenseSelectedMonth = null;
              expenseSelectedYear = null;
            }),
          ),
          const SizedBox(width: 8),
          if (expenseFilterType == 'date')
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: expenseSelectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => expenseSelectedDate = picked);
              },
              child: Text(DateFormat('yyyy-MM-dd').format(expenseSelectedDate)),
            ),
          if (expenseFilterType == 'month')
            Row(
              children: [
                DropdownButton<int>(
                  value: expenseSelectedMonth,
                  hint: const Text('Month'),
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(DateFormat.MMMM().format(DateTime(0, i + 1))),
                  )),
                  onChanged: (val) => setState(() => expenseSelectedMonth = val),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: expenseSelectedYear,
                  hint: const Text('Year'),
                  items: List.generate(6, (i) {
                    int year = DateTime.now().year - i;
                    return DropdownMenuItem(value: year, child: Text('$year'));
                  }),
                  onChanged: (val) => setState(() => expenseSelectedYear = val),
                ),
              ],
            ),
          if (expenseFilterType == 'year')
            DropdownButton<int>(
              value: expenseSelectedYear,
              hint: const Text('Year'),
              items: List.generate(6, (i) {
                int year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => setState(() => expenseSelectedYear = val),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: fetchExpenseTypeSummary,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      );
    }
  }

  Widget buildRevExpFilterControls() {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    if (isSmallScreen) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          DropdownButton<String>(
            value: revExpFilterType,
            items: const [
              DropdownMenuItem(value: 'date', child: Text('Date')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (val) => setState(() {
              revExpFilterType = val!;
              revExpSelectedMonth = null;
              revExpSelectedYear = null;
            }),
          ),
          if (revExpFilterType == 'date')
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: revExpSelectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => revExpSelectedDate = picked);
              },
              child: Text(DateFormat('yyyy-MM-dd').format(revExpSelectedDate)),
            ),
          if (revExpFilterType == 'month')
            DropdownButton<int>(
              value: revExpSelectedMonth,
              hint: const Text('Month'),
              items: List.generate(12, (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(DateFormat.MMMM().format(DateTime(0, i + 1))),
              )),
              onChanged: (val) => setState(() => revExpSelectedMonth = val),
            ),
          if (revExpFilterType == 'month')
            DropdownButton<int>(
              value: revExpSelectedYear,
              hint: const Text('Year'),
              items: List.generate(6, (i) {
                int year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => setState(() => revExpSelectedYear = val),
            ),
          if (revExpFilterType == 'year')
            DropdownButton<int>(
              value: revExpSelectedYear,
              hint: const Text('Year'),
              items: List.generate(6, (i) {
                int year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => setState(() => revExpSelectedYear = val),
            ),
          IconButton(
            onPressed: fetchRevenueExpenseData,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      );
    } else {
      return Row(
        children: [
          DropdownButton<String>(
            value: revExpFilterType,
            items: const [
              DropdownMenuItem(value: 'date', child: Text('Date')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (val) => setState(() {
              revExpFilterType = val!;
              revExpSelectedMonth = null;
              revExpSelectedYear = null;
            }),
          ),
          const SizedBox(width: 8),
          if (revExpFilterType == 'date')
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: revExpSelectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => revExpSelectedDate = picked);
              },
              child: Text(DateFormat('yyyy-MM-dd').format(revExpSelectedDate)),
            ),
          if (revExpFilterType == 'month')
            Row(
              children: [
                DropdownButton<int>(
                  value: revExpSelectedMonth,
                  hint: const Text('Month'),
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(DateFormat.MMMM().format(DateTime(0, i + 1))),
                  )),
                  onChanged: (val) => setState(() => revExpSelectedMonth = val),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: revExpSelectedYear,
                  hint: const Text('Year'),
                  items: List.generate(6, (i) {
                    int year = DateTime.now().year - i;
                    return DropdownMenuItem(value: year, child: Text('$year'));
                  }),
                  onChanged: (val) => setState(() => revExpSelectedYear = val),
                ),
              ],
            ),
          if (revExpFilterType == 'year')
            DropdownButton<int>(
              value: revExpSelectedYear,
              hint: const Text('Year'),
              items: List.generate(6, (i) {
                int year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => setState(() => revExpSelectedYear = val),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: fetchRevenueExpenseData,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      );
    }
  }

  // Define pieColors for use in charts
  final List<Color> pieColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.brown,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.lime,
  ];

  Widget buildGrowthYearFilter() {
    return Row(
      children: [
        const Text('Year:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: growthSelectedYear,
          items: List.generate(6, (i) {
            int year = DateTime.now().year - i;
            return DropdownMenuItem(value: year, child: Text('$year'));
          }),
          onChanged: (val) {
            setState(() {
              growthSelectedYear = val!;
            });
            fetchGrowthData();
          },
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('Search'),
          onPressed: fetchGrowthData,
        ),
      ],
    );
  }

  Widget buildGrowthBarLineChart() {
    if (_growthLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (growthData.isEmpty) {
      return const Center(child: Text('No growth data'));
    }

    final barGroups = growthData.map((e) {
      final monthIdx = (e['month'] as int) - 1;
      return BarChartGroupData(
        x: monthIdx,
        barRods: [
          BarChartRodData(
            toY: (e['profit'] as num).toDouble(),
            color: Colors.blue,
            width: 16,
          ),
        ],
      );
    }).toList();

    final lineSpots = growthData.map((e) {
      final monthIdx = (e['month'] as int) - 1;
      return FlSpot(
        monthIdx.toDouble(),
        (e['revenue'] as num).toDouble(),
      );
    }).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'PROFIT (Bar) & REVENUE (Line) GROWTH',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            buildGrowthYearFilter(),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = [
                            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                          ];
                          return Text(months[value.toInt() % 12]);
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                  extraLinesData: ExtraLinesData(
                    extraLinesOnTop: true,
                    horizontalLines: [],
                    verticalLines: [],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 16, height: 16, color: Colors.blue),
                const SizedBox(width: 4),
                const Text('Profit (Bar)'),
                const SizedBox(width: 16),
                Container(width: 16, height: 3, color: Colors.orange),
                const SizedBox(width: 4),
                const Text('Revenue (Line)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double paidValue = totalPaid < 0 ? 0 : totalPaid;
    double pipelineValue = pipeline < 0 ? 0 : pipeline;
    if (paidValue == 0 && pipelineValue == 0) pipelineValue = 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return Column(
                      children: [
                        // Branch selection
                        Row(
                          children: [
                            const Text('Branch:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: selectedBranch,
                              items: branches
                                  .map((branch) => DropdownMenuItem(
                                        value: branch,
                                        child: Text(branch),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedBranch = val;
                                });
                                fetchAllData();
                                fetchExpenseTypeSummary();
                                fetchRevenueExpenseData(); // Add this
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Pie charts: Row for wide screens, Column for small screens
                        isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildWalkinsCard()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildPaidPipelineCard(paidValue, pipelineValue)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildExpensePieChart()), // <-- KEEP THIS
                                ],
                              )
                            : Column(
                                children: [
                                  _buildWalkinsCard(),
                                  const SizedBox(height: 16),
                                  _buildPaidPipelineCard(paidValue, pipelineValue),
                                  const SizedBox(height: 16),
                                
                                ],
                              ),
                        const SizedBox(height: 24),
                        // Payment Modes
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'PAYMENT MODE (Cash vs Online)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                buildModeFilterControls(),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 220,
                                  child: PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          value: modeCashTotal,
                                          color: Colors.blue,
                                          title: 'Cash',
                                          radius: 60,
                                        ),
                                        PieChartSectionData(
                                          value: modeOnlineTotal,
                                          color: Colors.teal,
                                          title: 'Online',
                                          radius: 60,
                                        ),
                                        if (modeCashTotal == 0 && modeOnlineTotal == 0)
                                          PieChartSectionData(
                                            value: 1,
                                            color: Colors.grey[300]!,
                                            title: 'No Data',
                                            radius: 60,
                                          ),
                                      ],
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('Total Cash: ₹$modeCashTotal', style: const TextStyle(fontSize: 16)),
                                Text('Total Online: ₹$modeOnlineTotal', style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Expenses by Type
                        _buildExpensePieChart(),
                        const SizedBox(height: 24),
                        // Revenue vs Expense
                        _buildRevenueExpensePieChart(),
                        const SizedBox(height: 24),
                        // Profit/Revenue Growth
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'PROFIT/REVENUE GROWTH',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                buildGrowthYearFilter(),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 220,
                                  child: PieChart(
                                    PieChartData(
                                      sections: growthData.map((data) {
                                        final monthIdx = (data['month'] ?? 1) - 1;
                                          final monthNames = [
                                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                        ];
                                        final monthName = monthNames[monthIdx % 12];
                                        final profit = (data['profit'] ?? 0) is num
                                            ? (data['profit'] ?? 0).toDouble()
                                            : double.tryParse('${data['profit'] ?? 0}') ?? 0;
                                        final profitColor = pieColors[monthIdx % pieColors.length];
                                        return PieChartSectionData(
                                          value: profit.abs(),
                                          color: profitColor,
                                          title: '$monthName\n${profit >= 0 ? 'Profit' : 'Loss'}\n₹${profit.abs().toStringAsFixed(0)}',
                                          radius: 60,
                                          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                        );
                                      }).toList(),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...growthData.map((data) {
                                  final monthIdx = (data['month'] ?? 1) - 1;
                                  final monthNames = [
                                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                  ];
                                  final monthName = monthNames[monthIdx % 12];
                                  final profit = (data['profit'] ?? 0) is num
                                      ? (data['profit'] ?? 0).toDouble()
                                      : double.tryParse('${data['profit'] ?? 0}') ?? 0;
                                  final color = pieColors[monthIdx % pieColors.length];
                                  return Row(
                                    children: [
                                      Container(width: 16, height: 16, color: color),
                                      const SizedBox(width: 8),
                                      Text('$monthName: ₹${profit.abs().toStringAsFixed(0)}'),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Profit/Revenue Growth Bar & Line Chart
                        buildGrowthBarLineChart(),
                      ],
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchAllData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // Helper widgets for cards
  Widget _buildWalkinsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'PATIENTS WALKINS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            buildFilterControls(
              filterType: regFilterType,
              selectedDate: regSelectedDate,
              selectedMonth: regSelectedMonth,
              selectedYear: regSelectedYear,
              onTypeChanged: (val) {
                setState(() {
                  regFilterType = val;
                  regSelectedMonth = null;
                  regSelectedYear = null;
                });
              },
              onDateChanged: (date) {
                setState(() => regSelectedDate = date);
              },
              onMonthChanged: (month) {
                setState(() => regSelectedMonth = month);
              },
              onYearChanged: (year) {
                setState(() => regSelectedYear = year);
              },
              onSearch: fetchRegistrationsData,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: registrations.toDouble(),
                      color: Colors.purple,
                      title: 'Walkins',
                      titleStyle: const TextStyle(color: Colors.white),
                      radius: 60,
                    ),
                    if (registrations == 0)
                      PieChartSectionData(
                        value: 1,
                        color: Colors.grey[300]!,
                        title: 'No Data',
                        radius: 60,
                      ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Total Walkins: $registrations', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidPipelineCard(double paidValue, double pipelineValue) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Paid vs Pipeline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            buildFilterControls(
              filterType: paidFilterType,
              selectedDate: paidSelectedDate,
              selectedMonth: paidSelectedMonth,
              selectedYear: paidSelectedYear,
              onTypeChanged: (val) {
                setState(() {
                  paidFilterType = val;
                  paidSelectedMonth = null;
                  paidSelectedYear = null;
                });
              },
              onDateChanged: (date) {
                setState(() => paidSelectedDate = date);
              },
              onMonthChanged: (month) {
                setState(() => paidSelectedMonth = month);
              },
              onYearChanged: (year) {
                setState(() => paidSelectedYear = year);
              },
              onSearch: fetchPaidPipelineData,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: paidValue,
                      color: Colors.green,
                      title: 'Paid',
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: pipelineValue,
                      color: Colors.orange,
                      title: 'Pipeline',
                      radius: 60,
                    ),
                    if (paidValue == 0 && pipelineValue == 0)
                      PieChartSectionData(
                        value: 1,
                        color: Colors.grey[300]!,
                        title: 'No Data',
                        radius: 60,
                      ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Total Paid: ₹$totalPaid', style: const TextStyle(fontSize: 16)),
            Text('Pipeline: ₹$pipeline', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePieChart() {
    if (_expenseLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (expenseTypeSummary.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'EXPENSES BY TYPE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              buildExpenseFilterControls(),
              const SizedBox(height: 16),
              const Text('No expense data'),
            ],
          ),
        ),
      );
    }
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.brown,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
    ];
    int colorIdx = 0;
    final total = expenseTypeSummary.values.fold(0.0, (a, b) => a + b);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'EXPENSES BY TYPE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            buildExpenseFilterControls(),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: expenseTypeSummary.entries.map((entry) {
                    final color = colors[colorIdx++ % colors.length];
                    final percent = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
                    return PieChartSectionData(
                      value: entry.value,
                      color: color,
                      title: '${entry.key}\n₹${entry.value.toStringAsFixed(0)}\n$percent%',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...expenseTypeSummary.entries.map((entry) {
              final color = colors[expenseTypeSummary.keys.toList().indexOf(entry.key) % colors.length];
              return Row(
                children: [
                  Container(width: 16, height: 16, color: color),
                  const SizedBox(width: 8),
                  Text('${entry.key}: ₹${entry.value.toStringAsFixed(0)}'),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueExpensePieChart() {
    if (_revExpLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final hasData = revenueTotal > 0 || expenseTotal > 0;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'REVENUE VS EXPENSE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            buildRevExpFilterControls(),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: hasData
                      ? [
                          PieChartSectionData(
                            value: revenueTotal,
                            color: Colors.green,
                            title: 'Revenue',
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: expenseTotal,
                            color: Colors.red,
                            title: 'Expense',
                            radius: 60,
                          ),
                        ]
                      : [
                          PieChartSectionData(
                            value: 1,
                            color: Colors.grey[300]!,
                            title: 'No Data',
                            radius: 60,
                          ),
                        ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Profit: ₹${profitTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Revenue: ₹${revenueTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            Text('Expense: ₹${expenseTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
