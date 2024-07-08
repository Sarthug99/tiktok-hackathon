import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/utils/global_variable.dart';
import 'package:instagram_clone_flutter/main.dart'; // Import the VoiceAssistant class
import 'package:instagram_clone_flutter/screens/feed_screen.dart';
import 'package:instagram_clone_flutter/screens/search_screen.dart';
import 'package:instagram_clone_flutter/screens/add_post_screen.dart';
import 'package:instagram_clone_flutter/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({Key? key}) : super(key: key);

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  int _page = 0;
  late PageController pageController; // for tabs animation
  late VoiceAssistant voiceAssistant; // Instance of VoiceAssistant
  bool _isListening = false; // State to track if listening

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    voiceAssistant = VoiceAssistant(
      onListeningStateChanged: (isListening) {
        setState(() {
          _isListening = isListening;
        });
      },
    ); // Initialize VoiceAssistant
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    voiceAssistant.stopListening(); // Stop listening when disposed
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    setState(() {
      _page = page;
    });
    pageController.jumpToPage(page);
  }

  void _toggleListening(BuildContext context) {
    if (_isListening) {
      voiceAssistant.stopListening();
    } else {
      voiceAssistant.startListening(context); // Pass context here
    }
    setState(() {
      _isListening = !_isListening;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: [
          const FeedScreen(),
          const SearchScreen(),
          const AddPostScreen(),
          const Center(child: Text('Notifications Screen')),
          ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid), // Use the current user's UID
        ],
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: mobileBackgroundColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: (_page == 0) ? primaryColor : secondaryColor,
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
              color: (_page == 1) ? primaryColor : secondaryColor,
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle,
              color: (_page == 2) ? primaryColor : secondaryColor,
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.favorite,
              color: (_page == 3) ? primaryColor : secondaryColor,
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: (_page == 4) ? primaryColor : secondaryColor,
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
        ],
        onTap: navigationTapped,
        currentIndex: _page,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _toggleListening(context), // Pass context here
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
