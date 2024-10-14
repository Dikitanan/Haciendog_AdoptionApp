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
  double totalDonationAmount = 0; // Total donation amount
  DateTimeRange? selectedDateRange; // Store selected date range

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

  Future<void> fetchTotalDonations({DateTimeRange? range}) async {
    try {
      // Fetch all donations with status 'Accepted'
      QuerySnapshot donationsSnapshot =
          await FirebaseFirestore.instance.collection('Donations').get();

      double total = 0;

      // Loop through each donation document
      for (var doc in donationsSnapshot.docs) {
        // Get the DateOfDonation field as a Timestamp
        Timestamp donationDate = doc['DateOfDonation'];

        // If a date range is provided, filter donations in-memory
        if (range != null) {
          DateTime donationDateTime = donationDate.toDate();

          // Check if the donation is within the selected date range
          if (donationDateTime.isBefore(range.start) ||
              donationDateTime.isAfter(range.end)) {
            continue; // Skip donations outside the range
          }
        }

        // Get the amount and add it to the total
        var amountValue = doc['amount'];
        if (amountValue != null) {
          double amount = amountValue is String
              ? double.tryParse(amountValue) ?? 0
              : amountValue.toDouble();
          total += amount;
        }
      }

      // Update the totalDonationAmount state
      setState(() {
        totalDonationAmount = total;
      });
    } catch (e) {
      print('Error fetching donation data: $e');
    }
  }

  void _handleDateRangeSelection(DateTimeRange? range) {
    if (range != null) {
      setState(() {
        selectedDateRange = range;
      });
      fetchTotalDonations(range: range); // Fetch filtered data
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

      setState(() {
        totalVerifiedUsers = profilesSnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  double _getResponsiveFontSize(double maxWidth) {
    // Adjust the font size based on the screen width with a maximum limit of 20
    return (maxWidth / 40)
        .clamp(12, 20); // Minimum font size of 12 and maximum of 20
  }

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width;

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
                          fontSize: _getResponsiveFontSize(maxWidth),
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
                          fontSize: _getResponsiveFontSize(maxWidth),
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
                          fontSize: _getResponsiveFontSize(maxWidth),
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
                          fontSize: _getResponsiveFontSize(maxWidth),
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
            onDateRangeSelected: _handleDateRangeSelection, // Pass the callback
          ),
        ),
      ],
    );
  }
}
