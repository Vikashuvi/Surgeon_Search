// ignore_for_file: unused_element, unused_field, unused_import
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:doc/healthcare/hospial_form.dart';
import 'package:doc/navbar.dart';
import 'package:doc/profileprofile/surgeon_form.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';
import 'package:doc/model/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/screens/signup_screen.dart';
import 'package:doc/screens/forgot_password_screen.dart';
import 'package:doc/admin/admin_navbar.dart';
import 'package:doc/utils/app_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:doc/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="2443" height="2500" preserveAspectRatio="xMidYMid" viewBox="0 0 256 262">
  <path fill="#4285F4" d="M255.878 133.451c0-10.734-.871-18.567-2.756-26.69H130.55v48.448h71.947c-1.45 12.04-9.283 30.172-26.69 42.356l-.244 1.622 38.755 30.023 2.685.268c24.659-22.774 38.875-56.282 38.875-96.027"></path>
  <path fill="#34A853" d="M130.55 261.1c35.248 0 64.839-11.605 86.453-31.622l-41.196-31.913c-11.024 7.688-25.82 13.055-45.257 13.055-34.523 0-63.824-22.773-74.269-54.25l-1.531.13-40.298 31.187-.527 1.465C35.393 231.798 79.49 261.1 130.55 261.1"></path>
  <path fill="#FBBC05" d="M56.281 156.37c-2.756-8.123-4.351-16.827-4.351-25.82 0-8.994 1.595-17.697 4.206-25.82l-.073-1.73L15.26 71.312l-1.335.635C5.077 89.644 0 109.517 0 130.55s5.077 40.905 13.925 58.602l42.356-32.782"></path>
  <path fill="#EB4335" d="M130.55 50.479c24.514 0 41.05 10.589 50.479 19.438l36.844-35.974C195.245 12.91 165.798 0 130.55 0 79.49 0 35.393 29.301 13.925 71.947l42.211 32.783c10.59-31.477 39.891-54.251 74.414-54.251"></path>
</svg>''';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? '692027562141-g1i83eh2gdq3kkck0qo8b6bemerj6vfn.apps.googleusercontent.com' : null,
    serverClientId: '692027562141-g1i83eh2gdq3kkck0qo8b6bemerj6vfn.apps.googleusercontent.com',
  );

  String? _extractProfileId(dynamic source) {
    if (source == null) return null;

    String? normalize(dynamic value) {
      if (value == null) return null;
      if (value is Map && value.containsKey(r'$oid')) {
        final oidValue = value[r'$oid'];
        final oidString = oidValue?.toString().trim();
        if (oidString != null && oidString.isNotEmpty) return oidString;
      }
      final stringValue = value.toString().trim();
      return stringValue.isEmpty ? null : stringValue;
    }

    final keysToCheck = const {
      'profile_id',
      'profileId',
      'profileID',
      '_id',
      'id',
      'user_id',
      'userId',
      'doctor_id',
      'doctorId',
    };

    if (source is Map) {
      for (final entry in source.entries) {
        if (keysToCheck.contains(entry.key)) {
          final normalized = normalize(entry.value);
          if (normalized != null) return normalized;
        }

        if (entry.value is Map || entry.value is Iterable) {
          final nested = _extractProfileId(entry.value);
          if (nested != null) return nested;
        } else {
          final normalized = normalize(entry.value);
          if (normalized != null && keysToCheck.any(entry.key.toLowerCase().contains)) {
            return normalized;
          }
        }
      }
    } else if (source is Iterable) {
      for (final item in source) {
        final nested = _extractProfileId(item);
        if (nested != null) return nested;
      }
    } else {
      final normalized = normalize(source);
      if (normalized != null) return normalized;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _prewarmServer();
  }

  /// Wake up backend (Render) to prevent cold start delay
  Future<void> _prewarmServer() async {
    try {
      // Use root path which always exists and still wakes the instance
      await http
          .get(Uri.parse('${AppConfig.serverUrl}/'))

          .timeout(const Duration(seconds: 8));
      debugPrint(' Server is awake');
    } catch (_) {
      debugPrint(' Could not prewarm server.');
    }
  }

  /// Helper: POST with retries/backoff to tolerate cold starts or transient TLS drops
  Future<http.Response> _postWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int attempts = 3,
  }) async {
    final delays = <Duration>[
      Duration.zero,
      const Duration(seconds: 2),
      const Duration(seconds: 5),
    ];

    for (var i = 0; i < attempts; i++) {
      try {
        return await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));
      } on TimeoutException catch (_) {
        if (i == attempts - 1) rethrow;
      } on SocketException catch (_) {
        if (i == attempts - 1) rethrow;
      } on HandshakeException catch (_) {
        if (i == attempts - 1) rethrow;
      }
      // Backoff before next try
      await Future.delayed(delays[i]);
    }
    // Should never reach here
    throw Exception('Request failed after retries');
  }

  /// LOGIN FUNCTION
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    final url = Uri.parse('${AppConfig.apiBaseUrl}/signin');

    const uuid = Uuid();

    try {
      final response = await _postWithRetry(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final root = jsonDecode(response.body);
        final data = root is Map && root['data'] != null ? root['data'] : root;
        debugPrint(' Login successful: $data');

        final token = (data is Map) ? data['token'] : null;
        final userData = (data is Map)
            ? (data['user'] ?? data['profile'] ?? data)
            : data;

        String? role = (userData is Map)
            ? (userData['type'] ?? userData['role'] ?? (data is Map ? (data['type'] ?? data['role']) : null))?.toString()
            : null;

        bool healthProfile = false;
        bool surgeonProfile = false;
        if (userData is Map) {
          final rawHp = userData['healthprofile'] ?? userData['healthProfile'];
          if (rawHp is bool) {
            healthProfile = rawHp;
          } else if (rawHp is String) {
            healthProfile = rawHp.toLowerCase() == 'true';
          }
          final rawSp = userData['surgeonprofile'] ?? userData['surgeonProfile'];
          if (rawSp is bool) {
            surgeonProfile = rawSp;
          } else if (rawSp is String) {
            surgeonProfile = rawSp.toLowerCase() == 'true';
          }
        } else if (data is Map) {
          final rawHp = data['healthprofile'] ?? data['healthProfile'];
          if (rawHp is bool) {
            healthProfile = rawHp;
          } else if (rawHp is String) {
            healthProfile = rawHp.toLowerCase() == 'true';
          }
          final rawSp = data['surgeonprofile'] ?? data['surgeonProfile'];
          if (rawSp is bool) {
            surgeonProfile = rawSp;
          } else if (rawSp is String) {
            surgeonProfile = rawSp.toLowerCase() == 'true';
          }
        }


        // Extract or create profile ID
        final extractedProfileId = _extractProfileId(userData) ??
            (data is Map ? _extractProfileId(data['profile']) : null) ??
            _extractProfileId(data);
        String profileId = (extractedProfileId ??
                (userData is Map ? userData['_id']?.toString() : null) ??
                (userData is Map ? userData['profile_id']?.toString() : null) ??
                (userData is Map ? userData['id']?.toString() : null) ??
                '')
            .trim();
        if (profileId.isEmpty) profileId = uuid.v4();

        await _handleLoginSuccess(data, userData, token, role, healthProfile, surgeonProfile, profileId, email);
      } else {
        String message = 'Invalid credentials';
        try {
          final error = jsonDecode(response.body);
          if (error is Map && error['message'] != null) {
            message = error['message'];
          }
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ $message')));
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⏳ Server is taking too long to respond. Please try again.')));
    } on HandshakeException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🔒 Secure connection failed. Check date/time, VPN/proxy, or try a different network.')));
    } on SocketException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('📡 Network error. Check your internet connection and try again.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      setState(() => _isLoading = true);

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken ?? googleAuth.accessToken;
      final String? accessToken = googleAuth.accessToken;

      final url = Uri.parse('${AppConfig.apiBaseUrl}/google-signin');
      final response = await _postWithRetry(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': googleUser.email,
          'fullname': googleUser.displayName,
          'googleId': googleUser.id,
          'idToken': idToken,
          'accessToken': accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final root = jsonDecode(response.body);
        final data = root is Map && root['data'] != null ? root['data'] : root;

        final token = (data is Map) ? data['token'] : null;
        final userData = (data is Map)
            ? (data['user'] ?? data['profile'] ?? data)
            : data;

        String? role = (userData is Map)
            ? (userData['type'] ?? userData['role'] ?? (data is Map ? (data['type'] ?? data['role']) : null))?.toString()
            : null;

        bool healthProfile = false;
        bool surgeonProfile = false;
        if (userData is Map) {
          final rawHp = userData['healthprofile'] ?? userData['healthProfile'];
          if (rawHp is bool) {
            healthProfile = rawHp;
          } else if (rawHp is String) {
            healthProfile = rawHp.toLowerCase() == 'true';
          }
          final rawSp = userData['surgeonprofile'] ?? userData['surgeonProfile'];
          if (rawSp is bool) {
            surgeonProfile = rawSp;
          } else if (rawSp is String) {
            surgeonProfile = rawSp.toLowerCase() == 'true';
          }
        }

        final extractedProfileId = _extractProfileId(userData) ??
            (data is Map ? _extractProfileId(data['profile']) : null) ??
            _extractProfileId(data);

        String profileId = (extractedProfileId ??
                (userData is Map ? userData['_id']?.toString() : null) ??
                '')
            .trim();
        if (profileId.isEmpty) profileId = const Uuid().v4();

        await _handleLoginSuccess(data, userData, token, role, healthProfile, surgeonProfile, profileId, googleUser.email);

      } else {
        String message = 'Google Sign-In failed';
        try {
          final error = jsonDecode(response.body);
          if (error is Map && error['message'] != null) {
            message = error['message'];
          }
        } catch (_) {}

        if (!mounted) return;
        
        // If Google user is not found on backend login check, redirect to SignUpScreen with feedback
        if (message.toLowerCase().contains('not found') || 
            message.toLowerCase().contains('internal server error') || 
            response.statusCode == 404 || 
            response.statusCode == 500) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account not found. Redirecting to Sign Up...'),
              backgroundColor: Colors.blueAccent,
            )
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SignUpScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $message'),
              backgroundColor: Colors.redAccent,
            )
          );
        }
      }
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      if (!mounted) return;
      
      String errStr = error.toString();
      if (errStr.contains('10') || errStr.contains('DEVELOPER_ERROR') || errStr.contains('ApiException')) {
        errStr = 'SHA-1 fingerprint missing in Firebase Console for this build.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Google Sign-In: $errStr'),
          duration: const Duration(seconds: 4),
        )
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLoginSuccess(
    dynamic data,
    dynamic userData,
    String? token,
    String? role,
    bool healthProfile,
    bool surgeonProfile,
    String profileId,
    String email,
  ) async {
    String? phone;
    String? name;
    if (userData is Map) {
      phone = (userData['phoneNumber'] ??
              userData['phone'] ??
              userData['mobile'] ??
              userData['mobileNumber'] ??
              userData['mobilenumber'])
          ?.toString();

      name = (userData['fullName'] ??
              userData['fullname'] ??
              userData['name'] ??
              userData['username'] ??
              userData['full_name'])
          ?.toString();
    }

    // Save session using unified AuthController helper
    await AuthController.to.saveSession(
      id: profileId,
      role: role ?? '',
      email: email,
      name: name,
      phone: phone,
      token: token,
      healthProfile: healthProfile,
      surgeonProfile: surgeonProfile,
    );

    // Save free trial status directly from login response
    if (userData is Map && userData['freetrail2month'] != null) {
      final isFree = userData['freetrail2month'].toString().toLowerCase() == 'true';
      await SessionManager.saveFreeTrialFlag(isFree);
    } else if (data is Map && data['freetrail2month'] != null) {
      final isFree = data['freetrail2month'].toString().toLowerCase() == 'true';
      await SessionManager.saveFreeTrialFlag(isFree);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(' Login Successful!')));

    final rl = (role ?? '').toLowerCase().trim();

    // Check if user is Admin and redirect to Admin Dashboard
    if (rl.contains('admin')) {
      // Build admin data from response
      final adminData = <String, dynamic>{};
      if (userData is Map) {
        adminData.addAll(Map<String, dynamic>.from(userData));
      }
      if (data is Map) {
        // Add any missing fields from data
        data.forEach((key, value) {
          if (!adminData.containsKey(key)) {
            adminData[key] = value;
          }
        });
      }

      await SessionManager.saveAdminData(adminData);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminNavbar(adminData: adminData),
        ),
      );
    } else if (rl.contains('hospital') || rl.contains('health') || rl.contains('org')) {
      // Extract primary healthcare ID from signin response
      String? healthcareId;

      if (userData is Map) {
        final raw = (userData['_id'] ??
                userData['healthcare_id'] ??
                userData['healthcareId'] ??
                userData['healthcareID'] ??
                userData['id'])
            ?.toString()
            .trim();
        if (raw != null && raw.isNotEmpty) {
          healthcareId = raw;
        }
      }

      if ((healthcareId == null || healthcareId.isEmpty) && data is Map) {
        final raw = (data['_id'] ??
                data['healthcare_id'] ??
                data['healthcareId'] ??
                data['healthcareID'] ??
                data['id'])
            ?.toString()
            .trim();
        if (raw != null && raw.isNotEmpty) {
          healthcareId = raw;
        }
      }

      if (healthcareId != null && healthcareId.isNotEmpty) {
        await SessionManager.saveHealthcareId(healthcareId);
      }

      // Existing hospital user: healthprofile == true
      if (healthProfile) {
        if (healthcareId == null || healthcareId.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to determine hospital ID.')),
          );
          return;
        }

        try {
          final url = Uri.parse(
              '${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$healthcareId');

          final resp = await http.get(url).timeout(const Duration(seconds: 10));

          if (resp.statusCode == 200) {
            final body = resp.body.trimLeft();
            dynamic parsed;
            try {
              parsed = jsonDecode(body);
            } catch (_) {
              parsed = {};
            }

            final payload =
                (parsed is Map && parsed['data'] != null) ? parsed['data'] : parsed;
            final mapPayload =
                (payload is Map<String, dynamic>) ? payload : <String, dynamic>{};

            final navHospitalData = Map<String, dynamic>.from(mapPayload);
            navHospitalData['healthcare_id'] = healthcareId;

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Navbar(hospitalData: navHospitalData),
              ),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Could not load hospital profile. Please try again.'),
              ),
            );
          }
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not load hospital profile. Please try again.'),
            ),
          );
        }
      } else {
        // New hospital user (no completed health profile) -> go to HospitalForm
        final idForForm = (healthcareId != null && healthcareId.isNotEmpty)
            ? healthcareId
            : profileId;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HospitalForm(healthcareId: idForForm),
          ),
        );
      }
    } else if (rl.contains('surgeon') || rl.contains('doctor')) {
      if (surgeonProfile) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfessionalProfileViewPage(
              profileId: profileId,
            ),
          ),
        );
        return;
      }

      try {
        final res = await ApiService.fetchProfileInfo(profileId);
        if (!mounted) return;
        if (res['success'] == true) {
          final body = res['data'];
          final data = body is Map && body['data'] != null ? body['data'] : body;
          final p = data is Map && data['profile'] != null ? data['profile'] : data;

          // ✅ Save Free Trial Flag if present
          if (p is Map) {
            final freeTrial = p['freetrail2month'];
            if (freeTrial != null) {
              final isFree = freeTrial.toString().toLowerCase() == 'true';
              await SessionManager.saveFreeTrialFlag(isFree);
            }
          }

          if (!mounted) return;
          final hasValidProfile = p is Map &&
              (((p['fullName'] ?? p['fullname'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty ==
                      true) ||
                  (p['email']?.toString().trim().isNotEmpty == true) ||
                  (p['phoneNumber']?.toString().trim().isNotEmpty == true));

          if (hasValidProfile) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProfessionalProfileViewPage(
                  profileId: profileId,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SurgeonForm(
                  profileId: profileId,
                  existingData: const {},
                ),
              ),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SurgeonForm(
                profileId: profileId,
                existingData: const {},
              ),
            ),
          );
        }
      } catch (_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SurgeonForm(
              profileId: profileId,
              existingData: const {},
            ),
          ),
        );
      }
    } else {
      // Default to Surgeon profile flow if role is unknown
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SurgeonForm(
            profileId: profileId,
            existingData: const {},
          ),
        ),
      );
    }
  }


  

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text.rich(
                    TextSpan(
                      text: "Let’s ",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  Center(child: Image.asset('assets/logo2.png', height: 150)),
                  const SizedBox(height: 60),

                  // 📨 Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Iconsax.sms, size: 20),
                      hintText: 'Your email',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔒 Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Iconsax.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Iconsax.eye_slash : Iconsax.eye,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                      hintText: 'Your password',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),

                  // 🔗 Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔘 Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  // const SizedBox(height: 20),

                  // // 🔹 OR divider (Temporarily commented for future use)
                  // const Row(
                  //   children: [
                  //     Expanded(child: Divider(color: Colors.black12)),
                  //     Padding(
                  //       padding: EdgeInsets.symmetric(horizontal: 10),
                  //       child: Text("OR", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  //     ),
                  //     Expanded(child: Divider(color: Colors.black12)),
                  //   ],
                  // ),
                  // const SizedBox(height: 20),

                  // // 🔘 Google Sign In Button (Temporarily commented for future use)
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 55,
                  //   child: OutlinedButton.icon(
                  //     style: OutlinedButton.styleFrom(
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //       ),
                  //       side: const BorderSide(color: Colors.black12),
                  //     ),
                  //     onPressed: _isLoading ? null : _handleGoogleSignIn,
                  //     icon: SvgPicture.string(
                  //       LoginScreen._googleSvg,
                  //       height: 22,
                  //     ),
                  //     label: const Text(
                  //       'Continue with Google',
                  //       style: TextStyle(
                  //         color: Colors.black87,
                  //         fontWeight: FontWeight.w600,
                  //         fontSize: 16,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 20),

                  // 🔗 Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don’t have an account?",
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF003366),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ⏳ Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}