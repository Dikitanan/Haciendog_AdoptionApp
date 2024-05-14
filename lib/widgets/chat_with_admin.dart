import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatWithAdmin extends StatefulWidget {
  const ChatWithAdmin({Key? key}) : super(key: key);

  @override
  State<ChatWithAdmin> createState() => _ChatWithAdminState();
}

class _ChatWithAdminState extends State<ChatWithAdmin> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference _messagesCollection =
      FirebaseFirestore.instance.collection('admin_messages');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String adminEmail = 'ivory@gmail.com';

  Timestamp? _lastTimestamp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with Admin'),
        centerTitle: true,
      ),
      body: Card(
        margin: EdgeInsets.symmetric(vertical: 16),
        child: Container(
          height: 600,
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _messagesCollection
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final messages = snapshot.data!.docs
                        .map((doc) =>
                            Message.fromMap(doc.data() as Map<String, dynamic>))
                        .where((message) =>
                            (message.senderEmail == _auth.currentUser?.email &&
                                message.receiverEmail == adminEmail) ||
                            (message.senderEmail == adminEmail &&
                                message.receiverEmail ==
                                    _auth.currentUser?.email))
                        .toList();

                    // Sort messages by timestamp in descending order
                    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    return ListView.builder(
                      itemCount: messages.length,
                      reverse: true, // Reverse the order of the ListView
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final bool isCurrentUserSent =
                            message.senderEmail == _auth.currentUser?.email;
                        final bool showDivider = index == messages.length - 1 ||
                            _shouldShowDivider(
                                message.timestamp,
                                messages[index + 1]
                                    .timestamp); // Adjust index for next message

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDivider) _buildDivider(message.timestamp),
                            _buildMessage(message, isCurrentUserSent),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInputField(),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowDivider(Timestamp currentTimestamp, Timestamp nextTimestamp) {
    final diff = currentTimestamp.seconds - nextTimestamp.seconds;
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

  Widget _buildMessage(Message message, bool isCurrentUserSent) {
    return Align(
      alignment:
          isCurrentUserSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUserSent ? Color(0xFFE96560) : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isCurrentUserSent ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send),
            color: Color(0xFFE96560),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final String? userEmail = _auth.currentUser?.email;
    if (userEmail != null && _messageController.text.isNotEmpty) {
      final bool hasProfile = await _checkUserProfile(userEmail);
      if (hasProfile) {
        final String messageText = _messageController.text.trim();
        final timestamp = Timestamp.now();
        final messageData = {
          'text': messageText,
          'timestamp': timestamp,
          'senderEmail': userEmail,
          'receiverEmail': adminEmail,
        };
        _messageController.clear();
        await _messagesCollection.add(messageData);

        // Update or create document in UserNewMessage collection
        final userMessageDoc = await FirebaseFirestore.instance
            .collection('UserNewMessage')
            .doc(userEmail)
            .get();

        if (userMessageDoc.exists) {
          // If document exists, update messageCount
          int currentMessageCount = userMessageDoc.data()?['messageCount'] ?? 0;
          await FirebaseFirestore.instance
              .collection('UserNewMessage')
              .doc(userEmail)
              .update({'messageCount': currentMessageCount + 1});
        } else {
          // If document doesn't exist, create a new one
          await FirebaseFirestore.instance
              .collection('UserNewMessage')
              .doc(userEmail)
              .set({'email': userEmail, 'messageCount': 1});
        }
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Can't Send Message"),
              content: Text("Please set up your profile first."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<bool> _checkUserProfile(String userEmail) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore
        .collection('Profiles')
        .where('email', isEqualTo: userEmail)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }
}

class Message {
  final String text;
  final Timestamp timestamp;
  final String senderEmail;
  final String receiverEmail;

  Message({
    required this.text,
    required this.timestamp,
    required this.senderEmail,
    required this.receiverEmail,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      senderEmail: map['senderEmail'] ?? '',
      receiverEmail: map['receiverEmail'] ?? '',
    );
  }
}
