import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mad/admin/post_provider.dart';

class MiddlePart extends StatefulWidget {
  final LikeState likeState;

  const MiddlePart({Key? key, required this.likeState}) : super(key: key);

  @override
  State<MiddlePart> createState() => _MiddlePartState();
}

class _MiddlePartState extends State<MiddlePart>
    with AutomaticKeepAliveClientMixin<MiddlePart> {
  late Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('AdminBlogs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Colors.white,
      child: StreamBuilder(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Blogs Yet'));
          }
          return SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 50),
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      DateTime createdAt =
                          (doc['createdAt'] as Timestamp).toDate();
                      String timeAgo = timeAgoSinceDate(createdAt);

                      String blogId = snapshot.data!.docs[index].id;
                      int commentCount = doc['commentCount'] ?? 0;
                      int heartCount = doc['heartCount'] ?? 0;

                      return _buildPostCard(
                        name: doc['username'] ?? 'Anonymous',
                        profileImage: doc['profilePicture'] ??
                            'https://static.vecteezy.com/system/resources/thumbnails/020/911/740/small/user-profile-icon-profile-avatar-user-icon-male-icon-face-icon-profile-icon-free-png.png',
                        timePosted: timeAgo,
                        title: doc['title'] ?? 'No Title',
                        description: doc['description'] ?? 'No Description',
                        image: doc['imageURL'] ??
                            'https://static.vecteezy.com/system/resources/thumbnails/020/911/740/small/user-profile-icon-profile-avatar-user-icon-male-icon-face-icon-profile-icon-free-png.png',
                        blogId: blogId,
                        commentCount: commentCount,
                        heartCount: heartCount,
                        key: ValueKey<String>(blogId),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard({
    required String name,
    required String profileImage,
    required String timePosted,
    required String title,
    required String description,
    required String image,
    required String blogId,
    required int commentCount,
    required int heartCount,
    Key? key,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(profileImage),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(timePosted),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Image.network(
                  image,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        _showCommentsForBlogPost(context, blogId);
                      },
                      icon: Row(
                        children: [
                          const Icon(Icons.comment),
                          const SizedBox(width: 5),
                          Text('$commentCount'),
                        ],
                      ),
                    ),
                    _buildHeartIconButton(blogId, heartCount),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartIconButton(String blogId, int heartCount) {
    return FutureBuilder<bool>(
      future: widget.likeState.checkUserLiked(blogId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }
        bool userHasLiked = snapshot.data ?? false;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: IconButton(
            key: ValueKey<bool>(userHasLiked),
            onPressed: () {
              widget.likeState.toggleHeartReact(blogId, userHasLiked);
              setState(() {
                if (userHasLiked) {
                  heartCount--;
                } else {
                  heartCount++;
                }
              });
            },
            icon: Row(
              children: [
                Icon(
                  userHasLiked ? Icons.favorite : Icons.favorite_border,
                  color: userHasLiked ? Colors.red : null,
                ),
                const SizedBox(width: 5),
                Text('$heartCount'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommentsForBlogPost(BuildContext context, String blogId) {
    TextEditingController _commentController = TextEditingController();
    bool _isCommentUploading = false;

    // Show a dialog for displaying and adding comments
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // StreamBuilder to listen for changes in comments
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('blogsComments')
                  .where('blogId', isEqualTo: blogId)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Center();
                  default:
                    List<QueryDocumentSnapshot> comments =
                        snapshot.data!.docs.toList();
                    // Sort comments by createdAt timestamp
                    comments.sort((a, b) {
                      final timestampA = a['dateOfComment'] as Timestamp?;
                      final timestampB = b['dateOfComment'] as Timestamp?;
                      return timestampB!.compareTo(timestampA!);
                    });
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.8,
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                // Title of the dialog
                                const Text(
                                  'Comments for Blog Post',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                // Display existing comments or a loading indicator
                                _isCommentUploading
                                    ? Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.4,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.6,
                                        padding: const EdgeInsets.all(16),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : Container(
                                        constraints: BoxConstraints(
                                          minWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.8, // Example minimum width
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.8, // Example maximum width
                                          minHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.46, // Example minimum height
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.46, // Example maximum height
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.8,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.46,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children:
                                                comments.map((commentDoc) {
                                              var commentData =
                                                  commentDoc.data()
                                                      as Map<String, dynamic>;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Display comment text
                                                    Text(
                                                      commentData['comment'],
                                                      style: const TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // Display comment author and time
                                                    Text(
                                                      '${timeAgoSinceDate((commentData['dateOfComment'] as Timestamp).toDate())} by ${commentData['username']}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    const Divider(),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 8),
                                // Text field for entering a new comment
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
                                            ? const CircularProgressIndicator()
                                            : const Icon(Icons.send),
                                        onPressed: _isCommentUploading
                                            ? null
                                            : () async {
                                                // Add a new comment
                                                if (_commentController.text
                                                    .trim()
                                                    .isEmpty) {
                                                  return;
                                                }
                                                setState(() {
                                                  _isCommentUploading = true;
                                                });
                                                try {
                                                  String userEmail =
                                                      await getCurrentUserEmail();
                                                  bool commentAdded =
                                                      await addCommentToFirestore(
                                                    _commentController.text,
                                                    userEmail,
                                                    blogId,
                                                    context,
                                                  );
                                                  if (commentAdded) {
                                                    await updateCommentCount(
                                                        blogId);
                                                    _commentController.clear();
                                                  }
                                                } catch (e) {
                                                  print(
                                                      'Error sending comment: $e');
                                                } finally {
                                                  setState(() {
                                                    _isCommentUploading = false;
                                                  });
                                                }
                                              },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Close button to close the dialog
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                }
              },
            );
          },
        );
      },
    );
  }

  Future<String> getCurrentUserEmail() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return user.email ?? '';
      } else {
        return '';
      }
    } catch (error) {
      print('Error getting current user email: $error');
      return '';
    }
  }

  Future<bool> addCommentToFirestore(String comment, String userEmail,
      String blogId, BuildContext context) async {
    try {
      DateTime now = DateTime.now();

      DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
          .collection('Profiles')
          .doc(userEmail)
          .get();

      if (!userProfileSnapshot.exists) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Profile Setup Required'),
              content: const Text(
                  'Cannot upload comment. Please setup your Profile in [SETTINGS]'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return false;
      }

      Map<String, dynamic>? userProfile =
          userProfileSnapshot.data() as Map<String, dynamic>?;
      String username = userProfile?['username'] as String? ?? 'Unknown';

      await FirebaseFirestore.instance.collection('blogsComments').add({
        'comment': comment,
        'dateOfComment': now,
        'userEmail': userEmail,
        'username': username,
        'blogId': blogId,
      });
      return true;
    } catch (error) {
      print('Error adding comment: $error');
      return false;
    }
  }

  Future<void> updateCommentCount(String blogId) async {
    try {
      DocumentReference blogRef =
          FirebaseFirestore.instance.collection('AdminBlogs').doc(blogId);

      DocumentSnapshot blogSnapshot = await blogRef.get();
      int currentCommentCount = blogSnapshot['commentCount'] ?? 0;

      await blogRef.update({'commentCount': currentCommentCount + 1});
    } catch (error) {
      print('Error updating comment count: $error');
    }
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
}
