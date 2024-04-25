import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeState {
  Map<String, bool> likedPosts =
      {}; // Map to store liked post IDs and their states

  Future<void> toggleHeartReact(String blogPostId, bool userHasLiked) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in.');
        return;
      }

      String userEmail = user.email ?? '';
      final postRef =
          FirebaseFirestore.instance.collection('AdminBlogs').doc(blogPostId);
      final likesRef = postRef.collection('likes').doc(userEmail);

      final userLikeSnapshot = await likesRef.get();

      FirebaseFirestore.instance.runTransaction((transaction) async {
        if (userHasLiked) {
          transaction.update(postRef, {
            'heartCount': FieldValue.increment(-1),
          });
          transaction.delete(likesRef);
        } else {
          transaction.update(postRef, {
            'heartCount': FieldValue.increment(1),
          });
          transaction.set(likesRef, {
            'likedAt': FieldValue.serverTimestamp(),
          });
        }
      }).then((result) {
        print("Toggle heart react successfully.");
      }).catchError((error) {
        print("Failed to toggle heart react: $error");
      });
    } catch (error) {
      print('Error toggling heart react: $error');
    }
  }

  Future<bool> checkUserLiked(String blogPostId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      String userEmail = user.email ?? '';
      final likesRef = FirebaseFirestore.instance
          .collection('AdminBlogs')
          .doc(blogPostId)
          .collection('likes')
          .doc(userEmail);

      final userLikeSnapshot = await likesRef.get();
      return userLikeSnapshot.exists;
    } catch (error) {
      print('Error checking user like: $error');
      return false;
    }
  }
}
