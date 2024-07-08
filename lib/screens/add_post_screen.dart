import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone_flutter/providers/user_provider.dart';
import 'package:instagram_clone_flutter/resources/firestore_methods.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  Uint8List? _file;
  XFile? _videoFile;
  bool isLoading = false;
  final TextEditingController _descriptionController = TextEditingController();
  VideoPlayerController? _videoPlayerController;

  @override
  void dispose() {
    super.dispose();
    _descriptionController.dispose();
    _videoPlayerController?.dispose();
  }

  _selectImage(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Create a Post'),
          children: <Widget>[
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Take a photo'),
              onPressed: () async {
                Navigator.pop(context);
                Uint8List file = await pickImage(ImageSource.camera);
                setState(() {
                  _file = file;
                  _videoFile = null;
                  _videoPlayerController?.dispose();
                  _videoPlayerController = null;
                });
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Take a video'),
              onPressed: () async {
                Navigator.of(context).pop();
                XFile video = await pickVideo(ImageSource.camera);
                _videoPlayerController = VideoPlayerController.file(File(video.path));
                await _videoPlayerController!.initialize();
                setState(() {
                  _videoFile = video;
                  _file = null;
                });
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Choose photo from gallery'),
              onPressed: () async {
                Navigator.of(context).pop();
                Uint8List? file = await pickImageFromGallery();
                if (file != null) {
                  setState(() {
                    _file = file;
                    _videoFile = null;
                    _videoPlayerController?.dispose();
                    _videoPlayerController = null;
                  });
                }
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Choose video from gallery'),
              onPressed: () async {
                Navigator.of(context).pop();
                XFile? video = await pickVideoFromGallery();
                if (video != null) {
                  _videoPlayerController = VideoPlayerController.file(File(video.path));
                  await _videoPlayerController!.initialize();
                  setState(() {
                    _videoFile = video;
                    _file = null;
                  });
                }
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  void postImage(String uid, String username, String profImage) async {
    setState(() {
      isLoading = true;
    });
    try {
      String res;
      if (_file != null) {
        res = await FireStoreMethods().uploadPost(
          _descriptionController.text,
          _file!,
          uid,
          username,
          profImage,
          isVideo: false,
          showJobCompleteDialog: (postId, result) => _showJobCompleteDialog(context, postId, result),
        );
      } else if (_videoFile != null) {
        res = await FireStoreMethods().uploadPost(
          _descriptionController.text,
          await _videoFile!.readAsBytes(),
          uid,
          username,
          profImage,
          isVideo: true,
          showJobCompleteDialog: (postId, result) => _showJobCompleteDialog(context, postId, result),
        );
      } else {
        res = "No file selected";
      }

      if (res == "success") {
        setState(() {
          isLoading = false;
        });
        if (context.mounted) {
          showSnackBar(
            context,
            'Posted!',
          );
        }
        clearMedia();
      } else {
        if (context.mounted) {
          showSnackBar(context, res);
        }
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(
        context,
        err.toString(),
      );
    }
  }

  void clearMedia() {
    setState(() {
      _file = null;
      _videoFile = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    });
  }

  void _showJobCompleteDialog(BuildContext context, String postId, Map<String, dynamic>? result) {
    String resultText = "Accessibility Report";
    if (result != null) {
      resultText = "Accessibility Report\n";
      if (result.containsKey('Number of Contrast Errors')) {
        resultText += "Number of Contrast Errors: ${result['Number of Contrast Errors']}\n";
      }
      if (result.containsKey('Number of Violations')) {
        resultText += "Number of Violations: ${result['Number of Violations']}\n";
      }
      if (result.containsKey('Risk Level')) {
        resultText += "Risk Level: ${result['Risk Level']}\n";
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Job Complete'),
        content: Text(resultText),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);

    return _file == null && _videoFile == null
        ? Center(
            child: IconButton(
              icon: const Icon(
                Icons.upload,
              ),
              onPressed: () => _selectImage(context),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: clearMedia,
              ),
              title: const Text(
                'Post to',
              ),
              centerTitle: false,
              actions: <Widget>[
                TextButton(
                  onPressed: () => postImage(
                    userProvider.getUser.uid,
                    userProvider.getUser.username,
                    userProvider.getUser.photoUrl,
                  ),
                  child: const Text(
                    "Post",
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  ),
                )
              ],
            ),
            // POST FORM
            body: Column(
              children: <Widget>[
                isLoading
                    ? const LinearProgressIndicator()
                    : const Padding(padding: EdgeInsets.only(top: 0.0)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        userProvider.getUser.photoUrl,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                            hintText: "Write a caption...",
                            border: InputBorder.none),
                        maxLines: 8,
                      ),
                    ),
                    _file != null
                        ? SizedBox(
                            height: 45.0,
                            width: 45.0,
                            child: AspectRatio(
                              aspectRatio: 487 / 451,
                              child: Container(
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                  fit: BoxFit.fill,
                                  alignment: FractionalOffset.topCenter,
                                  image: MemoryImage(_file!),
                                )),
                              ),
                            ),
                          )
                        : _videoFile != null
                            ? SizedBox(
                                height: 45.0,
                                width: 45.0,
                                child: AspectRatio(
                                  aspectRatio: 487 / 451,
                                  child: VideoPlayer(_videoPlayerController!),
                                ),
                              )
                            : Container(),
                  ],
                ),
                const Divider(),
              ],
            ),
          );
  }

  Future<Uint8List?> pickImageFromGallery() async {
    final ImagePicker _picker = ImagePicker();
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return await image.readAsBytes();
    }
    return null;
  }

  Future<XFile?> pickVideoFromGallery() async {
    final ImagePicker _picker = ImagePicker();
    return await _picker.pickVideo(source: ImageSource.gallery);
  }

  Future<XFile> pickVideo(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    XFile? video = await _picker.pickVideo(source: source);
    if (video == null) {
      throw Exception("No video selected");
    }
    return video;
  }
}
