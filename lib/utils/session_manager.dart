import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------
/// 🧠 Session Manager
/// ---------------------------------------------------------
/// Handles user session data such as userId, profileId, token, etc.
/// Works safely with null-safety and async calls.
/// ---------------------------------------------------------
class SessionManager {
  static const _keyUserId = 'user_id';
  static const _keyProfileId = 'profile_id';
  static const _keyToken = 'auth_token';
  static const _keyLoginId = 'login_id';
  static const _keyRole = 'user_role';
  static const _keyHealthcareId = 'healthcare_id';
  static const _keyHealthProfileFlag = 'health_profile_flag';
  static const _keyFreeTrialFlag = 'free_trial_flag';
  static const _keyAdminData = 'admin_data';
  static const _keyIsSubscribed = 'is_subscribed';
  static const _keySubscribedDate = 'subscribed_date';
  static const _keySubscriptionEndDate = 'subscription_end_date';

  /// ✅ Save the logged-in user's ID
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  /// ✅ Save the profile ID (if your app differentiates it)
  static Future<void> saveProfileId(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileId, profileId);
  }

  static Future<void> saveHealthcareId(String healthcareId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHealthcareId, healthcareId);
  }

  /// ✅ Save auth token (for API authorization)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  /// ✅ Save unique login session ID
  static Future<void> saveLoginId(String loginId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoginId, loginId);
  }

  /// ✅ Retrieve the stored userId
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// ✅ Retrieve stored profileId
  static Future<String?> getProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfileId);
  }

  static Future<String?> getHealthcareId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHealthcareId);
  }

  /// ✅ Retrieve stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// ✅ Retrieve login ID
  static Future<String?> getLoginId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoginId);
  }

  /// ✅ Check if a user is logged in (returns true/false)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final profileId = prefs.getString(_keyProfileId);
    final token = prefs.getString(_keyToken);
    
    final bool hasValidUser = (userId != null && userId.isNotEmpty && userId != 'null') ||
        (profileId != null && profileId.isNotEmpty && profileId != 'null');

    final bool hasValidSession = hasValidUser;

    // Log the check for debugging state issues
    // ignore: avoid_print
    print('📦 Session Check - LoggedIn: $hasValidSession (ID: $userId, ProfileID: $profileId, HasToken: ${token != null && token.isNotEmpty})');
    
    return hasValidSession;
  }

  /// 🚪 Log out and clear all stored data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyProfileId);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyLoginId);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyHealthcareId);
    await prefs.remove(_keyHealthProfileFlag);
    await prefs.remove(_keySurgeonProfileFlag);
    await prefs.remove(_keyFreeTrialFlag);
    await prefs.remove(_keyAdminData);
    await prefs.remove(_keyIsSubscribed);
    await prefs.remove(_keySubscribedDate);
    await prefs.remove(_keySubscriptionEndDate);
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_name');
  }

  static Future<void> saveHealthProfileFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHealthProfileFlag, value);
  }

  static Future<bool?> getHealthProfileFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHealthProfileFlag);
  }

  static const _keySurgeonProfileFlag = 'surgeon_profile_flag';

  static Future<void> saveSurgeonProfileFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySurgeonProfileFlag, value);
  }

  static Future<bool?> getSurgeonProfileFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySurgeonProfileFlag);
  }

  static Future<void> saveFreeTrialFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFreeTrialFlag, value);
  }

  static Future<bool?> getFreeTrialFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFreeTrialFlag);
  }

  /// 💳 Save yearly subscription status and dates
  static Future<void> saveSubscriptionDetails({
    required bool isSubscribed,
    String? startDate,
    String? endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsSubscribed, isSubscribed);
    if (startDate != null) {
      await prefs.setString(_keySubscribedDate, startDate);
    }
    if (endDate != null) {
      await prefs.setString(_keySubscriptionEndDate, endDate);
    }
    if (isSubscribed) {
      await prefs.setBool(_keyFreeTrialFlag, true);
    }
  }

  static Future<bool> getIsSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsSubscribed) ?? false;
  }

  static Future<String?> getSubscriptionEndDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySubscriptionEndDate);
  }

  /// Check whether user has active access (either active trial or valid subscription)
  static Future<bool> hasActiveAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool(_keyIsSubscribed) ?? false;
    final endDateStr = prefs.getString(_keySubscriptionEndDate);

    if (isSubscribed && endDateStr != null) {
      final endDate = DateTime.tryParse(endDateStr);
      if (endDate != null && endDate.isAfter(DateTime.now())) {
        return true;
      }
    }

    final trialFlag = prefs.getBool(_keyFreeTrialFlag);
    return trialFlag == true || trialFlag == null;
  }

  static Future<void> saveAdminData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final jsonStr = jsonEncode(data);
      await prefs.setString(_keyAdminData, jsonStr);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving admin data: $e');
    }
  }

  static Future<Map<String, dynamic>?> getAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyAdminData);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing admin data: $e');
      return null;
    }
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  /// ✅ Save profile ID for a specific user (by email)
  /// This maps user email -> their profile's actual _id
  static Future<void> saveUserProfileMapping(String email, String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_map_$email', profileId);
  }

  /// ✅ Get stored profile ID for a specific user (by email)
  static Future<String?> getUserProfileMapping(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_map_$email');
  }

  /// ✅ Save current user's email
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  /// ✅ Get current user's email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  /// ✅ Save current user's phone number
  static Future<void> saveUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', phone);
  }

  /// ✅ Get current user's phone number
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }

  /// ✅ Save current user's name
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  /// ✅ Get current user's name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  /// ✅ Save cached registered FCM token
  static const _keyRegisteredFcmToken = 'registered_fcm_token';

  static Future<void> saveRegisteredFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRegisteredFcmToken, token);
  }

  static Future<String?> getRegisteredFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRegisteredFcmToken);
  }

  static Future<void> clearRegisteredFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRegisteredFcmToken);
  }
}

