import 'package:flutter/material.dart';

class ChatWithAdmin extends StatefulWidget {
  const ChatWithAdmin({Key? key}) : super(key: key);

  @override
  State<ChatWithAdmin> createState() => _ChatWithAdminState();
}

class _ChatWithAdminState extends State<ChatWithAdmin> {
  List<Message> _messages = []; // List to hold messages

  @override
  void initState() {
    super.initState();
    // Add a sample message when the chat screen is initialized
    _messages
        .add(Message(text: 'Hello! How can I assist you?', isSender: false));
  }

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
                child: SingleChildScrollView(
                  child: Column(
                    children: _messages.map((message) {
                      return _buildMessage(message);
                    }).toList(),
                  ),
                ),
              ),
              _buildInputField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Message message) {
    return Align(
      alignment:
          message.isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isSender ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style:
              TextStyle(color: message.isSender ? Colors.white : Colors.black),
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
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _messages.add(Message(text: value, isSender: true));
                });
              },
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              // Add message to the list
              setState(() {
                _messages.add(Message(text: 'Your message', isSender: true));
              });
            },
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isSender;

  Message({required this.text, required this.isSender});
}
