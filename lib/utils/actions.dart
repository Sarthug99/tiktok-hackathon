// actions.dart
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/screens/feed_screen.dart';
import 'package:instagram_clone_flutter/screens/add_post_screen.dart';

class Actions {
  static void swipeUp(BuildContext context) {
    final double height = MediaQuery.of(context).size.height * 0.35 + 20; // Height of one post + padding
    FeedScreen.scrollController.animateTo(
      FeedScreen.scrollController.offset + height,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    print("Swiping up");
  }

  static void swipeDown(BuildContext context) {
    final double height = MediaQuery.of(context).size.height * 0.35 + 20; // Height of one post + padding
    FeedScreen.scrollController.animateTo(
      FeedScreen.scrollController.offset - height,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    print("Swiping down");
  }

  static void addPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPostScreen()),
    );
  }
}
