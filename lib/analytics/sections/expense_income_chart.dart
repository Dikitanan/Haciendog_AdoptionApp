import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mad/analytics/styles/styles.dart';
import 'package:mad/analytics/widgets/bar_chart_with_title.dart';

class ExpenseIncomeCharts extends StatefulWidget {
  const ExpenseIncomeCharts({Key? key}) : super(key: key);

  @override
  _ExpenseIncomeChartsState createState() => _ExpenseIncomeChartsState();
}

class _ExpenseIncomeChartsState extends State<ExpenseIncomeCharts> {
  int totalUsers = 0;
  int totalVerifiedUsers = 0;
  int bannedUsers = 0;
  int pendingAdoptionRequests = 0;
  double totalDonationAmount = 0; // New variable to store total donations

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTotalDonations(); // Fetch total donations

    _getPendingAdoptionRequestsStream().listen((count) {
      setState(() {
        pendingAdoptionRequests = count;
      });
    });
  }

  Future<void> fetchTotalDonations() async {
    try {
      // Fetch all donations from the Donations collection
      QuerySnapshot donationsSnapshot = await FirebaseFirestore.instance
          .collection('Donations')
          .where('status', isEqualTo: 'Accepted')
          .get();

      double total = 0;

      // Sum up the "amount" field safely, handling potential string or null values
      for (var doc in donationsSnapshot.docs) {
        var amountValue = doc['amount'];
        if (amountValue != null) {
          // Check if the value is a string and parse it to a double
          double amount = amountValue is String
              ? double.tryParse(amountValue) ?? 0
              : amountValue.toDouble();
          total += amount;
        }
      }

      // Update the state with the total donation amount
      setState(() {
        totalDonationAmount = total;
      });
    } catch (e) {
      print('Error fetching donation data: $e');
    }
  }

  Stream<int> _getPendingAdoptionRequestsStream() {
    return FirebaseFirestore.instance
        .collection('AdoptionForms')
        .where('status',
            whereNotIn: ['Rejected', 'Adopted', 'Cancelled', 'Archived'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> fetchUserData() async {
    try {
      // Fetch total users from UserEmails collection excluding banned users
      QuerySnapshot userEmailsSnapshot = await FirebaseFirestore.instance
          .collection('UserEmails')
          .where('ban', isEqualTo: false) // Exclude banned users
          .get();

      setState(() {
        totalUsers = userEmailsSnapshot.docs.length;
      });

      // Fetch banned users from UserEmails collection
      QuerySnapshot bannedUsersSnapshot = await FirebaseFirestore.instance
          .collection('UserEmails')
          .where('ban', isEqualTo: true) // Only banned users
          .get();

      setState(() {
        bannedUsers = bannedUsersSnapshot.docs.length;
      });

      // Fetch verified users from Profiles collection by matching emails
      QuerySnapshot profilesSnapshot =
          await FirebaseFirestore.instance.collection('Profiles').get();
      List<String> verifiedEmails =
          profilesSnapshot.docs.map((doc) => doc['email'].toString()).toList();

      setState(() {
        totalVerifiedUsers = userEmailsSnapshot.docs
            .where((doc) => verifiedEmails.contains(doc['email']))
            .length;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

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
                      Icon(Icons.people, size: 30, color: Color(0xFFE96560)),
                      SizedBox(width: 10),
                      Text(
                        "Total Users: $totalUsers",
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
                      Icon(Icons.verified, size: 30, color: Color(0xFFE96560)),
                      SizedBox(width: 10),
                      Text(
                        "Total Verified Users: $totalVerifiedUsers",
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
                      Icon(Icons.block, size: 30, color: Color(0xFFE96560)),
                      SizedBox(width: 10),
                      Text(
                        "Banned Users: $bannedUsers",
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
                          size: 30, color: Color(0xFFE96560)),
                      SizedBox(width: 10),
                      Text(
                        "Pending Adoptions: $pendingAdoptionRequests",
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
            amount: totalDonationAmount,
            barColor: Styles.defaultRedColor,
          ),
        ),
      ],
    );
  }
}
