import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/auth/repository/auth_repository.dart';
import 'package:whatsapp_ui/models/user_model.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  final authRepository = ref.watch(authRepositoryprovider);
  return AuthController(authRepository: authRepository, ref: ref);
});

final userDataAuthProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getUserData();
});

class AuthController {
  final AuthRepository authRepository;
  final ProviderRef ref;

  AuthController({required this.authRepository, required this.ref});

  Future<UserModel?> getUserData() async {
    UserModel? user = await authRepository.getCurrentUserData();
    return user;
  }

  void signInWithPhone(BuildContext context, String phoneNumber) {
    authRepository.signInWithPhone(context, phoneNumber);
  }

  void verifyOTP(
      {required BuildContext context,
      required String verificationId,
      required String userOTP}) {
    authRepository.verifyOTP(
        context: context, verificationId: verificationId, userOTP: userOTP);
  }

  void saveUserDataToFirebase(
      BuildContext context, String name, File? profilePic) {
    authRepository.saveUserDataToFirebase(
        name: name, profilePic: profilePic, context: context, ref: ref);
  }

  Stream<UserModel> userDataById(String uid) {
    return authRepository.userData(uid);
  }

  void setUserState(bool status) {
    authRepository.setUserState(status);
  }
}
