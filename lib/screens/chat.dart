import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mad/theme/color.dart';

import 'package:mad/widgets/custom_image.dart';
import 'package:mad/widgets/notify_box.dart';

class ChatItem extends StatelessWidget {
  const ChatItem(
    this.chatData, {
    Key? key,
    this.isNotified = true,
    this.profileSize = 50,
  }) : super(key: key);

  final chatData;
  final bool isNotified;
  final double profileSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPhoto(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                buildNameAndTime(),
                const SizedBox(
                  height: 5,
                ),
                _buildTextAndNotified(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAndNotified() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            chatData['last_text'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 5),
          child: NotifyBox(
            number: chatData['notify'],
            boxSize: 17,
            color: AppColor.red,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoto() {
    return CustomImage(
      chatData['image'],
      width: profileSize,
      height: profileSize,
    );
  }

  Widget buildNameAndTime() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            chatData['name'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          chatData['date'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        )
      ],
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    print('Send button pressed'); // Add this line
    final String message = _messageController.text.trim();
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;
    final DateTime now = DateTime.now();
    final String formattedDate =
        '${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}';

    if (message.isNotEmpty) {
      await FirebaseFirestore.instance.collection('chat').add({
        'last_text': message,
        'name': currentUserEmail,
        'date': formattedDate,
        'image': '', // Set user's profile image here if available
        'notify': 0,
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chat')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var chatData = snapshot.data!.docs[index];
                    return ChatItem(
                      chatData,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
