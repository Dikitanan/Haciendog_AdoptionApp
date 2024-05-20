import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mad/theme/color.dart';

class NotificationBox extends StatefulWidget {
  const NotificationBox({
    Key? key,
    this.onTap,
    this.notificationClicked = false,
  }) : super(key: key);

  final GestureTapCallback? onTap;
  final bool notificationClicked;

  @override
  _NotificationBoxState createState() => _NotificationBoxState();
}

class _NotificationBoxState extends State<NotificationBox> {
  late Stream<DocumentSnapshot> _notificationStream;

  @override
  void initState() {
    super.initState();
    _notificationStream = _subscribeToNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _notificationStream,
      builder: (context, snapshot) {
        int notifiedNumber = 0;

        if (snapshot.hasData) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('notificationCount')) {
            notifiedNumber = data['notificationCount'] as int;
          }
        }

        String bellIconPath = widget.notificationClicked
            ? "assets/icons/bell.svg"
            : "assets/icons/bell.svg";

        MaterialColor? iconColor =
            widget.notificationClicked ? Colors.red : null;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.appBarColor,
              border: Border.all(color: Colors.grey.withOpacity(.3)),
            ),
            child: notifiedNumber > 0
                ? Badge(
                    backgroundColor: AppColor.actionColor,
                    child: SvgPicture.asset(
                      bellIconPath,
                      width: 25,
                      height: 25,
                      color: iconColor,
                    ),
                  )
                : SvgPicture.asset(
                    bellIconPath,
                    width: 25,
                    height: 25,
                    color: iconColor,
                  ),
          ),
        );
      },
    );
  }

  Stream<DocumentSnapshot> _subscribeToNotificationCount() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('UserNewMessage')
          .doc(user.email) // Assuming email is the document ID
          .snapshots();
    } else {
      throw Exception("User not logged in");
    }
  }
}
