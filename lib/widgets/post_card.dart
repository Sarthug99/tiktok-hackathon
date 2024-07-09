import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/models/user.dart' as model;
import 'package:instagram_clone_flutter/providers/user_provider.dart';
import 'package:instagram_clone_flutter/resources/firestore_methods.dart';
import 'package:instagram_clone_flutter/screens/comments_screen.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/utils/global_variable.dart';
import 'package:instagram_clone_flutter/utils/utils.dart';
import 'package:instagram_clone_flutter/widgets/like_animation.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({
    Key? key,
    required this.snap,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int commentLen = 0;
  bool isLikeAnimating = false;
  VideoPlayerController? _videoPlayerController;
  bool isVideoInitialized = false;
  bool isMuted = true;

  @override
  void initState() {
    super.initState();
    fetchCommentLen();
    if (widget.snap['isVideo'] == true) {
      _videoPlayerController = VideoPlayerController.network(widget.snap['postUrl'])
        ..initialize().then((_) {
          setState(() {
            isVideoInitialized = true;
            _videoPlayerController?.setVolume(0); // Start muted
          });
        });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController?.dispose();
  }

  fetchCommentLen() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();
      commentLen = snap.docs.length;
    } catch (err) {
      showSnackBar(
        context,
        err.toString(),
      );
    }
    setState(() {});
  }

  deletePost(String postId) async {
    try {
      await FireStoreMethods().deletePost(postId);
    } catch (err) {
      showSnackBar(
        context,
        err.toString(),
      );
    }
  }

  void _playVideo() {
    if (_videoPlayerController != null && isVideoInitialized) {
      _videoPlayerController!.play();
    }
  }

  void _toggleMute() {
    if (_videoPlayerController != null && isVideoInitialized) {
      setState(() {
        isMuted = !isMuted;
        _videoPlayerController!.setVolume(isMuted ? 0 : 1);
      });
    }
  }

  void likePost() {
    final model.User user = Provider.of<UserProvider>(context, listen: false).getUser;
    FireStoreMethods().likePost(
      widget.snap['postId'].toString(),
      user.uid,
      widget.snap['likes'],
    );
    setState(() {
      isLikeAnimating = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    print("------------------------ screen height: $height, $width");
    final leftBarHeight = height * 0.072;
    final rightBarHeight = height * 0.1335;
    final barWidth = width * 0.0446;

    return VisibilityDetector(
      key: Key(widget.snap['postId']),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          _playVideo();
        } else {
          _videoPlayerController?.pause();
        }
      },
      child: Container(
        height: height - kBottomNavigationBarHeight - kToolbarHeight, // Adjust height
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: width > webScreenSize ? secondaryColor : mobileBackgroundColor,
          ),
          color: mobileBackgroundColor,
        ),
        child: Stack(
          children: [
            // VIDEO OR IMAGE SECTION
            Container(
              width: double.infinity,
              color: Colors.black,
              child: widget.snap['isVideo'] == true
                  ? _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(_videoPlayerController!),
                        )
                      : const Center(child: CircularProgressIndicator())
                  : Image.network(
                      widget.snap['postUrl'].toString(),
                      fit: BoxFit.cover,
                    ),
            ),
            // AUTHOR NAME AND CAPTION SECTION
            Positioned(
              bottom: leftBarHeight,
              left: barWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(
                                isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                                size: 16,
                              ),
                              onPressed: _toggleMute,
                            ),
                          ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(
                          widget.snap['profImage'].toString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.snap['username'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.snap['description'],
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            // LIKE, COMMENT, AND SHARE ICONS SECTION
            Positioned(
              right: barWidth,
              bottom: rightBarHeight,
              child: Column(
                children: <Widget>[
                  LikeAnimation(
                    isAnimating: widget.snap['likes'].contains(user.uid),
                    smallLike: true,
                    child: IconButton(
                      icon: widget.snap['likes'].contains(user.uid)
                          ? const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            )
                          : const Icon(
                              Icons.favorite_border,
                            ),
                      onPressed: () => likePost(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.comment_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(
                          postId: widget.snap['postId'].toString(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // LIKE ANIMATION
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isLikeAnimating ? 1 : 0,
              child: LikeAnimation(
                isAnimating: isLikeAnimating,
                duration: const Duration(
                  milliseconds: 400,
                ),
                onEnd: () {
                  setState(() {
                    isLikeAnimating = false;
                  });
                },
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
