import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:instagram_clone_flutter/models/post.dart';
import 'package:instagram_clone_flutter/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadPost(
    String description,
    Uint8List file,
    String uid,
    String username,
    String profImage, {
    required bool isVideo,
    required Function(String, Map<String, dynamic>?) showJobCompleteDialog,
  }) async {
    String res = "Some error occurred";
    try {
      String mediaUrl = isVideo
          ? await StorageMethods().uploadVideoToStorage('posts', file)
          : await StorageMethods().uploadImageToStorage('posts', file, true);
      String postId = const Uuid().v1();
      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: mediaUrl,
        profImage: profImage,
        isVideo: isVideo,
      );
      _firestore.collection('posts').doc(postId).set(post.toJson());

      // Add the job to the 'job_processing' collection
      _firestore.collection('job_processing').doc(postId).set({
        'isVideo': isVideo,
        'postId': postId,
        'status': 'N',
      });

      // Start listening to the job status
      _startJobStatusNotifier(postId, showJobCompleteDialog);

      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  void _startJobStatusNotifier(String postId, Function(String, Map<String, dynamic>?) showJobCompleteDialog) {
    late StreamSubscription<DocumentSnapshot> jobSubscription;
    jobSubscription = FirebaseFirestore.instance
        .collection('job_processing')
        .doc(postId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        String jobStatus = snapshot.data()?['status'] ?? 'N';
        if (jobStatus == 'C') {
          // Show a dialog box
          Map<String, dynamic>? result = snapshot.data()?['result'];
          showJobCompleteDialog(postId, result);
          jobSubscription.cancel();  // Cancel the subscription when the job is done
        }
      }
    });
  }

  Future<String> likePost(String postId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> postComment(String postId, String text, String uid,
      String name, String profilePic) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> deletePost(String postId) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('posts').doc(postId).delete();
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(uid).get();
      List following = (snap.data()! as dynamic)['following'];

      if (following.contains(followId)) {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      } else {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId])
        });
      }
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }
}
