import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/features/chat/widgets/my_message_card.dart';
import 'package:whatsapp_ui/features/chat/widgets/sender_message_card.dart';
import 'package:whatsapp_ui/models/message.dart';

class ChatList extends ConsumerStatefulWidget {
  final String recieverUserId;
  const ChatList({required this.recieverUserId, Key? key}) : super(key: key);

  @override
  ConsumerState<ChatList> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void onMessageSwipe(
    String message,
    bool isMe,
    MessageEnum messageType,
  ) {
    ref.read(messageReplyProvider.state).update((state) =>
        MessageReply(message: message, isMe: isMe, messageType: messageType));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
        stream: ref.read(chatControllerProvider).chatMessages(
              widget.recieverUserId,
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          SchedulerBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });

          return ListView.builder(
            controller: _scrollController,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final Message message = snapshot.data![index];
              if (!message.isSeen &&
                  message.receiverId != widget.recieverUserId) {
                ref.read(chatControllerProvider).setChatMessageSeen(
                      context,
                      widget.recieverUserId,
                      message.messageId,
                    );
              }
              if (message.receiverId == widget.recieverUserId) {
                return MyMessageCard(
                  message: message.text,
                  date: DateFormat.Hm().format(message.timeSent),
                  messageType: message.type,
                  replyText: message.repliedMessage,
                  username: message.repliedTo,
                  repliedMessageType: message.repliedMessageType,
                  onLeftSwipe: (() =>
                      onMessageSwipe(message.text, true, message.type)),
                  isSeen: message.isSeen,
                );
              }
              return SenderMessageCard(
                message: message.text,
                date: DateFormat.Hm().format(message.timeSent),
                messageType: message.type,
                replyText: message.repliedMessage,
                username: message.repliedTo,
                repliedMessageType: message.repliedMessageType,
                onRightSwipe: (() =>
                    onMessageSwipe(message.text, false, message.type)),
              );
            },
          );
        });
  }
}
