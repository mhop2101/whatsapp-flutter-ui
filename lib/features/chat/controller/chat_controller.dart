import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/chat/repository/chat_repository.dart';
import 'package:whatsapp_ui/models/chat_contact.dart';
import 'package:whatsapp_ui/models/message.dart';

final chatControllerProvider = Provider<ChatController>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(
    chatRepository: chatRepository,
    ref: ref,
  );
});

class ChatController {
  final ChatRepository chatRepository;
  final ProviderRef ref;
  ChatController({required this.chatRepository, required this.ref});
  
  Stream<List<ChatContact>> chatContacts() {
    return chatRepository.getChatContacts();
  }

  Stream<List<Message>> chatMessages(String recieverUserId) {
    return chatRepository.getMessages(recieverUserId);
  }

  void sendTextMessage(
      BuildContext context, String text, String recieverUserId) {
    ref.read(userDataAuthProvider).whenData(
          (value) => chatRepository.sendTextMessage(
            context: context,
            text: text,
            receiverUserId: recieverUserId,
            senderUser: value!,
          ),
        );
  }

  void sendFileMessage(
    BuildContext context,
    File file,
    String recieverUserId,
    MessageEnum messageType,
  ) {
    ref.read(userDataAuthProvider).whenData(
          (value) => chatRepository.sendFileMessage(
            context: context,
            file: file,
            recieverUserId: recieverUserId,
            senderUserData: value!,
            messageType: messageType,
            ref: ref,
          ),
        );
  }

  void sendGifMessage(
    BuildContext context,
    String gifUrl,
    String recieverUserId,
  ) {
    String gifUrlPart = 'https://media.giphy.com/media/';
    int gifUrlPartIndex = gifUrl.lastIndexOf('-') + 1;
    String newGifUrl = gifUrlPart + gifUrl.substring(gifUrlPartIndex);
    newGifUrl += '/200.gif';
    ref.read(userDataAuthProvider).whenData(
          (value) => chatRepository.sendGifMessage(
            context: context,
            gifUrl: newGifUrl,
            receiverUserId: recieverUserId,
            senderUser: value!,
          ),
        );
  }

}
