import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/models/user_model.dart';
import 'package:whatsapp_ui/features/chat/screens/mobile_chat_screen.dart';

final selectContactRepositoryProvider = Provider<SelectContactRepository>(
    (ref) => SelectContactRepository(firestore: FirebaseFirestore.instance));

class SelectContactRepository {
  final FirebaseFirestore firestore;

  SelectContactRepository({
    required this.firestore,
  });

  Future<List<Contact>> getContacts() async {
    List<Contact> contacts = [];
    try {
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return contacts;
  }

  void selectContact(Contact selectedContact, BuildContext context) async {
    try {
      
      var userCollection = await firestore.collection("users").get();
      bool isFound = false;

      for (var user in userCollection.docs) {
        var userData = UserModel.fromMap(user.data());

        String userDataNumber =
            userData.phoneNumber.replaceAll(" ", "").replaceAll("-", "");
        String selectedContactNumber = selectedContact.phones[0].number
            .replaceAll(" ", "")
            .replaceAll("-", "")
            .replaceAll("(", "")
            .replaceAll(")", "");

        
        print(userDataNumber);
        print(selectedContactNumber);
        if (userDataNumber.contains(selectedContactNumber)) {
          isFound = true;
          Navigator.pushNamed(context, MobileChatScreen.routeName, arguments: {
            'name': userData.name,
            'uid': userData.uid,
          });
        }
      }

      if (!isFound) {
        showSnackBar(context: context, message: "User not found");
      }
    } catch (e) {
      showSnackBar(context: context, message: e.toString());
    }
  }
}
