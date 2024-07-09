import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/utils/global_variable.dart';
import 'package:instagram_clone_flutter/widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  static final ScrollController scrollController = ScrollController();

  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double appBarHeight = screenHeight * 0.05;

    return Scaffold(
      backgroundColor:
          width > webScreenSize ? webBackgroundColor : mobileBackgroundColor,
      appBar: width > webScreenSize
          ? null
          : AppBar(
              toolbarHeight: appBarHeight,
              backgroundColor: mobileBackgroundColor,
              centerTitle: true, // Center the title content horizontally
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/tiktok.svg',
                    color: primaryColor,
                    height: 32,
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'For You',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // Placeholder to balance the space taken by the messenger icon on the right
                  SizedBox(width: 32), 
                ],
              )
            ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView.builder(
            controller: FeedScreen.scrollController,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, index) { 
              final postHeight = MediaQuery.of(context).size.height - kBottomNavigationBarHeight - kToolbarHeight;

              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: width > webScreenSize ? width * 0.3 : 0,
                  vertical: width > webScreenSize ? 15 : 0,
                ),
                child: SizedBox(
                  height: postHeight,
                  child: PostCard(
                    snap: snapshot.data!.docs[index].data(),
                  ),
                ),
              );
            }
          );
        },
      ),
    );
  }
}
