import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class WebScreenLayout extends StatefulWidget {
  const WebScreenLayout({Key? key}) : super(key: key);

  @override
  State<WebScreenLayout> createState() => _WebScreenLayoutState();
}

class _WebScreenLayoutState extends State<WebScreenLayout> {
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
    pageController.jumpToPage(page);
    setState(() {
      _page = page;
    });
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
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: false,
        title: SvgPicture.asset(
          'assets/tiktok.svg',
          color: primaryColor,
          height: 32,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: _page == 0 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(0),
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: _page == 1 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(1),
          ),
          IconButton(
            icon: Icon(
              Icons.add_a_photo,
              color: _page == 2 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(2),
          ),
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: _page == 3 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(3),
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              color: _page == 4 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(4),
          ),
        ],
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: [
          const FeedScreen(),
          const SearchScreen(),
          const AddPostScreen(),
          const Center(child: Text('Notifications Screen')),
          ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _toggleListening(context),
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
