import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mad/analytics/models/expense.dart';
import 'package:mad/analytics/models/pie_data.dart';
import 'package:mad/analytics/styles/styles.dart';
import 'package:mad/analytics/widgets/category_box.dart';
import 'package:mad/analytics/widgets/expense_widget.dart';

class StaticsByCategory extends StatefulWidget {
  const StaticsByCategory({Key? key}) : super(key: key);

  @override
  State<StaticsByCategory> createState() => _StaticsByCategoryState();
}

class _StaticsByCategoryState extends State<StaticsByCategory> {
  int touchedIndex = -1;
  final ScrollController _scrollController = ScrollController();

  List<Expense> expenses = []; // List to hold expenses fetched from Firestore
  int totalCat = 0;
  int totalDog = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnimalCollection();
  }

  Future<void> _fetchAnimalCollection() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Animal')
          .where('Status', isNotEqualTo: 'Adopted')
          .get();

      totalCat = 0;
      totalDog = 0;

      querySnapshot.docs.forEach((doc) {
        if (doc['CatOrDog'] == 'Cat') {
          totalCat++;
        } else if (doc['CatOrDog'] == 'Dog') {
          totalDog++;
        }
      });

      setState(() {
        expenses = [
          Expense(
            expenseName: 'Cat',
            expensePercentage: totalCat / (totalCat + totalDog) * 100,
            color: Color(0xFFE96560), // Example color
          ),
          Expense(
            expenseName: 'Dog',
            expensePercentage: totalDog / (totalCat + totalDog) * 100,
            color: Colors.grey, // Example color
          ),
        ];
      });
    } catch (e) {
      print('Error fetching Animal collection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: Styles.defaultPadding),
      child: CategoryBox(
        suffix: Container(),
        title: "Number of Cats and Dogs",
        children: [
          Expanded(
            child: _pieChart(
              expenses
                  .map(
                    (e) => PieData(value: e.expensePercentage, color: e.color),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: _otherExpenses(expenses),
          ),
        ],
      ),
    );
  }

  Widget _otherExpenses(List<Expense> expenses) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Styles.defaultLightWhiteColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(2),
        children: expenses
            .map(
              (Expense e) => ExpenseWidget(
                expense: e,
                totalCat: totalCat,
                totalDog: totalDog,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _pieChart(List<PieData> data) {
    int totalSum = totalCat + totalDog; // Calculate the total sum

    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              "Total: $totalSum", // Display "Total: " followed by the total sum
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          PieChart(
            PieChartData(
              sections: data
                  .map(
                    (e) => PieChartSectionData(
                      color: e.color,
                      value: e.value,
                      radius: touchedIndex == data.indexOf(e) ? 35.0 : 25.0,
                      title: '',
                    ),
                  )
                  .toList(),
              borderData: FlBorderData(
                show: false,
              ),
              sectionsSpace: 0,
              centerSpaceRadius: 50,
            ),
          ),
        ],
      ),
    );
  }
}
