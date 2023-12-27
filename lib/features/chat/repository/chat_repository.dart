import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/models/chat_contact.dart';
import 'package:whatsapp_ui/models/message.dart';
import 'package:whatsapp_ui/models/user_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  return ChatRepository(
    firestore: firestore,
    auth: auth,
  );
});

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  ChatRepository({required this.firestore, required this.auth});

  void _saveDataToContactsSubCollection({
    required UserModel senderUserData,
    required UserModel recieverUserData,
    required String text,
    required DateTime timeSent,
    required String recieverUserId,
  }) async {
    // set recieverUserId chat contact
    ChatContact recieverChatContact = ChatContact(
      name: senderUserData.name,
      profilePic: senderUserData.profilePic,
      contacId: senderUserData.uid,
      timeSent: timeSent,
      lastMessage: text,
    );
    await firestore
        .collection('users')
        .doc(recieverUserId)
        .collection('chats')
        .doc(senderUserData.uid)
        .set(recieverChatContact.toMap());
    // set senderUserId chat contact
    ChatContact senderChatContact = ChatContact(
      name: recieverUserData.name,
      profilePic: recieverUserData.profilePic,
      contacId: recieverUserData.uid,
      timeSent: timeSent,
      lastMessage: text,
    );
    await firestore
        .collection('users')
        .doc(senderUserData.uid)
        .collection('chats')
        .doc(recieverUserId)
        .set(senderChatContact.toMap());
  }

  void _saveMessageToMessageSubcollection({
    required String recieverUserId,
    required String text,
    required DateTime timeSent,
    required String messageId,
    required String username,
    required String recieverUsername,
    required MessageEnum messageType,
    required MessageReply? messageReply,
    required String senderUserName,
    required String recieverUserName,
  }) async {
    final Message message = Message(
      senderId: auth.currentUser!.uid,
      receiverId: recieverUserId,
      text: text,
      type: messageType,
      timeSent: timeSent,
      messageId: messageId,
      isSeen: false,
      repliedMessage: messageReply == null ? '' : messageReply.message,
      repliedTo: messageReply == null
          ? ''
          : messageReply.isMe
              ? senderUserName
              : recieverUsername,
      repliedMessageType:
          messageReply == null ? MessageEnum.text : messageReply.messageType,
    );
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(recieverUserId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    await firestore
        .collection('users')
        .doc(recieverUserId)
        .collection('chats')
        .doc(auth.currentUser!.uid)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());
  }

  void sendTextMessage({
    required BuildContext context,
    required String text,
    required String receiverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
  }) async {
    try {
      var timeSent = DateTime.now();
      UserModel recieverUserData;
      var userDataMap =
          await firestore.collection('users').doc(receiverUserId).get();
      recieverUserData = UserModel.fromMap(userDataMap.data()!);

      var messageId = const Uuid().v1();

      _saveDataToContactsSubCollection(
        senderUserData: senderUser,
        recieverUserData: recieverUserData,
        text: text,
        timeSent: timeSent,
        recieverUserId: receiverUserId,
      );

      _saveMessageToMessageSubcollection(
        recieverUserId: receiverUserId,
        text: text,
        timeSent: timeSent,
        messageType: MessageEnum.text,
        messageId: messageId,
        recieverUsername: recieverUserData.name,
        username: senderUser.name,
        messageReply: messageReply,
        recieverUserName: recieverUserData.name,
        senderUserName: senderUser.name,
      );
    } catch (e) {
      showSnackBar(context: context, message: e.toString());
    }
  }

  void sendFileMessage({
    required BuildContext context,
    required File file,
    required String recieverUserId,
    required UserModel senderUserData,
    required ProviderRef ref,
    required MessageEnum messageType,
    required MessageReply? messageReply,
  }) async {
    try {
      DateTime timeSent = DateTime.now();
      String messageId = const Uuid().v1();
      String downloadUrl =
          await ref.read(commonFirebaseStorageRepository).storeFileToFirebase(
                'chat/${messageType.type}/${senderUserData.uid}/$recieverUserId/$messageId',
                file,
              );
      UserModel recieverUserData;
      var userDataMap =
          await firestore.collection('users').doc(recieverUserId).get();
      recieverUserData = UserModel.fromMap(userDataMap.data()!);

      String contactMsg;

      switch (messageType) {
        case MessageEnum.image:
          contactMsg = '📸 Photo';
          break;
        case MessageEnum.video:
          contactMsg = '🎥 Video';
          break;
        case MessageEnum.audio:
          contactMsg = '🎙️ Audio';
          break;
        case MessageEnum.gif:
          contactMsg = '🗾 Gif';
          break;
        default:
          contactMsg = 'Message';
      }

      _saveDataToContactsSubCollection(
        senderUserData: senderUserData,
        recieverUserData: recieverUserData,
        text: contactMsg,
        timeSent: timeSent,
        recieverUserId: recieverUserId,
      );

      _saveMessageToMessageSubcollection(
        recieverUserId: recieverUserId,
        text: downloadUrl,
        timeSent: timeSent,
        messageType: messageType,
        messageId: messageId,
        recieverUsername: recieverUserData.name,
        username: senderUserData.name,
        messageReply: messageReply,
        senderUserName: senderUserData.name,
        recieverUserName: recieverUserData.name,
      );
    } catch (e) {
      showSnackBar(context: context, message: e.toString());
    }
  }

  Stream<List<ChatContact>> getChatContacts() {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      List<ChatContact> chatContacts = [];
      for (var doc in event.docs) {
        ChatContact chatContact = ChatContact.fromMap(doc.data());
        // ignore: unused_local_variable
        UserModel userData = await firestore
            .collection('users')
            .doc(chatContact.contacId)
            .get()
            .then((value) => UserModel.fromMap(value.data()!));

        chatContacts.add(chatContact);
      }
      return chatContacts;
    });
  }

  Stream<List<Message>> getMessages(String receiverUserId) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverUserId)
        .collection('messages')
        .orderBy('timeSent', descending: false)
        .snapshots()
        .asyncMap((event) async {
      List<Message> messages = [];
      for (var doc in event.docs) {
        Message message = Message.fromMap(doc.data());
        messages.add(message);
      }
      return messages;
    });
  }

  void sendGifMessage({
    required BuildContext context,
    required String gifUrl,
    required String receiverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
  }) async {
    try {
      var timeSent = DateTime.now();
      UserModel recieverUserData;
      var userDataMap =
          await firestore.collection('users').doc(receiverUserId).get();
      recieverUserData = UserModel.fromMap(userDataMap.data()!);

      var messageId = const Uuid().v1();

      _saveDataToContactsSubCollection(
        senderUserData: senderUser,
        recieverUserData: recieverUserData,
        text: '🗾 GIF',
        timeSent: timeSent,
        recieverUserId: receiverUserId,
      );

      _saveMessageToMessageSubcollection(
        recieverUserId: receiverUserId,
        text: gifUrl,
        timeSent: timeSent,
        messageType: MessageEnum.gif,
        messageId: messageId,
        recieverUsername: recieverUserData.name,
        username: senderUser.name,
        messageReply: messageReply,
        senderUserName: senderUser.name,
        recieverUserName: recieverUserData.name,
      );
    } catch (e) {
      showSnackBar(context: context, message: e.toString());
    }
  }

  void setChatMessageSeen(
      BuildContext context, String recieverUserId, String messageId) async {
    try {
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(recieverUserId)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});
      await firestore
          .collection('users')
          .doc(recieverUserId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      showSnackBar(context: context, message: e.toString());
    }
  }
}
