import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';

import 'package:whatsapp_ui/features/status/repository/status_repository.dart';

final statusControllerProvider = Provider<StatusController>(
  (ref) => StatusController(
    statusRepository: ref.watch(statusRepositoryProvider),
    ref: ref,
  ),
);

class StatusController {
  final StatusRepository statusRepository;
  final ProviderRef ref;
  StatusController({
    required this.statusRepository,
    required this.ref,
  });

  void addStatus(File file, BuildContext context) {
    ref.watch(userDataAuthProvider).whenData((value) {
      statusRepository.uploadStatus(
          username: value!.name,
          profilePic: value.profilePic,
          phoneNumber: value.phoneNumber,
          statusImage: file,
          context: context);
    });
  }
}
