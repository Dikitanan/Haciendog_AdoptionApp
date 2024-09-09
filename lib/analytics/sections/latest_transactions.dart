import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mad/analytics/data/mock_data.dart';
import 'package:mad/analytics/models/enums/transaction_type.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mad/analytics/responsive.dart';
import 'package:mad/analytics/styles/styles.dart';
import 'package:mad/analytics/widgets/category_box.dart';
import 'package:mad/analytics/widgets/currency_text.dart';

class LatestTransactions extends StatefulWidget {
  LatestTransactions({Key? key}) : super(key: key);

  @override
  _LatestTransactionsState createState() => _LatestTransactionsState();
}

class _LatestTransactionsState extends State<LatestTransactions> {
  final ScrollController _scrollController = ScrollController();
  int _totalAdoptions = 0;
  List<Map<String, dynamic>> _adoptionData = [];

  @override
  void initState() {
    super.initState();
    _fetchAdoptions();
  }

  Future<void> _fetchAdoptions() async {
    try {
      QuerySnapshot adoptionFormsSnapshot = await FirebaseFirestore.instance
          .collection('AdoptionForms')
          .where('status', isEqualTo: 'Adopted')
          .get();

      List<Map<String, dynamic>> fetchedData = [];

      for (var adoptionFormDoc in adoptionFormsSnapshot.docs) {
        var adoptionData = adoptionFormDoc.data() as Map<String, dynamic>;

        // Fetch the pet name from the Animal collection using petId
        var animalDoc = await FirebaseFirestore.instance
            .collection('Animal')
            .doc(adoptionData['petId'])
            .get();

        var petName = (animalDoc.exists && animalDoc.data() != null)
            ? animalDoc.data()!['Name'] ?? 'Unknown'
            : 'Unknown';

        // Fetch the profile picture from the Profiles collection using the email
        var profileSnapshot = await FirebaseFirestore.instance
            .collection('Profiles')
            .where('email', isEqualTo: adoptionData['email'])
            .get();

        var profilePicture = profileSnapshot.docs.isNotEmpty
            ? profileSnapshot.docs.first.data()['profilePicture']
            : null;

        fetchedData.add({
          'name': adoptionData['name'],
          'DateAdopted': adoptionData['DateAdopted'],
          'petId': adoptionData['petId'],
          'petName': petName,
          'profilePicture': profilePicture,
        });
      }

      // Sort the data by DateAdopted in descending order
      fetchedData.sort((a, b) {
        Timestamp dateA = a['DateAdopted'] as Timestamp;
        Timestamp dateB = b['DateAdopted'] as Timestamp;
        return dateB.compareTo(dateA); // Newest first
      });

      setState(() {
        _adoptionData = fetchedData;
        _totalAdoptions = _adoptionData.length;
      });
    } catch (e) {
      print("Failed to fetch adoptions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CategoryBox(
      title: "Complete Adoptions ($_totalAdoptions)",
      suffix: TextButton(
        child: Text(
          "See all",
          style: TextStyle(
            color: Styles.defaultRedColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {},
      ),
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _adoptionData.length,
            itemBuilder: (context, index) {
              var data = _adoptionData[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                backgroundImage: data['profilePicture'] != null
                                    ? NetworkImage(
                                        data['profilePicture'] as String)
                                    : AssetImage('assets/default_avatar.png')
                                        as ImageProvider,
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: Text(
                              data['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        intl.DateFormat.MMMd().add_jm().format(
                              (data['DateAdopted'] as Timestamp).toDate(),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Visibility(
                      visible: !Responsive.isMobile(context),
                      child: Expanded(
                        child: Text(
                          "Pet ID: ${data['petId']}",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Pet Name: ${data['petName']}",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
