import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSideMessage extends StatefulWidget {
  const AdminSideMessage({Key? key}) : super(key: key);

  @override
  State<AdminSideMessage> createState() => _AdminSideMessageState();
}

class _AdminSideMessageState extends State<AdminSideMessage> {
  List<String> users = [];
  Map<String, int> userMessageCounts = {}; // Map to store message counts
  String? selectedUser;
  String? userEmail;
  bool isLoadingMessages = false;
  TextEditingController messageController = TextEditingController();
  late StreamSubscription<DocumentSnapshot> _messageCountSubscription;

  @override
  void initState() {
    super.initState();
    fetchUsernames();
    // Start listening to UserNewMessage collection
    _listenToMessageCount();
  }

  @override
  void dispose() {
    // Dispose subscription to avoid memory leaks
    _messageCountSubscription.cancel();
    super.dispose();
  }

  Future<void> fetchUsernames() async {
    setState(() {
      isLoadingMessages = true;
    });
    await Firebase.initializeApp();
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch emails from 'UserEmails' collection
    QuerySnapshot userEmailsSnapshot =
        await firestore.collection('UserEmails').get();

    // Filter out "ivory@gmail.com" from the list of user emails
    List<String> userEmails = userEmailsSnapshot.docs
        .map((doc) => doc['email'] as String)
        .where((email) => email != "ivory@gmail.com")
        .toList();

    // Set the user list using the filtered emails fetched from 'UserEmails'
    users = userEmails;

    // Fetch message counts for each user
    await fetchUserMessageCounts();

    if (users.isNotEmpty) {
      setState(() {
        selectedUser = users.first;
      });
      fetchUserEmail(selectedUser!);
    }
  }

  Future<void> fetchUserMessageCounts() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch documents from 'UserNewMessage' collection
    QuerySnapshot userMessageCountSnapshot =
        await firestore.collection('UserNewMessage').get();

    // Extract email and message count from each document and store it in the map
    userMessageCounts = {
      for (var doc in userMessageCountSnapshot.docs)
        doc['email'] as String: doc['messageCount'] as int
    };

    // Update the UI
    setState(() {});
  }

  void _listenToMessageCount() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    _messageCountSubscription =
        firestore.collection('UserNewMessage').snapshots().listen((snapshot) {
      // Update userMessageCounts when changes occur in the UserNewMessage collection
      userMessageCounts = {
        for (var doc in snapshot.docs)
          doc['email'] as String: doc['messageCount'] as int
      };
      // Update UI
      setState(() {});
    }) as StreamSubscription<DocumentSnapshot<Object?>>;
  }

  Future<void> fetchUserEmail(String username) async {
    setState(() {
      isLoadingMessages = true; // Show circular progress indicator
      selectedUser = "Loading..."; // Change label to "Loading..."
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore
        .collection('Profiles')
        .where('email', isEqualTo: username)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // If there's a match in the Profiles collection, set the username as the label
      setState(() {
        userEmail = username;
        selectedUser = querySnapshot.docs.first['username'] as String?;
      });

      // Reset message count to 0 when user is clicked
      await resetMessageCount(username);
    } else {
      // If no match is found in the Profiles collection, set the label as "User Profile Not Set Yet"
      setState(() {
        userEmail = username;
        selectedUser = "User Profile Not Set Yet";
      });
    }

    fetchMessages();
  }

  Future<void> resetMessageCount(String userEmail) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection('UserNewMessage')
        .doc(userEmail)
        .update({'messageCount': 0});
    // Refresh message counts after updating
    await fetchUserMessageCounts();
  }

  Stream<List<Map<String, dynamic>>> messagesStream() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    return firestore.collection('admin_messages').snapshots().map((snapshot) {
      List<Map<String, dynamic>> messages = [];
      for (var doc in snapshot.docs) {
        final message = {
          'text': doc['text'] as String,
          'timestamp': doc['timestamp'] as Timestamp,
          'senderEmail': doc['senderEmail'] as String,
          'receiverEmail': doc['receiverEmail'] as String,
        };
        if (message['senderEmail'] == userEmail ||
            message['receiverEmail'] == userEmail) {
          messages.add(message);
        }
      }
      messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      return messages;
    });
  }

  void fetchMessages() async {
    setState(() {
      isLoadingMessages = false;
    });
  }

  Future<void> sendMessage(String text, String receiverEmail) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('admin_messages').add({
      'text': text,
      'timestamp': Timestamp.now(),
      'senderEmail': 'ivory@gmail.com', // Default sender email
      'receiverEmail': receiverEmail,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (BuildContext context, int index) {
                  final user = users[index];
                  final messageCount = userMessageCounts[user];

                  // If message count is zero or null, display the user email without the count
                  final title = messageCount == null || messageCount == 0
                      ? user
                      : '$user ($messageCount)';

                  return ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedUser = user;
                      });
                      fetchUserEmail(selectedUser!);
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    selectedUser ?? "Loading...",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: isLoadingMessages
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: messagesStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }
                            List<Map<String, dynamic>> messages =
                                snapshot.data ?? [];
                            if (messages.isEmpty) {
                              return Center(
                                child: Text('Empty Chat'),
                              );
                            }
                            return Container(
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: SingleChildScrollView(
                                reverse: true,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children:
                                      _buildMessagesWithDividers(messages),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message here',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        onPressed: () async {
                          if (selectedUser != null &&
                              messageController.text.isNotEmpty) {
                            await sendMessage(
                                messageController.text, userEmail!);

                            messageController.clear();

                            await resetMessageCount(
                                userEmail!); // Reset message count
                          }
                        },
                        icon: Icon(Icons.send),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMessagesWithDividers(List<Map<String, dynamic>> messages) {
    List<Widget> messageWidgets = [];
    if (messages.isNotEmpty) {
      for (int i = 0; i < messages.length; i++) {
        final currentMessage = messages[i];
        final Timestamp currentTimestamp = currentMessage['timestamp'];
        if (i == 0 ||
            _shouldShowDivider(
                currentTimestamp, messages[i - 1]['timestamp'])) {
          messageWidgets.add(_buildDivider(currentTimestamp));
        }
        messageWidgets.add(_buildMessage(currentMessage));
      }
    }
    return messageWidgets;
  }

  bool _shouldShowDivider(
      Timestamp currentTimestamp, Timestamp previousTimestamp) {
    final diff = currentTimestamp.seconds - previousTimestamp.seconds;
    return diff >= 250; // 1 hour in seconds
  }

  Widget _buildDivider(Timestamp timestamp) {
    final DateTime currentDateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);
    final formattedDateTime = _formatDateTime(currentDateTime);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          formattedDateTime,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isSentMessage =
        message['senderEmail'] == userEmail; // Check if the message is sent

    return Align(
      alignment: isSentMessage ? Alignment.topLeft : Alignment.topRight,
      child: Container(
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: isSentMessage ? Colors.grey[200] : Colors.blue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.0),
            bottomLeft: isSentMessage ? Radius.circular(12.0) : Radius.zero,
            bottomRight: isSentMessage ? Radius.zero : Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
        ),
        child: Text(
          message['text'] as String,
          style: TextStyle(color: isSentMessage ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    final String hour =
        dateTime.hour < 10 ? '0${dateTime.hour}' : '${dateTime.hour}';
    final String minute =
        dateTime.minute < 10 ? '0${dateTime.minute}' : '${dateTime.minute}';
    final String hourMinute = '$hour:$minute';

    if (difference.inDays >= 1 || dateTime.day != now.day) {
      final String month = _getMonthName(dateTime.month);
      final String day = dateTime.day.toString();
      final String year = dateTime.year.toString();
      return '$month $day, $year $hourMinute';
    } else {
      final String amPm = dateTime.hour < 12 ? 'AM' : 'PM';
      final int hour12Format = dateTime.hour == 0
          ? 12
          : dateTime.hour > 12
              ? dateTime.hour - 12
              : dateTime.hour;
      return '$hour12Format:$minute $amPm';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}
