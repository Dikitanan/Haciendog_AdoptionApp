import 'package:flutter/material.dart';
import 'package:mad/analytics/layout/app_layout.dart';
import 'package:mad/analytics/models/card_details.dart';
import 'package:mad/analytics/models/enums/card_type.dart';
import 'package:mad/analytics/responsive.dart';
import 'package:mad/analytics/sections/expense_income_chart.dart';
import 'package:mad/analytics/sections/latest_transactions.dart';
import 'package:mad/analytics/sections/statics_by_category.dart';
import 'package:mad/analytics/sections/upgrade_pro_section.dart';
import 'package:mad/analytics/sections/your_cards_section.dart';
import 'package:mad/analytics/styles/styles.dart';

class FintechDasboardApp extends StatelessWidget {
  const FintechDasboardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Styles.scaffoldBackgroundColor,
        scrollbarTheme: Styles.scrollbarTheme,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppLayout(
          content: Row(
            children: [
              // Main Panel
              Expanded(
                child: Column(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: ExpenseIncomeCharts(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Styles.defaultPadding,
                        ),
                        child: const UpgradeProSection(),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: LatestTransactions(),
                    ),
                  ],
                ),
                flex: 5,
              ),
              // Right Panel
              Visibility(
                visible: Responsive.isDesktop(context),
                child: Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: Styles.defaultPadding),
                    child: Column(
                      children: [
                        CardsSection(
                          cardDetails: [
                            CardDetails("431421432", CardType.mastercard),
                            CardDetails("423142231", CardType.mastercard),
                          ],
                        ),
                        const Expanded(
                          child: StaticsByCategory(),
                        ),
                      ],
                    ),
                  ),
                  flex: 2,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
