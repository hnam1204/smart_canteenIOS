import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/safe_change_notifier.dart';
import '../../../models/firestore_models.dart' as store;
import '../../../repositories/user_repository.dart';
import 'user_profile_model.dart';

class PersonalInfoController extends SafeChangeNotifier {
  PersonalInfoController({UserRepository? repository})
    : _repository = repository;

  UserRepository? _repository;
  StreamSubscription<store.UserModel?>? _subscription;
  String? _uid;

  UserProfileModel? profile;
  bool loading = true;
  bool saving = false;
  bool editing = false;
  bool hasError = false;
  bool authRequired = false;
  String? errorMessage;

  Future<void> load() async {
    if (Firebase.apps.isEmpty) {
      loading = false;
      authRequired = true;
      notifyListeners();
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      loading = false;
      authRequired = true;
      notifyListeners();
      return;
    }
    _uid = user.uid;
    _repository ??= UserRepository();
    await _subscription?.cancel();
    _subscription = _repository!
        .watchUser(user.uid)
        .listen(
          (remoteProfile) {
            if (remoteProfile == null) {
              profile = null;
              loading = false;
              hasError = false;
              authRequired = false;
              notifyListeners();
              return;
            }
            profile = _fromUser(remoteProfile, user.email ?? '');
            loading = false;
            hasError = false;
            authRequired = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'PersonalInfoController load failed: $error\n$stackTrace',
            );
            loading = false;
            hasError = true;
            errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null || Firebase.apps.isEmpty) {
      loading = false;
      authRequired = true;
      notifyListeners();
      return;
    }
    try {
      final latest = await (_repository ??= UserRepository()).getUser(uid);
      if (latest != null) {
        profile = _fromUser(
          latest,
          FirebaseAuth.instance.currentUser?.email ?? '',
        );
      }
      hasError = false;
      errorMessage = null;
    } on Object catch (error, stackTrace) {
      debugPrint('PersonalInfoController refresh failed: $error\n$stackTrace');
      hasError = true;
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  void retry() {
    hasError = false;
    authRequired = false;
    loading = true;
    notifyListeners();
    unawaited(load());
  }

  void beginEdit() {
    if (profile == null) return;
    editing = true;
    notifyListeners();
  }

  void cancelEdit() {
    editing = false;
    notifyListeners();
  }

  Future<void> save(UserProfileModel updatedProfile) async {
    final uid = _uid;
    if (uid == null || Firebase.apps.isEmpty) {
      authRequired = true;
      notifyListeners();
      return;
    }
    saving = true;
    notifyListeners();
    try {
      await (_repository ??= UserRepository()).updateProfile(uid, {
        'fullName': updatedProfile.fullName,
        'email': updatedProfile.email,
        'phone': updatedProfile.phone,
        'avatarUrl': updatedProfile.avatarUrl,
        'address': updatedProfile.address,
        'studentId': updatedProfile.studentId,
        'department': updatedProfile.department,
        'note': updatedProfile.note,
        'gender': updatedProfile.gender.name,
        'dateOfBirth': Timestamp.fromDate(updatedProfile.dateOfBirth),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      profile = updatedProfile;
      hasError = false;
      errorMessage = null;
      editing = false;
    } on Object catch (error, stackTrace) {
      debugPrint('PersonalInfoController save failed: $error\n$stackTrace');
      hasError = true;
      errorMessage = error.toString();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  UserProfileModel _fromUser(store.UserModel user, String authEmail) {
    return UserProfileModel(
      uid: user.uid,
      fullName: user.fullName.isEmpty
          ? 'Người dùng Smart Canteen'
          : user.fullName,
      email: user.email.isEmpty ? authEmail : user.email,
      phone: user.phone,
      dateOfBirth: user.dateOfBirth ?? DateTime(2000),
      gender: _gender(user.gender),
      studentId: user.studentId,
      department: user.department,
      address: user.address,
      note: user.note,
      avatarVariant: 0,
      avatarUrl: user.avatarUrl,
      stats: ProfileStatsModel(
        points: user.points,
        memberTier: user.memberTier.isEmpty ? 'Đồng' : user.memberTier,
        orderCount: user.orderCount,
        totalSpent: user.totalSpent,
      ),
      securityItems: const [
        AccountSecurityModel(
          action: SecurityAction.changePassword,
          title: 'Đổi mật khẩu',
          subtitle: 'Cập nhật mật khẩu đăng nhập',
          icon: Icons.lock_outline_rounded,
        ),
        AccountSecurityModel(
          action: SecurityAction.loginActivity,
          title: 'Đăng nhập gần đây',
          subtitle: 'Xem thiết bị đã đăng nhập',
          icon: Icons.devices_outlined,
        ),
      ],
    );
  }

  Gender _gender(String value) {
    return switch (value.trim()) {
      'male' => Gender.male,
      'female' => Gender.female,
      _ => Gender.other,
    };
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
