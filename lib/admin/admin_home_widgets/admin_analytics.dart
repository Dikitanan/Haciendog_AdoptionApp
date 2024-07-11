import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mad/analytics/main.dart';

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
    return SingleChildScrollView(
      child: Container(
        height: 800,
        child: FintechDasboardApp(),
      ),
    );
  }
}
