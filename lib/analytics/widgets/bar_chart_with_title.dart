import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mad/analytics/responsive.dart';
import 'package:mad/analytics/styles/styles.dart';
import 'package:mad/analytics/widgets/currency_text.dart';

class BarChartWithTitle extends StatefulWidget {
  final String title;
  final Color barColor;
  final double amount;
  final Function(DateTimeRange?) onDateRangeSelected;

  const BarChartWithTitle({
    Key? key,
    required this.title,
    required this.amount,
    required this.barColor,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  _BarChartWithTitleState createState() => _BarChartWithTitleState();
}

class _BarChartWithTitleState extends State<BarChartWithTitle> {
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _monthlyData = [];

  // Function to format date range into a readable string
  String _getDateRangeText() {
    if (_selectedDateRange != null) {
      final DateFormat formatter = DateFormat('MM/dd/yyyy');
      String startDate = formatter.format(_selectedDateRange!.start);
      String endDate = formatter.format(_selectedDateRange!.end);
      return "$startDate - $endDate";
    }
    return "All donations";
  }

  // Fetch data from Firebase and group by month
  // Fetch data from Firebase and group by month
  Future<void> _fetchDonationsData() async {
    DateTime start =
        DateTime.now().subtract(Duration(days: 7 * 30)); // 7 months back
    DateTime end = DateTime.now();

    QuerySnapshot donationsSnapshot = await FirebaseFirestore.instance
        .collection('Donations')
        .where('DateOfDonation',
            isGreaterThanOrEqualTo: start, isLessThanOrEqualTo: end)
        .get();

    List<QueryDocumentSnapshot> donations = donationsSnapshot.docs;

    // Initialize a map for monthly sums with 0 for the last 7 months
    Map<String, double> monthlySums = {};
    for (int i = 0; i < 7; i++) {
      DateTime monthDate = DateTime.now().subtract(Duration(days: i * 30));
      String monthKey = DateFormat('yyyy-MM').format(monthDate);
      monthlySums[monthKey] = 0.0; // Initialize to 0
    }

    for (var donation in donations) {
      DateTime donationDate =
          (donation['DateOfDonation'] as Timestamp).toDate();

      // Handle both double and string values for 'amount'
      double amount;
      if (donation['amount'] is String) {
        amount = double.tryParse(donation['amount']) ?? 0.0;
      } else if (donation['amount'] is int) {
        amount = donation['amount'].toDouble();
      } else {
        amount = donation['amount'];
      }

      // Format date as 'YYYY-MM' to group by month
      String monthKey = DateFormat('yyyy-MM').format(donationDate);

      if (monthlySums.containsKey(monthKey)) {
        monthlySums[monthKey] = monthlySums[monthKey]! + amount;
      }
    }

    // Convert the map to a sorted list for chart rendering
    setState(() {
      // Convert the map to a sorted list for chart rendering
      setState(() {
        _monthlyData = monthlySums.entries
            .map((e) => {'month': e.key, 'amount': e.value})
            .toList()
          ..sort((a, b) => (a['month'] as String)
              .compareTo(b['month'] as String)); // Sort in descending order
      });
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 180)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      widget.onDateRangeSelected(picked);
      await _fetchDonationsData(); // Fetch donations after date range selection
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDonationsData(); // Fetch data initially for the last 6 months
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: Styles.defaultBorderRadius,
        color: Colors.white,
      ),
      padding: EdgeInsets.all(Styles.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Responsive.isDesktop(context)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    CurrencyText(
                      currency: "\Php",
                      amount: widget.amount,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getDateRangeText(),
                      style: TextStyle(
                        color: Styles.defaultGreyColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: <Widget>[
                    CurrencyText(
                      currency: "\Php",
                      amount: widget.amount,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getDateRangeText(),
                      style: TextStyle(
                        color: Styles.defaultGreyColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 38),
          Expanded(
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.grey,
                    getTooltipItem: (_a, _b, _c, _d) => null,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: SideTitles(showTitles: false),
                  topTitles: SideTitles(showTitles: false),
                  leftTitles: SideTitles(
                    showTitles: true,
                    getTextStyles: (context, value) => TextStyle(
                      color: Styles.defaultLightGreyColor,
                      fontWeight: FontWeight.bold,
                      fontSize:
                          10, // Set your desired font size here for the Y-axis
                    ),
                  ),
                  bottomTitles: SideTitles(
                    rotateAngle: Responsive.isMobile(context) ? 45 : 0,
                    showTitles: true,
                    getTextStyles: (context, value) => TextStyle(
                      color: Styles.defaultLightGreyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Font size for the X-axis
                    ),
                    getTitles: (double value) {
                      // Display month titles (Jan, Feb, etc.)
                      if (_monthlyData.isNotEmpty &&
                          value < _monthlyData.length) {
                        return DateFormat('MMM').format(DateTime.parse(
                            _monthlyData[value.toInt()]['month'] + '-01'));
                      }
                      return '';
                    },
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: _monthlyData.asMap().entries.map((entry) {
                  int index = entry.key;
                  double totalAmount = entry.value['amount'];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        y: totalAmount,
                        colors: [widget.barColor],
                        width: Responsive.isMobile(context) ? 10 : 25,
                      ),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
