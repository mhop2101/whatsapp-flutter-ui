import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';

class MessageReply {
  final String message;
  final bool isMe;
  final MessageEnum messageType;

  MessageReply(
      {required this.message, required this.isMe, required this.messageType});
}

final messageReplyProvider = StateProvider<MessageReply?>((ref) => null);
