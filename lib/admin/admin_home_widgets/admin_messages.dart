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
  List<Map<String, String>> userProfiles =
      []; // List to store usernames and emails
  Map<String, int> userMessageCounts = {}; // Map to store message counts
  String? selectedUser;
  String? selectedUserEmail;
  bool isLoadingMessages = false;
  TextEditingController messageController = TextEditingController();
  late StreamSubscription<QuerySnapshot> _messageCountSubscription;

  @override
  void initState() {
    super.initState();
    fetchUserProfiles();
    // Start listening to UserNewMessage collection
    _listenToMessageCount();
  }

  @override
  void dispose() {
    // Dispose subscription to avoid memory leaks
    _messageCountSubscription.cancel();
    super.dispose();
  }

  Future<void> fetchUserProfiles() async {
    setState(() {
      isLoadingMessages = true;
    });

    await Firebase.initializeApp();
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Fetch emails from 'UserEmails' collection
      QuerySnapshot userEmailsSnapshot =
          await firestore.collection('UserEmails').get();

      // Filter out "ivory@gmail.com" from the list of user emails
      List<String> userEmails = userEmailsSnapshot.docs
          .map((doc) =>
              (doc['email'] as String).toLowerCase()) // Convert to lowercase
          .where((email) => email != "ivory@gmail.com")
          .toList();

      print('Fetched User Emails: ${userEmails.join(', ')}'); // Debugging log

      // Fetch profiles for all user emails in parallel
      List<Future<void>> profileFutures = userEmails.map((email) async {
        DocumentSnapshot profileSnapshot =
            await firestore.collection('Profiles').doc(email).get();

        if (profileSnapshot.exists) {
          var profileData = profileSnapshot.data()
              as Map<String, dynamic>; // Explicit cast to Map
          String? firstName = profileData['firstName'] as String?;
          String? lastName = profileData['lastName'] as String?;
          String username = '$firstName $lastName';

          userProfiles.add({
            'username': username,
            'email': email,
          });
        } else {
          print('No profile found for email: $email'); // Debugging log
        }
      }).toList();

      // Wait for all profile fetching to complete
      await Future.wait(profileFutures);

      // Fetch message counts and total messages in parallel
      await Future.wait([
        fetchUserMessageCounts(),
        fetchUserTotalMessages(),
      ]);

      // Fetch last messages for each user
      List<Future<void>> messageFutures = userProfiles.map((userProfile) async {
        DocumentSnapshot newMessageSnapshot = await firestore
            .collection('UserNewMessage')
            .doc(userProfile['email'])
            .get();

        if (newMessageSnapshot.exists) {
          var messageData = newMessageSnapshot.data()
              as Map<String, dynamic>; // Explicit cast
          userProfile['LastMessage'] = messageData['LastMessage'] ?? '';
        } else {
          userProfile['LastMessage'] = '';
        }
      }).toList();

      // Wait for all last message fetching to complete
      await Future.wait(messageFutures);

      // Sort userProfiles based on new messages (messageCount) and total messages (totalMessage)
      userProfiles.sort((a, b) {
        int messageCountA = userMessageCounts[a['email']] ?? 0;
        int messageCountB = userMessageCounts[b['email']] ?? 0;

        // Sort by messageCount first (new messages)
        if (messageCountA != messageCountB) {
          return messageCountB
              .compareTo(messageCountA); // New messages at the top
        }

        // Sort by totalMessage count if messageCount is the same
        int totalMessageA = int.tryParse(a['totalMessage'] ?? '0') ?? 0;
        int totalMessageB = int.tryParse(b['totalMessage'] ?? '0') ?? 0;
        return totalMessageB.compareTo(totalMessageA); // Sort by total messages
      });

      // Fetch the email of the selected user
      if (selectedUser != null) {
        await fetchUserEmail(selectedUser!);
      }
    } catch (e) {
      print("Error fetching user profiles: $e");
    } finally {
      setState(() {
        isLoadingMessages = false;
      });
    }
  }

// Method to fetch total message count for each user from 'UserNewMessage' collection
  Future<void> fetchUserTotalMessages() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    List<Future<void>> totalMessageFutures =
        userProfiles.map((userProfile) async {
      QuerySnapshot totalMessageSnapshot = await firestore
          .collection('UserNewMessage')
          .where('email', isEqualTo: userProfile['email'])
          .get();
      if (totalMessageSnapshot.docs.isNotEmpty) {
        var messageDoc = totalMessageSnapshot.docs.first;
        var messageData =
            messageDoc.data() as Map<String, dynamic>; // Explicit cast
        userProfile['totalMessage'] =
            (messageData['totalMessage'] ?? 0).toString(); // Convert to string
      } else {
        userProfile['totalMessage'] = '0'; // Default string value
      }
    }).toList();

    // Wait for all total message count fetching to complete
    await Future.wait(totalMessageFutures);
  }

  Future<void> fetchUserMessageCounts() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Fetch documents from 'UserNewMessage' collection
      QuerySnapshot userMessageCountSnapshot =
          await firestore.collection('UserNewMessage').get();

      // Loop through each document and safely extract 'email' and 'messageCount'
      for (var doc in userMessageCountSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          // Check if 'email' exists in the document before accessing it
          if (data.containsKey('email')) {
            String email = data['email'] as String;
            int messageCount =
                data['messageCount'] ?? 0; // Default to 0 if missing

            // Add message count to userMessageCounts only if the profile exists
            if (userProfiles.any((profile) => profile['email'] == email)) {
              userMessageCounts[email] = messageCount;
            }
          } else {
            print('Email field does not exist in this document: ${doc.id}');
          }
        } else {
          print('Document data is null for document ID: ${doc.id}');
        }
      }

      setState(() {}); // Update the UI
    } catch (e) {
      print("Error fetching user message counts: $e");
    }
  }

  void _listenToMessageCount() {
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
    });
  }

  Future<void> fetchUserEmail(String email) async {
    setState(() {
      isLoadingMessages = true; // Show circular progress indicator
      selectedUser = "Loading..."; // Change label to "Loading..."
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      QuerySnapshot querySnapshot = await firestore
          .collection('Profiles')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // If there's a match in the Profiles collection, set the email and username as the label
        setState(() {
          selectedUserEmail = querySnapshot.docs.first['email'] as String?;
          selectedUser = email;
        });

        // Reset message count to 0 when user is clicked
        await resetMessageCount(selectedUserEmail!);
      } else {
        // If no match is found in the Profiles collection, set the label as "User Profile Not Set Yet"
        setState(() {
          selectedUserEmail = null;
          selectedUser = "User Profile Not Set Yet";
        });
      }

      fetchMessages();
    } catch (e) {
      print("Error fetching user email: $e");
    } finally {
      setState(() {
        isLoadingMessages = false;
      });
    }
  }

  Future<void> resetMessageCount(String userEmail) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      await firestore
          .collection('UserNewMessage')
          .doc(userEmail)
          .update({'messageCount': 0});
      // Refresh message counts after updating
      await fetchUserMessageCounts();
    } catch (e) {
      print("Error resetting message count: $e");
    }
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
        if (message['senderEmail'] == selectedUserEmail ||
            message['receiverEmail'] == selectedUserEmail) {
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

    try {
      // Add to 'admin_messages' collection
      await firestore.collection('admin_messages').add({
        'text': text,
        'timestamp': Timestamp.now(),
        'senderEmail': 'ivory@gmail.com', // Default sender email
        'receiverEmail': receiverEmail,
      });

      messageController.clear();

      // Update 'UserNewMessage' collection
      DocumentReference userNewMessageDoc =
          firestore.collection('UserNewMessage').doc(receiverEmail);
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userNewMessageDoc);
        if (!snapshot.exists) {
          // If the document does not exist, create it with ReceivedCount and totalMessage set to 1
          transaction.set(userNewMessageDoc, {
            'ReceivedCount': 1,
            'totalMessage': 1,
            'messageSort': Timestamp.now(),
          });
        } else {
          // If the document exists, increment ReceivedCount and totalMessage
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          int newReceivedCount = (data?['ReceivedCount'] ?? 0) + 1;
          int newTotalMessage = (data?['totalMessage'] ?? 0) + 1;
          transaction.update(userNewMessageDoc, {
            'ReceivedCount': newReceivedCount,
            'totalMessage': newTotalMessage,
            'messageSort': Timestamp.now(),
          });
        }
      });

      // Update 'UserNewMessage' collection for message count
      final userMessageDoc =
          await firestore.collection('UserNewMessage').doc(receiverEmail).get();

      if (userMessageDoc.exists) {
        // If document exists, update LastMessage
        await firestore.collection('UserNewMessage').doc(receiverEmail).update({
          'LastMessage': 'You: $text', // Update LastMessage
        });

        // Update userProfiles list with the new LastMessage
        for (var profile in userProfiles) {
          if (profile['email'] == receiverEmail) {
            setState(() {
              profile['LastMessage'] = 'You: $text';
            });
            break;
          }
        }
      } else {
        // If document doesn't exist, create a new one with LastMessage
        await firestore.collection('UserNewMessage').doc(receiverEmail).set({
          'email': receiverEmail,
          'LastMessage': 'You: $text', // Prefix "You:" to the message
        });
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color.fromARGB(255, 244, 217, 217),
                    Colors.white,
                  ],
                ),
              ),
              child: ListView.builder(
                itemCount: userProfiles.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Container(
                      color: Color(0xFFE96560),
                      child: ListTile(
                        title: Text(
                          'MESSAGES',
                          style: TextStyle(color: Colors.white),
                        ),
                        selected: selectedUser == null,
                        onTap: () async {
                          setState(() {
                            selectedUser = null;
                          });
                        },
                      ),
                    );
                  } else {
                    final userProfile = userProfiles[index - 1];
                    final username = userProfile['username'];
                    final email = userProfile['email'];
                    final lastMessage = userProfile['LastMessage'];
                    final messageCount = userMessageCounts[email] ?? 0;
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            username ?? '',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            lastMessage ?? '',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 62, 53, 53),
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                          ),
                          trailing: CircleAvatar(
                            backgroundColor: messageCount > 0
                                ? Colors.red
                                : Colors.transparent,
                            child: Text(
                              messageCount > 0 ? '$messageCount' : '',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          selected: selectedUser == email,
                          onTap: () async {
                            setState(() {
                              selectedUser = email;
                            });
                            await fetchUserEmail(email!);
                          },
                        ),
                        Divider(), // Add Divider between users
                      ],
                    );
                  }
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: <Widget>[
                if (selectedUser != null) ...[
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
                                  messageController.text, selectedUserEmail!);

                              await resetMessageCount(
                                  selectedUserEmail!); // Reset message count
                            }
                          },
                          icon: Icon(Icons.send),
                          color: Color(0xFFE96560),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Expanded(
                    child: Center(
                      child: Text(
                        'Select a user to see messages',
                        style: TextStyle(fontSize: 18),
                      ),
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
    bool isSentMessage = message['senderEmail'] ==
        selectedUserEmail; // Check if the message is sent

    return Align(
      alignment: isSentMessage ? Alignment.topLeft : Alignment.topRight,
      child: Container(
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: isSentMessage ? Colors.grey[200] : Color(0xFFE96560),
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
