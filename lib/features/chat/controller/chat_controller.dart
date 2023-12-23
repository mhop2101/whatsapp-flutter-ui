import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/chat/repository/chat_repository.dart';

class ChatController {
  final ChatRepository chatRepository;
  final ProviderRef ref;
  ChatController({required this.chatRepository, required this.ref});
  void sendTextMessage(BuildContext context, String text, String recieverUserId, ) {
    ref.read(userDataAuthProvider).when(data: data, error: error, loading: loading)
    chatRepository.sendTextMessage( );
  }
}
