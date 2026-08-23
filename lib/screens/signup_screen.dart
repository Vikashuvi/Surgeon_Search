// ignore_for_file: unused_import

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:doc/screens/signin_screen.dart';
import 'package:doc/screens/otp_screen.dart';
import 'package:doc/utils/app_config.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:doc/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:doc/profileprofile/surgeon_form.dart';
import 'package:doc/healthcare/hospial_form.dart';
import 'package:doc/navbar.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';
import 'package:doc/model/api_service.dart';
import 'dart:async';
import 'dart:io';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="2443" height="2500" preserveAspectRatio="xMidYMid" viewBox="0 0 256 262">
  <path fill="#4285F4" d="M255.878 133.451c0-10.734-.871-18.567-2.756-26.69H130.55v48.448h71.947c-1.45 12.04-9.283 30.172-26.69 42.356l-.244 1.622 38.755 30.023 2.685.268c24.659-22.774 38.875-56.282 38.875-96.027"></path>
  <path fill="#34A853" d="M130.55 261.1c35.248 0 64.839-11.605 86.453-31.622l-41.196-31.913c-11.024 7.688-25.82 13.055-45.257 13.055-34.523 0-63.824-22.773-74.269-54.25l-1.531.13-40.298 31.187-.527 1.465C35.393 231.798 79.49 261.1 130.55 261.1"></path>
  <path fill="#FBBC05" d="M56.281 156.37c-2.756-8.123-4.351-16.827-4.351-25.82 0-8.994 1.595-17.697 4.206-25.82l-.073-1.73L15.26 71.312l-1.335.635C5.077 89.644 0 109.517 0 130.55s5.077 40.905 13.925 58.602l42.356-32.782"></path>
  <path fill="#EB4335" d="M130.55 50.479c24.514 0 41.05 10.589 50.479 19.438l36.844-35.974C195.245 12.91 165.798 0 130.55 0 79.49 0 35.393 29.301 13.925 71.947l42.211 32.783c10.59-31.477 39.891-54.251 74.414-54.251"></path>
</svg>''';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedRole = "Surgeon";
  bool _obscurePassword = true;
  bool isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? '692027562141-g1i83eh2gdq3kkck0qo8b6bemerj6vfn.apps.googleusercontent.com' : null,
    serverClientId: '692027562141-g1i83eh2gdq3kkck0qo8b6bemerj6vfn.apps.googleusercontent.com',
  );

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  


  // ✅ Two roles only
  final List<String> roles = ["Healthcare Organizations", "Surgeon"];

  /// ✅ SIGNUP API FUNCTION
  Future<void> signUpUser() async {
    if (!_formKey.currentState!.validate()) return;

    final roleToUse = selectedRole ?? "Surgeon";

    setState(() => isLoading = true);

    final String apiUrl = "${AppConfig.apiBaseUrl}/signup";

    // ✅ Use MultipartRequest if image is selected, otherwise normal POST
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullname": nameController.text.trim(),
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "mobilenumber": phoneController.text.trim(),
          "mobile": phoneController.text.trim(),
          "password": passwordController.text.trim(),
          "type": roleToUse,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Signup Successful: ${responseData['message'] ?? 'Welcome!'}",
            ),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Navigate to OTP screen
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(email: emailController.text.trim()),
            ),
          );
        });
      } else {
        // Show specific backend error
        String errorMessage = "Signup failed";
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['error'] ??
              error['message'] ??
              "Server Error (${response.statusCode})";
        } catch (_) {
          errorMessage = "Unexpected response (${response.statusCode})";
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network Error: ${e.toString()}"),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
      await Future.delayed(delays[i]);
    }
    throw Exception('Request failed after retries');
  }

  Future<void> _handleGoogleSignIn() async {
    if (isLoading) return;
    
    final roleToUse = selectedRole ?? "Surgeon";
    
    try {
      // Force account selection by signing out first
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      setState(() => isLoading = true);

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
          'type': roleToUse,
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

        final effectiveRole = (role != null && role.isNotEmpty) ? role : roleToUse;
        await AuthController.to.saveSession(
          id: profileId,
          role: effectiveRole,
          email: googleUser.email,
          name: googleUser.displayName,
          token: token,
          healthProfile: healthProfile,
          surgeonProfile: surgeonProfile,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In Successful!'))
        );

        // Route based on the user's role and profile completion status
        final rl = effectiveRole.toLowerCase().trim();
        if (rl.contains('hospital') || rl.contains('health') || rl.contains('org')) {
          await SessionManager.saveHealthcareId(profileId);
          
          if (healthProfile) {
            // Existing hospital user -> go to Navbar/Dashboard
            try {
              final url = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$profileId');
              final resp = await http.get(url).timeout(const Duration(seconds: 10));
              if (resp.statusCode == 200) {
                final parsed = jsonDecode(resp.body);
                final payload = (parsed is Map && parsed['data'] != null) ? parsed['data'] : parsed;
                final mapPayload = (payload is Map<String, dynamic>) ? payload : <String, dynamic>{};
                final navHospitalData = Map<String, dynamic>.from(mapPayload);
                navHospitalData['healthcare_id'] = profileId;
                
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Navbar(hospitalData: navHospitalData)));
                return;
              }
            } catch (_) {}
          }
          
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HospitalForm(healthcareId: profileId)));
        } else {
          // Surgeon
          if (surgeonProfile) {
            if (!mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfessionalProfileViewPage(profileId: profileId)));
            return;
          }
          
          // Double check with API if flag is false
          try {
            final res = await ApiService.fetchProfileInfo(profileId);
            if (res['success'] == true) {
              final pBody = res['data'];
              final pData = pBody is Map && pBody['data'] != null ? pBody['data'] : pBody;
              final p = pData is Map && pData['profile'] != null ? pData['profile'] : pData;
              
              final hasValidProfile = p is Map &&
                  (((p['fullName'] ?? p['fullname'] ?? '').toString().trim().isNotEmpty == true) ||
                  (p['email']?.toString().trim().isNotEmpty == true));
                  
              if (hasValidProfile) {
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfessionalProfileViewPage(profileId: profileId)));
                return;
              }
            }
          } catch (_) {}

          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SurgeonForm(profileId: profileId, existingData: const {})));
        }

      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Google Sign-In failed on server'))
        );
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
      if (mounted) setState(() => isLoading = false);
    }
  }


  /// ✅ UI DESIGN
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "Let’s ",
                style: TextStyle(color: Colors.black, fontSize: 22),
              ),
              TextSpan(
                text: "Sign up",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              // 🔹 Dropdown (Role Selector)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A5DB2), Color(0xFF3BA7F5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    hint: const Text(
                      "Sign Up As",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onChanged: (value) {
                      setState(() => selectedRole = value);
                    },
                    items: roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Row(
                              children: [
                                Icon(
                                  role == "Healthcare Organizations"
                                      ? Icons.local_hospital
                                      : Icons.person,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  role,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 🔹 Input Fields
              _buildField(
                label: "Full Name",
                hint: "Full name",
                controller: nameController,
                icon: Icons.person_outline,
              ),
              _buildField(
                label: "Phone number",
                hint: "Your number",
                controller: phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isRequired: false,
              ),
              _buildField(
                label: "Email",
                hint: "Your email",
                controller: emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              // 🔹 Password Field
              const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Your password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter password" : null,
              ),
              const SizedBox(height: 25),

              // 🔹 Signup Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signUpUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFADE1FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),

              // 🔘 Google Sign In Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.black12),
                  ),
                  onPressed: isLoading ? null : _handleGoogleSignIn,
                  icon: SvgPicture.string(
                    SignUpScreen._googleSvg,
                    height: 22,
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Sign In link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Reusable Input Builder
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: isRequired
              ? (value) => value!.isEmpty ? "Please enter $label" : null
              : null,
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
