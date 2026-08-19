import 'package:get/get.dart';
import 'package:doc/utils/session_manager.dart';

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
  }

  /// ✅ Legacy update state helper after a successful login
  void loginSuccess({required String role, required String id}) {
    isLoggedIn.value = true;
    userRole.value = role;
    profileId.value = id;
  }

  /// 🚪 Logout and clear states
  Future<void> logout() async {
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
}
