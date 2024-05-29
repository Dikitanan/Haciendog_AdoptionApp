import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mad/admin/post_provider.dart';

class BlogsAdmin extends StatefulWidget {
  const BlogsAdmin({super.key});

  @override
  State<BlogsAdmin> createState() => _BlogsAdminState();
}

class _BlogsAdminState extends State<BlogsAdmin> {
  void _showAddBlogPostModal() async {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    String? _uploadedImageURL;
    bool _formIsValid = false;
    String? userEmail = FirebaseAuth.instance.currentUser!.email;

    Future<String> _uploadImageToFirebase(
        Uint8List fileBytes, String fileName) async {
      try {
        firebase_storage.Reference ref = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('blog_images')
            .child(fileName);
        await ref.putData(fileBytes);
        String downloadURL = await ref.getDownloadURL();
        return downloadURL;
      } catch (e) {
        print('Error uploading image to Firebase Storage: $e');
        return '';
      }
    }

    Future<void> _uploadImage() async {
      if (kIsWeb) {
        FilePickerResult? result =
            await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null) {
          Uint8List fileBytes = result.files.first.bytes!;
          String fileName = result.files.first.name;
          _uploadedImageURL = await _uploadImageToFirebase(fileBytes, fileName);
        }
      } else {
        final picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          File imageFile = File(image.path);
          String fileName = imageFile.path.split('/').last;
          Uint8List fileBytes = await imageFile.readAsBytes();
          _uploadedImageURL = await _uploadImageToFirebase(fileBytes, fileName);
        }
      }
    }

    // Check if the user's email is associated with a profile
    bool hasProfile = await _checkUserProfile(userEmail);

    if (!hasProfile) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('No Profile Associated'),
            content: Text(
                'You need to create a profile before you can upload a blog post.Please go to [SETTINGS].'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              title: const Text('Add Blog Post'),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        onChanged: (value) {
                          setState(() {
                            _formIsValid = titleController.text.isNotEmpty &&
                                descriptionController.text.isNotEmpty &&
                                _uploadedImageURL != null &&
                                _uploadedImageURL!.isNotEmpty;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: descriptionController,
                        onChanged: (value) {
                          setState(() {
                            _formIsValid = titleController.text.isNotEmpty &&
                                descriptionController.text.isNotEmpty &&
                                _uploadedImageURL != null &&
                                _uploadedImageURL!.isNotEmpty;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                      SizedBox(height: 20),
                      // Image Preview
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _uploadedImageURL != null
                            ? Image.network(
                                _uploadedImageURL!,
                                fit: BoxFit.fill,
                              )
                            : Center(
                                child: Text('Insert Image'),
                              ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _uploadImage();
                                setState(() {
                                  _formIsValid = titleController
                                          .text.isNotEmpty &&
                                      descriptionController.text.isNotEmpty &&
                                      _uploadedImageURL != null &&
                                      _uploadedImageURL!.isNotEmpty;
                                });
                              },
                              icon: Icon(Icons.image),
                              label: Text('Upload Image'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: _formIsValid
                      ? () async {
                          if (titleController.text.isEmpty ||
                              descriptionController.text.isEmpty ||
                              _uploadedImageURL == null ||
                              _uploadedImageURL!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please fill all fields and upload an image.',
                                ),
                              ),
                            );
                            return;
                          }

                          // Fetch user profile details
                          DocumentSnapshot userProfile;
                          try {
                            userProfile = await FirebaseFirestore.instance
                                .collection('Profiles')
                                .doc(
                                    userEmail) // Assuming userEmail is the document ID
                                .get();

                            if (!userProfile.exists) {
                              Fluttertoast.showToast(
                                msg: 'User profile not found!',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );
                              return;
                            }
                          } catch (e) {
                            Fluttertoast.showToast(
                              msg: 'Error fetching user profile: $e',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                            return;
                          }

                          int heartCount = 0;
                          int commentCount = 0;
                          await FirebaseFirestore.instance
                              .collection('AdminBlogs')
                              .add({
                            'title': titleController.text,
                            'description': descriptionController.text,
                            'imageURL': _uploadedImageURL,
                            'createdAt': FieldValue.serverTimestamp(),
                            'heartCount': heartCount,
                            'commentCount': commentCount,
                            'userEmail': userEmail,
                            'profilePicture': userProfile['profilePicture'],
                            'username': userProfile['username'],
                          });

                          Fluttertoast.showToast(
                            msg: 'Blog post successfully added!',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                          );
                          await Future.delayed(Duration(milliseconds: 500));
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

// Function to check if the user's email has associated profile
  Future<bool> _checkUserProfile(String? userEmail) async {
    if (userEmail == null) return false;

    DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('Profiles')
        .doc(userEmail)
        .get();

    return profileSnapshot.exists;
  }

  void _showViewBlogPostModal(DocumentSnapshot blogData) async {
    // Extract data from the document snapshot
    String imageURL = blogData['imageURL'];
    String title = blogData['title'];
    String description = blogData['description'];
    Timestamp createdAt = blogData['createdAt'];
    int heartCount = blogData['heartCount'] ?? 0;
    int commentCount = blogData['commentCount'] ?? 0;
    final String blogPostId = blogData.id;
    bool areCommentsVisible = false; // Move outside StatefulBuilder
    TextEditingController _commentController = TextEditingController();
    bool _isCommentUploading = false;

    // Create an instance of LikeState to use its methods
    LikeState likeState = LikeState();

    // Fetch the user's like status
    bool userHasLiked = await likeState.checkUserLiked(blogPostId);

    // Fetch user's profile data from Firestore
    // Retrieve the user email associated with the blog post
    String userEmail = blogData['userEmail'];

    // Fetch user's profile data from Firestore using the email associated with the blog post
    DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('Profiles')
        .doc(userEmail)
        .get();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.32,
                height: MediaQuery.of(context).size.height * 0.85,
                child: ListView(
                  children: [
                    // Profile and Time Ago
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left section with the avatar and user details
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                  profileSnapshot['profilePicture'] ??
                                      'https://randomuser.me/api/portraits/women/81.jpg',
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profileSnapshot['username'] ?? 'Unknown',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                      '${timeAgoSinceDate(createdAt.toDate())}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          // Right section with the close icon
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                    // Post Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    // Post Description
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(description,
                          style:
                              TextStyle(color: Colors.grey[800], fontSize: 16)),
                    ),
                    // Image
                    SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 400,
                        height: 390,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(imageURL),
                            fit: BoxFit.fill,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    // React and Comment Icons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            // Occupy half the space for heart react button and count
                            child: InkWell(
                              onTap: () async {
                                await likeState.toggleHeartReact(
                                    blogPostId, userHasLiked);
                                setState(() {
                                  if (userHasLiked) {
                                    heartCount--;
                                    userHasLiked = false;
                                  } else {
                                    heartCount++;
                                    userHasLiked = true;
                                  }
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      userHasLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('$heartCount'),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            // Occupy half the space for comment button and count
                            child: InkWell(
                              onTap: () {
                                // Toggle comment section visibility
                                setState(() {
                                  areCommentsVisible = !areCommentsVisible;
                                  print(
                                      'Comments section visibility toggled: $areCommentsVisible');
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.comment, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('$commentCount'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Comment Text Field
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: _isCommentUploading
                                ? CircularProgressIndicator()
                                : Icon(Icons.send),
                            onPressed: _isCommentUploading
                                ? null
                                : () async {
                                    setState(() {
                                      _isCommentUploading = true;
                                    });
                                    try {
                                      // Get the current user's email
                                      String userEmail =
                                          await getCurrentUserEmail();
                                      // Add the comment to Firestore
                                      bool commentAdded =
                                          await addCommentToFirestore(
                                        _commentController.text,
                                        userEmail,
                                        blogPostId,
                                        context,
                                      );
                                      if (commentAdded) {
                                        // Update the comment count in AdminBlogs collection
                                        await updateCommentCount(blogPostId);
                                        // Refresh the dialog to reflect the updated comment count
                                        setState(() {
                                          commentCount++;
                                        });
                                      }
                                    } catch (e) {
                                      // Handle errors or exceptions
                                      print("Error sending comment: $e");
                                    } finally {
                                      // Clear the text field after sending the comment
                                      _commentController.clear();
                                      setState(() {
                                        _isCommentUploading = false;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ),
                    ),
                    // Comments Section
                    if (areCommentsVisible) ...[
                      // Fetch and display comments
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('blogsComments')
                            .where('blogId', isEqualTo: blogPostId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else {
                            final comments = snapshot.data!.docs;
                            // Sort comments by dateOfComment in ascending order
                            comments.sort((a, b) => (b['dateOfComment']
                                    as Timestamp)
                                .compareTo(a['dateOfComment'] as Timestamp));

                            List<Widget> commentWidgets = [];
                            for (int i = 0; i < comments.length; i++) {
                              commentWidgets.add(
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(color: Colors.grey)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comments[i]['comment'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors
                                              .black87, // Change text color
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${timeAgoSinceDate((comments[i]['dateOfComment'] as Timestamp).toDate())} by ${comments[i]['username'] ?? 'Unknown'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            // Determine the number of comments to display initially
                            int initialCommentsToShow =
                                comments.length > 4 ? 4 : comments.length;
                            // Determine if there are more comments to display
                            bool hasMoreComments =
                                comments.length > initialCommentsToShow;
                            // Display only the initial comments
                            List<Widget> initialCommentWidgets = commentWidgets
                                .sublist(0, initialCommentsToShow);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  'Comments',
                                  style: TextStyle(
                                    fontSize: 20, // Increase the font size
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Colors.black87, // Change the text color
                                  ),
                                ),
                                SizedBox(
                                    height:
                                        10), // Increase the vertical spacing
                                // Display initial comments with padding and borders
                                ...initialCommentWidgets.map((commentWidget) =>
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      margin: EdgeInsets.symmetric(vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[
                                            100], // Lighter background color
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: commentWidget,
                                    )),
                                // Display "See More" button with some spacing
                                if (hasMoreComments)
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 10),
                                    child: TextButton(
                                      onPressed: () {
                                        _showAllCommentsDialog(comments);
                                      },
                                      child: Text(
                                        'See More',
                                        style: TextStyle(
                                          fontSize: 16, // Adjust the font size
                                          color: Colors.blue,
                                          fontWeight: FontWeight
                                              .bold, // Make the text bold
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAllCommentsDialog(List<DocumentSnapshot> comments) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'All Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: comments.map((comment) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['comment'],
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${timeAgoSinceDate((comment['dateOfComment'] as Timestamp).toDate())} by ${comment['username']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Divider(), // Add divider between comments
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> getCurrentUserEmail() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return user.email ?? ''; // Return the user's email if available
      } else {
        return ''; // Return empty string if user is not signed in
      }
    } catch (error) {
      print('Error getting current user email: $error');
      return ''; // Return empty string in case of error
    }
  }

  Future<bool> addCommentToFirestore(String comment, String userEmail,
      String blogId, BuildContext context) async {
    try {
      // Get the current date and time
      DateTime now = DateTime.now();

      // Fetch the username from the Profiles collection
      DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
          .collection('Profiles')
          .doc(userEmail)
          .get();

      if (!userProfileSnapshot.exists) {
        // If the userProfileSnapshot does not exist, show a dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Profile Setup Required'),
              content: Text(
                  'Cannot upload comment. Please setup your Profile in [SETTINGS]'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return false; // Indicate failure
      }

      // Explicitly cast the data to a map and extract username
      Map<String, dynamic>? userProfile =
          userProfileSnapshot.data() as Map<String, dynamic>?;
      String username = userProfile?['username'] as String? ?? 'Unknown';

      // Add the comment to Firestore with username
      await FirebaseFirestore.instance.collection('blogsComments').add({
        'comment': comment,
        'dateOfComment': now,
        'userEmail': userEmail,
        'username':
            username, // Store the username along with other comment details
        'blogId': blogId,
      });
      return true; // Indicate success
    } catch (error) {
      print('Error adding comment: $error');
      return false; // Indicate failure
    }
  }

  Future<void> updateCommentCount(String blogId) async {
    try {
      // Get the reference to the blog document
      DocumentReference blogRef =
          FirebaseFirestore.instance.collection('AdminBlogs').doc(blogId);

      // Get the current comment count
      DocumentSnapshot blogSnapshot = await blogRef.get();
      int currentCommentCount = blogSnapshot['commentCount'] ?? 0;

      // Update the comment count
      await blogRef.update({'commentCount': currentCommentCount + 1});
    } catch (error) {
      print('Error updating comment count: $error');
      // Handle error as needed
    }
  }

  Future<bool> checkUserLiked(String blogPostId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false; // User not logged in, hence not liked
    }

    final userId = user.uid;
    final likesRef = FirebaseFirestore.instance
        .collection('AdminBlogs')
        .doc(blogPostId)
        .collection('likes')
        .doc(userId);

    final userLikeSnapshot = await likesRef.get();
    return userLikeSnapshot.exists;
  }

  String timeAgoSinceDate(DateTime date) {
    Duration difference = DateTime.now().difference(date);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Animal Blogs',
          style: TextStyle(color: Colors.black),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBlogPostModal,
        backgroundColor: Colors.blue, // Change color to stand out
        child: Icon(Icons.add),
      ),
      body: Container(
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
        child: StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('AdminBlogs').snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              ); // Show a loading indicator while fetching data
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                ),
              ); // Show an error message if fetching data fails
            }

            // Extract the list of blog posts from the snapshot
            List<DocumentSnapshot> blogPosts = snapshot.data!.docs;

            // Sort blog posts by createdAt in descending order, handling null values
            blogPosts.sort((a, b) {
              final timestampA = a['createdAt'] as Timestamp?;
              final timestampB = b['createdAt'] as Timestamp?;

              // Handle null values
              if (timestampA == null && timestampB == null) {
                return 0; // Both timestamps are null, consider them equal
              }
              if (timestampA == null) {
                return 1; // Place nulls at the end
              }
              if (timestampB == null) {
                return -1; // Place nulls at the beginning
              }

              // Compare timestamps normally if they are not null
              return timestampB.compareTo(timestampA);
            });

            return MouseRegion(
              cursor: SystemMouseCursors.click, // Change cursor to pointer
              child: GridView.builder(
                padding: EdgeInsets.all(10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      4, // Increase the number of columns to make cards smaller
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio:
                      1, // Adjust aspect ratio for better card size
                ),
                itemCount: blogPosts
                    .length, // Use the count of blog posts from the database
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _showViewBlogPostModal(
                          blogPosts[index]); // Pass the document snapshot
                    },
                    child: _buildBlogPostTile(blogPosts[index]),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlogPostTile(DocumentSnapshot? blogData) {
    if (blogData == null || !blogData.exists) {
      // Return a placeholder widget if blog data is null or doesn't exist
      return Container(
        color: Colors.grey.withOpacity(0.3),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    String? imageUrl = blogData['imageURL'];
    String? title = blogData['title'];
    int? heartCount = blogData['heartCount'];
    int? commentCount = blogData['commentCount'];

    if (imageUrl == null || title == null) {
      // Return a placeholder widget if image URL or title is missing
      return Container(
        color: Colors.grey.withOpacity(0.3),
        child: Center(
          child: Text(
            'Invalid data',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    // Truncate title if it exceeds six words
    title = truncateTitle(title, 6);

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        '$heartCount',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.comment, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        '$commentCount',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String truncateTitle(String title, int maxWords) {
    List<String> words = title.split(' ');
    if (words.length <= maxWords) {
      return title;
    }
    return words.take(maxWords).join(' ') + '...';
  }
}
