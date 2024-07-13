import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mad/analytics/styles/styles.dart';
import 'package:mad/analytics/widgets/bar_chart_with_title.dart';

class ExpenseIncomeCharts extends StatelessWidget {
  const ExpenseIncomeCharts({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 15),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            height: 500,
            width: 700,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.people, size: 30, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        "Total Users: 10",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified, size: 30, color: Colors.green),
                      SizedBox(width: 10),
                      Text(
                        "Total Verified Users: 8",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.pending_actions,
                          size: 30, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        "Pending Adoptions: 10",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Flexible(
          child: BarChartWithTitle(
            title: "Total Donation",
            amount: 1980,
            barColor: Styles.defaultRedColor,
          ),
        ),
      ],
    );
  }
}
