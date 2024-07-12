import 'package:flutter/material.dart';
import 'package:mad/analytics/models/expense.dart';

class ExpenseWidget extends StatelessWidget {
  final Expense expense;
  final int totalCat;
  final int totalDog;

  const ExpenseWidget({
    Key? key,
    required this.expense,
    required this.totalCat,
    required this.totalDog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String countText = '';
    if (expense.expenseName == 'Cat') {
      countText = ' ($totalCat)';
    } else if (expense.expenseName == 'Dog') {
      countText = ' ($totalDog)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            margin: const EdgeInsets.only(right: 18),
            decoration: BoxDecoration(
              color: expense.color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              "${expense.expenseName} -$countText ${expense.expensePercentage.round()}%",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
