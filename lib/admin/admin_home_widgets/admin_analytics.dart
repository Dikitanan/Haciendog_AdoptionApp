import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalytics extends StatefulWidget {
  const AdminAnalytics({Key? key}) : super(key: key);

  @override
  State<AdminAnalytics> createState() => _AdminAnalyticsState();
}

class _AdminAnalyticsState extends State<AdminAnalytics> {
  int totalDogs = 40; // Example value for total dogs
  int totalCats = 60; // Example value for total cats
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Container(
            height: 1770,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatisticCard('Total Users', '0'),
                    _buildStatisticCard('Total Pets', '0'),
                    _buildStatisticCard('Total Adopted Pets', '0'),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildChartWithTitle(
                        title: 'Total Dogs and Cats',
                        chart: _buildPieChart(totalDogs, totalCats),
                        height: 570,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      _buildChartWithTitle(
                        title: 'Adoption Requests',
                        chart: _buildBarChart(),
                        height: 450,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      _buildChartWithTitle(
                        title: 'Adoption Rate',
                        chart: _buildLineChart(),
                        height: 450,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticCard(String title, String value) {
    return Card(
      elevation: 4.0,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartWithTitle(
      {required String title, required Widget chart, required double height}) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: height,
          width: 700,
          child: chart,
        ),
      ],
    );
  }

  Widget _buildPieChart(int totalDogs, int totalCats) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              height: 500,
              width: 500,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                        value: totalDogs.toDouble(),
                        color: Colors.blue,
                        title: '$totalDogs Dogs'),
                    PieChartSectionData(
                        value: totalCats.toDouble(),
                        color: Colors.orange,
                        title: '$totalCats Cats'),
                  ],
                  centerSpaceRadius: 80,
                  sectionsSpace: 2,
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLabel('Total Dogs: $totalDogs'),
                SizedBox(width: 20),
                _buildLabel('Total Cats: $totalCats'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBarChart() {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: [
              BarChartGroupData(x: 0, barRods: [
                BarChartRodData(toY: 8, color: Colors.blue),
              ], showingTooltipIndicators: [
                0
              ]),
              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(toY: 10, color: Colors.blue),
              ], showingTooltipIndicators: [
                0
              ]),
              BarChartGroupData(x: 2, barRods: [
                BarChartRodData(toY: 14, color: Colors.blue),
              ], showingTooltipIndicators: [
                0
              ]),
              BarChartGroupData(x: 3, barRods: [
                BarChartRodData(toY: 15, color: Colors.blue),
              ], showingTooltipIndicators: [
                0
              ]),
              BarChartGroupData(x: 4, barRods: [
                BarChartRodData(toY: 13, color: Colors.blue),
              ], showingTooltipIndicators: [
                0
              ]),
              BarChartGroupData(x: 5, barRods: [
                BarChartRodData(toY: 10, color: Colors.blue),
              ], showingTooltipIndicators: [
                0
              ]),
              BarChartGroupData(x: 6, barRods: [
                BarChartRodData(toY: 6, color: Colors.blue),
              ], showingTooltipIndicators: [
                0
              ]),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    const style = TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    );
                    Widget text;
                    switch (value.toInt()) {
                      case 0:
                        text = Text('Pending', style: style);
                        break;
                      case 1:
                        text = Text('Accepted', style: style);
                        break;
                      case 2:
                        text = Text('Shipped', style: style);
                        break;
                      case 3:
                        text = Text('Adopted', style: style);
                        break;
                      case 4:
                        text = Text('Rejected', style: style);
                        break;
                      case 5:
                        text = Text('Cancelled', style: style);
                        break;
                      case 6:
                        text = Text('Archived', style: style);
                        break;
                      default:
                        text = Text('', style: style);
                        break;
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: text,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, 1),
                  FlSpot(1, 3),
                  FlSpot(2, 5),
                  FlSpot(3, 7),
                  FlSpot(4, 4),
                  FlSpot(5, 6),
                  FlSpot(6, 8),
                ],
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
