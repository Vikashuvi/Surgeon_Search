import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
import 'package:doc/utils/app_config.dart';
import 'package:doc/services/notification_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final isLoggedIn = false.obs;
  final userRole = ''.obs;
  final profileId = ''.obs;
  final userEmail = ''.obs;
  final userName = ''.obs;
  final userPhone = ''.obs;
  final hasSurgeonProfile = false.obs;
  final hasHealthProfile = false.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  /// 🔄 Restore session from local storage on app start
  Future<void> restoreSession() async {
    isLoading.value = true;
    try {
      final loggedIn = await SessionManager.isLoggedIn();
      if (loggedIn) {
        isLoggedIn.value = true;
        userRole.value = (await SessionManager.getRole()) ?? '';
        profileId.value = (await SessionManager.getProfileId()) ?? (await SessionManager.getUserId()) ?? '';
        userEmail.value = (await SessionManager.getUserEmail()) ?? '';
        userName.value = (await SessionManager.getUserName()) ?? '';
        userPhone.value = (await SessionManager.getUserPhone()) ?? '';
        hasSurgeonProfile.value = (await SessionManager.getSurgeonProfileFlag()) ?? false;
        hasHealthProfile.value = (await SessionManager.getHealthProfileFlag()) ?? false;

        // 🔔 Re-register FCM token on session restore (handles token refresh)
        _registerFcmTokenSilently(profileId.value, userRole.value);
      } else {
        isLoggedIn.value = false;
        userRole.value = '';
        profileId.value = '';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Unified session save helper (updates reactive state & persistence)
  Future<void> saveSession({
    required String id,
    required String role,
    String? email,
    String? name,
    String? phone,
    String? token,
    bool? healthProfile,
    bool? surgeonProfile,
  }) async {
    isLoggedIn.value = true;
    userRole.value = role;
    profileId.value = id;
    
    await SessionManager.saveUserId(id);
    await SessionManager.saveProfileId(id);
    if (role.isNotEmpty) {
      await SessionManager.saveRole(role);
    }
    if (token != null) {
      await SessionManager.saveToken(token.isEmpty ? 'active_session' : token);
    } else {
      final existingToken = await SessionManager.getToken();
      if (existingToken == null || existingToken.isEmpty) {
        await SessionManager.saveToken('active_session');
      }
    }
    if (email != null && email.isNotEmpty) {
      userEmail.value = email;
      await SessionManager.saveUserEmail(email);
    }
    if (name != null && name.isNotEmpty) {
      userName.value = name;
      await SessionManager.saveUserName(name);
    }
    if (phone != null && phone.isNotEmpty) {
      userPhone.value = phone;
      await SessionManager.saveUserPhone(phone);
    }
    if (healthProfile != null) {
      hasHealthProfile.value = healthProfile;
      await SessionManager.saveHealthProfileFlag(healthProfile);
    }
    if (surgeonProfile != null) {
      hasSurgeonProfile.value = surgeonProfile;
      await SessionManager.saveSurgeonProfileFlag(surgeonProfile);
    }

    // 🔔 Register FCM token with backend after successful login
    _registerFcmTokenSilently(id, role);
  }

  /// ✅ Legacy update state helper after a successful login
  void loginSuccess({required String role, required String id}) {
    isLoggedIn.value = true;
    userRole.value = role;
    profileId.value = id;
  }

  /// 🚪 Logout and clear states
  Future<void> logout() async {
    // 🔔 Unregister FCM token before clearing session
    await _unregisterFcmToken(profileId.value);

    await SessionManager.clearAll();
    isLoggedIn.value = false;
    userRole.value = '';
    profileId.value = '';
    userEmail.value = '';
    userName.value = '';
    userPhone.value = '';
    hasSurgeonProfile.value = false;
    hasHealthProfile.value = false;
  }

  // ──────────────────────────────────────────────
  // 🔔 FCM Token Management (Private Helpers)
  // ──────────────────────────────────────────────

  /// Register FCM token with backend (fire-and-forget, cached to avoid redundant network calls)
  void _registerFcmTokenSilently(String userId, String role) {
    if (userId.isEmpty) return;

    Future(() async {
      try {
        final fcmToken = await NotificationService().getToken();
        if (fcmToken == null || fcmToken.isEmpty) {
          return;
        }

        // ✅ Check if token is already registered to avoid redundant requests
        final lastRegisteredToken = await SessionManager.getRegisteredFcmToken();
        if (lastRegisteredToken == fcmToken) {
          debugPrint('🔔 FCM token is already registered with backend (cached)');
          return;
        }

        final response = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/notifications/register-token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'token': fcmToken,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'user_role': role,
          }),
        );

        if (response.statusCode == 200) {
          await SessionManager.saveRegisteredFcmToken(fcmToken);
          debugPrint('🔔 FCM token successfully registered with backend and cached');
        } else {
          debugPrint('⚠️ FCM token registration failed: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('⚠️ FCM token registration error: $e');
      }
    });
  }

  /// Unregister FCM token from backend on logout
  Future<void> _unregisterFcmToken(String userId) async {
    if (userId.isEmpty) return;

    try {
      final fcmToken = await NotificationService().getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/unregister-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        await SessionManager.clearRegisteredFcmToken();
        debugPrint('🔕 FCM token unregistered from backend');
      } else {
        debugPrint('⚠️ FCM token unregistration failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ FCM token unregistration error: $e');
    }
  }

}
