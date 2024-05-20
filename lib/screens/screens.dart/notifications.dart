import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserNotifications extends StatefulWidget {
  const UserNotifications({Key? key}) : super(key: key);

  @override
  State<UserNotifications> createState() => _UserNotificationsState();
}

class _UserNotificationsState extends State<UserNotifications> {
  late Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      notificationsStream;

  @override
  void initState() {
    super.initState();
    notificationsStream = fetchNotificationsStream();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchNotificationsStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email ?? '';

      // Stream notifications from Firestore
      return FirebaseFirestore.instance
          .collection('Notifications')
          .where('email', isEqualTo: email)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.toList());
    }
    // Return an empty stream if user is null
    return Stream.value([]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600, // Specify a fixed height for the widget
      child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No notifications available.'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              QueryDocumentSnapshot<Map<String, dynamic>> notification =
                  snapshot.data![index];
              return _buildNotificationBody(
                notification['title'] ?? '',
                notification['body'] ?? '',
                (notification['timestamp'] as Timestamp)
                    .toDate()
                    .toString(), // Convert timestamp to string date
                notification.reference, // Pass the document reference
                notification['isSeen'] ?? false, // Pass isSeen value
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationBody(String title, String body, String date,
      DocumentReference reference, bool isSeen) {
    Color cardColor = isSeen
        ? Colors.white
        : Colors.grey[300] ?? const Color.fromARGB(255, 255, 255, 255);

    return GestureDetector(
      onTap: () async {
        // Check if notification is already seen
        if (!isSeen) {
          // Update isSeen to true
          await reference.update({'isSeen': true});

          // Get the current user's email
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            String userEmail = user.email ?? '';

            // Update notificationCount in UserNewMessage collection
            DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                .collection('UserNewMessage')
                .doc(userEmail)
                .get();
            int notificationCount = userSnapshot['notificationCount'] ?? 0;
            if (notificationCount > 0) {
              await FirebaseFirestore.instance
                  .collection('UserNewMessage')
                  .doc(userEmail)
                  .update({'notificationCount': FieldValue.increment(-1)});
            }
          }
        }

        // Show dialog with notification details
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(body),
                SizedBox(height: 8),
                Text(formatDate(date)), // Format the date string
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        height: 150, // Specify a fixed height for each notification card
        child: Card(
          elevation: 3,
          color: cardColor, // Set the color based on isSeen
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDate(date), // Format the date string
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    String formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${_formatHour(dateTime.hour)}:${_formatMinute(dateTime.minute)} '
        '${dateTime.hour >= 12 ? 'pm' : 'am'}';
    return formattedDate;
  }

  String _formatHour(int hour) {
    if (hour == 0) {
      return '12'; // 12 AM
    } else if (hour > 12) {
      return '${hour - 12}'; // PM hours
    } else {
      return hour.toString(); // AM hours
    }
  }

  String _formatMinute(int minute) {
    return minute < 10 ? '0$minute' : minute.toString();
  }
}
