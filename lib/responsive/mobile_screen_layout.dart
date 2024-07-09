import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Conditional imports for VoiceAssistant
import 'package:instagram_clone_flutter/utils/voice_assistant_mobile.dart'
    if (dart.library.html) 'package:instagram_clone_flutter/utils/voice_assistant_web.dart';

import 'package:instagram_clone_flutter/screens/feed_screen.dart';
import 'package:instagram_clone_flutter/screens/search_screen.dart';
import 'package:instagram_clone_flutter/screens/add_post_screen.dart';
import 'package:instagram_clone_flutter/screens/profile_screen.dart';

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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomNavBarHeight = screenHeight * 0.07;

    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: [
          const FeedScreen(),
          const SearchScreen(), // This will be for the "Discover" tab
          const AddPostScreen(),
          const Center(child: Text('Notifications Screen')), // This will be for the "Inbox" tab
          ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid),
        ],
      ),
      bottomNavigationBar: Container(
        height: bottomNavBarHeight,
        child: CupertinoTabBar(
          backgroundColor: mobileBackgroundColor,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                color: (_page == 0) ? primaryColor : secondaryColor,
              ),
              label: 'Home',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                FontAwesomeIcons.compass, // Discover icon
                color: (_page == 1) ? primaryColor : secondaryColor,
              ),
              label: 'Discover',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: (_page == 2) ? Colors.pink : primaryColor, // Color of the middle button
                ),
                child: Icon(
                  Icons.add,
                  color: (_page == 2) ? Colors.white : Colors.black,
                ),
              ),
              label: '',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                FontAwesomeIcons.message, // Inbox icon
                color: (_page == 3) ? primaryColor : secondaryColor,
              ),
              label: 'Inbox',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: (_page == 4) ? primaryColor : secondaryColor,
              ),
              label: 'Profile',
              backgroundColor: primaryColor,
            ),
          ],
          onTap: navigationTapped,
          currentIndex: _page,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _toggleListening(context),
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
