import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordSecurityPage extends StatelessWidget {
  const PasswordSecurityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Password and Security'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ChangePasswordForm(),
      ),
    );
  }
}

class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({Key? key}) : super(key: key);

  @override
  _ChangePasswordFormState createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  late String? userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUserEmail();
  }

  Future<void> fetchUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email;
    }
  }

  Future<void> changePassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if the new password matches the confirmation
      if (newPasswordController.text != confirmPasswordController.text) {
        throw Exception("Passwords do not match");
      }

      // Re-authenticate the user before changing the password
      AuthCredential credential = EmailAuthProvider.credential(
          email: userEmail!, password: currentPasswordController.text);
      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithCredential(credential);

      // Change the password
      await FirebaseAuth.instance.currentUser!
          .updatePassword(newPasswordController.text);

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Success"),
            content: Text("Password changed successfully!"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  // Clear text fields
                  currentPasswordController.clear();
                  newPasswordController.clear();
                  confirmPasswordController.clear();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Error changing password: $e"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: currentPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Current Password',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 12.0),
        TextField(
          controller: newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 12.0),
        TextField(
          controller: confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20.0),
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: changePassword,
                child: Text('Change Password'),
              ),
      ],
    );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
