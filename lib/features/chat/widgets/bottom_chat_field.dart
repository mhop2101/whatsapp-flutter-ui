import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:whatsapp_ui/colors.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';

class BottomChatField extends ConsumerStatefulWidget {
  final String recieverUserId;
  const BottomChatField(
    this.recieverUserId, {
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends ConsumerState<BottomChatField> {
  bool isShowSendButton = false;
  bool isLoading = false;
  bool isShowEmojiContainer = false;
  bool isRecorderInitialized = false;
  bool isRecording = false;
  FlutterSoundRecorder? _soundRecorder;
  FocusNode focusNode = FocusNode();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _soundRecorder = FlutterSoundRecorder();
    openAudioRecorder();
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
    _soundRecorder!.closeRecorder();
    isRecorderInitialized = false;
  }

  void openAudioRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _soundRecorder!.openRecorder();
    isRecorderInitialized = true;
  }

  void sendFileMessage(File file, MessageEnum messageEnum) {
    ref.read(chatControllerProvider).sendFileMessage(
          context,
          file,
          widget.recieverUserId,
          messageEnum,
        );
  }

  void selectImage() async {
    File? pickedImage = await pickImageFromGallery(context);
    if (pickedImage != null) {
      sendFileMessage(pickedImage, MessageEnum.image);
    }
  }

  void selectVideo() async {
    File? pickedVideo = await pickVideoFromGallery(context);
    if (pickedVideo != null) {
      sendFileMessage(pickedVideo, MessageEnum.video);
    }
  }

  void selectGif() async {
    final pickedGif = await pickGIF(context);
    if (pickedGif != null) {
      ref.read(chatControllerProvider).sendGifMessage(
            context,
            pickedGif.url,
            widget.recieverUserId,
          );
    }
  }

  void hideEmojiContainer() {
    setState(() {
      isShowEmojiContainer = false;
    });
  }

  void showEmojiContainer() {
    setState(() {
      isShowEmojiContainer = true;
    });
  }

  void toggleEmojiContainer() {
    if (isShowEmojiContainer) {
      showKeyboard();
      hideEmojiContainer();
    } else {
      hideKeyboard();
      showEmojiContainer();
    }
  }

  void showKeyboard() {
    focusNode.requestFocus();
  }

  void hideKeyboard() {
    focusNode.unfocus();
  }

  void sendTextMessage() async {
    if (isShowSendButton) {
      ref.read(chatControllerProvider).sendTextMessage(
          context, _messageController.text.trim(), widget.recieverUserId);
      setState(() {
        _messageController.clear();
      });
    } else {
      if (!isRecorderInitialized) {
        return;
      }
      var temporalDir = await getTemporaryDirectory();
      var path = '${temporalDir.path}/flutter_sound.aac';
      if (isRecording) {
        await _soundRecorder!.stopRecorder();
      } else {
        await _soundRecorder!.startRecorder(
          toFile: path,
          codec: Codec.aacMP4,
        );
      }
      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                focusNode: focusNode,
                controller: _messageController,
                onTap: () => hideEmojiContainer(),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      isShowSendButton = true;
                    });
                  } else {
                    setState(() {
                      isShowSendButton = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: mobileChatBoxColor,
                  prefixIcon: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () {
                            toggleEmojiContainer();
                          },
                          icon: const Icon(
                            Icons.emoji_emotions,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            selectGif();
                          },
                          icon: const Icon(
                            Icons.gif,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  suffixIcon: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () {
                            selectImage();
                          },
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            selectVideo();
                          },
                          icon: const Icon(
                            Icons.video_call,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  hintText: 'Type a message!',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5.0, right: 10, left: 2),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF128C7E),
                child: GestureDetector(
                  onTap: () {
                    sendTextMessage();
                    setState(() {
                      isShowSendButton = false;
                    });
                  },
                  child: isShowSendButton
                      ? const Icon(Icons.send, color: Colors.white)
                      : const Icon(Icons.mic, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        isShowEmojiContainer
            ? SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() {
                      _messageController.text += emoji.emoji;
                    });
                    if (_messageController.text.isNotEmpty) {
                      setState(() {
                        isShowSendButton = true;
                      });
                    }
                  },
                  onBackspacePressed: () {
                    setState(() {
                      _messageController.text = _messageController.text
                          .substring(0, _messageController.text.length - 1);
                    });
                    if (_messageController.text.isEmpty) {
                      setState(() {
                        isShowSendButton = false;
                      });
                    }
                  },
                ))
            : const SizedBox(),
      ],
    );
  }
}
