import 'package:flutter/material.dart';

class MessageCountProvider extends ChangeNotifier {
  Map<String, int> _newMessageCountMap = {};

  Map<String, int> get newMessageCountMap => _newMessageCountMap;

  void updateMessageCount(String userEmail, int count) {
    _newMessageCountMap[userEmail] = count;
    notifyListeners();
  }
}
