import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/models/status.dart';
import 'package:whatsapp_ui/models/user_model.dart';

final statusRepositoryProvider = Provider<StatusRepository>(
  (ref) => StatusRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    ref: ref,
  ),
);

class StatusRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final ProviderRef ref;

  StatusRepository({
    required this.firestore,
    required this.auth,
    required this.ref,
  });

  void uploadStatus({
    required String username,
    required String profilePic,
    required String phoneNumber,
    required File statusImage,
    required BuildContext context,
  }) async {
    try {
      var statusId = const Uuid().v1();
      String uid = auth.currentUser!.uid;
      String imageurl = await ref
          .read(commonFirebaseStorageRepository)
          .storeFileToFirebase('/status/$statusId$uid', statusImage);

      List<Contact> contacts = [];

      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }

      List<String> whoCanSee = [];

      for (int i = 0; i < contacts.length; i++) {
        String phoneNumber = contacts[i]
            .phones[0]
            .number
            .replaceAll(" ", "")
            .replaceAll("-", "")
            .replaceAll("(", "")
            .replaceAll(")", "");
        ;
        var userDataFirebase = await firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();
        if (userDataFirebase.docs.isNotEmpty) {
          UserModel user = UserModel.fromMap(userDataFirebase.docs[0].data());
          whoCanSee.add(user.uid);
        }
      }

      List<String> statusImageUrls = [];

      var statusSnaphot = await firestore
          .collection('status')
          .where('uid', isEqualTo: uid)
          .get();

      if (statusSnaphot.docs.isNotEmpty) {
        Status status = Status.fromMap(statusSnaphot.docs[0].data());
        statusImageUrls = status.photourl;
        statusImageUrls.add(imageurl);
        await firestore
            .collection('status')
            .doc(statusSnaphot.docs[0].id)
            .update({'photoUrl': statusImageUrls});
        return;
      } else {
        statusImageUrls = [imageurl];
      }

      Status status = Status(
          uid: uid,
          username: username,
          phoneNumber: phoneNumber,
          photourl: statusImageUrls,
          createdAt: DateTime.now(),
          profilePic: profilePic,
          statusId: statusId,
          whoCanSee: whoCanSee);

      await firestore.collection('status').doc(statusId).set(status.toMap());
    } catch (e) {
      showSnackBar(context: context, message: e.toString());
    }
  }
}
