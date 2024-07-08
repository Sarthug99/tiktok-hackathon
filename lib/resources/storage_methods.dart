import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Adding image to Firebase Storage
  Future<String> uploadImageToStorage(String childName, Uint8List file, bool isPost) async {
    // Creating location in Firebase Storage
    Reference ref = _storage.ref().child(childName).child(_auth.currentUser!.uid);
    if (isPost) {
      String id = const Uuid().v1();
      ref = ref.child(id);
    }

    // Uploading in Uint8List format -> Upload task like a future but not future
    UploadTask uploadTask = ref.putData(file);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // Adding video to Firebase Storage
  Future<String> uploadVideoToStorage(String childName, Uint8List file) async {
    // Creating location in Firebase Storage
    Reference ref = _storage.ref().child(childName).child(_auth.currentUser!.uid).child(const Uuid().v1());

    // Uploading in Uint8List format -> Upload task like a future but not future
    UploadTask uploadTask = ref.putData(file);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
