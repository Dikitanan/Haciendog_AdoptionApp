import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mad/analytics/data/mock_data.dart';
import 'package:mad/analytics/responsive.dart';
import 'package:mad/analytics/styles/styles.dart';
import 'package:mad/analytics/widgets/currency_text.dart';
import 'package:intl/intl.dart';

class BarChartWithTitle extends StatefulWidget {
  final String title;
  final Color barColor;
  final double amount;
  final Function(DateTimeRange?)
      onDateRangeSelected; // Callback for date range selection

  const BarChartWithTitle({
    Key? key,
    required this.title,
    required this.amount,
    required this.barColor,
    required this.onDateRangeSelected, // Pass callback
  }) : super(key: key);

  @override
  _BarChartWithTitleState createState() => _BarChartWithTitleState();
}

class _BarChartWithTitleState extends State<BarChartWithTitle> {
  DateTimeRange? _selectedDateRange;

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

  Future<void> _selectDateRange(BuildContext context) async {
    // Use DateRangePicker to select the date range
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1), // Earliest selectable date
      lastDate: DateTime.now(), // Latest selectable date
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      widget.onDateRangeSelected(
          picked); // Call the function passed in to handle date range
    }
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
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
                onSelected: (int result) {
                  if (result == 0) {
                    _selectDateRange(context);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                  const PopupMenuItem<int>(
                    value: 0,
                    child: Text('Filter by Date'),
                  ),
                ],
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
                      _getDateRangeText(), // Show the formatted date range or default text
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
                      _getDateRangeText(), // Show the formatted date range or default text
                      style: TextStyle(
                        color: Styles.defaultGreyColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
          const SizedBox(
            height: 38,
          ),
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
                  leftTitles: SideTitles(showTitles: false),
                  bottomTitles: SideTitles(
                    rotateAngle: Responsive.isMobile(context) ? 45 : 0,
                    showTitles: true,
                    getTextStyles: (context, value) => TextStyle(
                      color: Styles.defaultLightGreyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    getTitles: (double value) {
                      switch (value.toInt()) {
                        case 0:
                          return 'Mon';
                        case 1:
                          return 'Tue';
                        case 2:
                          return 'Wed';
                        case 3:
                          return 'Thu';
                        case 4:
                          return 'Fri';
                        case 5:
                          return 'Sat';
                        case 6:
                          return 'Sun';
                        default:
                          return '';
                      }
                    },
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: MockData.getBarChartitems(
                  widget.barColor,
                  width: Responsive.isMobile(context) ? 10 : 25,
                ),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
