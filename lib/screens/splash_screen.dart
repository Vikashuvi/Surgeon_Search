import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/screens/signin_screen.dart';
import 'package:doc/healthcare/hospial_form.dart';
import 'package:doc/profileprofile/surgeon_form.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';
import 'package:doc/navbar.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/app_config.dart';
import 'package:doc/controllers/auth_controller.dart';
import 'package:doc/model/api_service.dart';
import 'package:get/get.dart';
import 'package:doc/admin/admin_navbar.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// ⏳ Initialize splash logic and route
  Future<void> _initApp() async {
    // Give a short delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    // Then check login status using AuthController
    final auth = AuthController.to;
    await auth.restoreSession();

    if (!mounted) return;

    if (auth.isLoggedIn.value) {
      final role = auth.userRole.value.toLowerCase().trim();
      final profileId = auth.profileId.value;
      debugPrint('✅ User already logged in. Role: $role');

      if (role.contains('admin')) {
        final adminData = await SessionManager.getAdminData() ?? {};
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminNavbar(adminData: adminData)),
        );
      } else if (role.contains('hospital') || role.contains('health') || role.contains('org')) {
        final hid = (await SessionManager.getHealthcareId()) ?? profileId;
        final healthProfileFlag = await SessionManager.getHealthProfileFlag() ?? false;

        if (healthProfileFlag) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Navbar(hospitalData: {'healthcare_id': hid})),
          );
          return;
        }

        try {
          final url = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$hid');

          final resp = await http.get(url).timeout(const Duration(seconds: 12));
          if (!mounted) return;
          if (resp.statusCode == 200) {
            dynamic parsed;
            try { parsed = jsonDecode(resp.body); } catch (_) { parsed = {}; }
            final payload = (parsed is Map && parsed['data'] != null) ? parsed['data'] : parsed;
            final mapPayload = (payload is Map<String, dynamic>) ? payload : <String, dynamic>{};
            await SessionManager.saveHealthProfileFlag(true);
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Navbar(hospitalData: mapPayload)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HospitalForm(healthcareId: hid)),
            );
          }
        } catch (_) {
          if (!mounted) return;
          if (healthProfileFlag) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Navbar(hospitalData: {'healthcare_id': hid})),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HospitalForm(healthcareId: hid)),
            );
          }
        }
      } else if (role.contains('surgeon') || role.contains('doctor')) {
        final surgeonProfile = await SessionManager.getSurgeonProfileFlag() ?? false;
        
        if (surgeonProfile) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfessionalProfileViewPage(profileId: profileId),
            ),
          );
          return;
        }

        try {
          final res = await ApiService.fetchProfileInfo(profileId);
          if (!mounted) return;
          
          bool hasValidProfile = false;
          if (res['success'] == true) {
            final body = res['data'];
            final data = body is Map && body['data'] != null ? body['data'] : body;
            final p = data is Map && data['profile'] != null ? data['profile'] : data;
            
            hasValidProfile = p is Map &&
                (((p['fullName'] ?? p['fullname'] ?? '').toString().trim().isNotEmpty == true) ||
                (p['email']?.toString().trim().isNotEmpty == true) ||
                (p['phoneNumber']?.toString().trim().isNotEmpty == true));
          }

          if (hasValidProfile) {
            await SessionManager.saveSurgeonProfileFlag(true);
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProfessionalProfileViewPage(profileId: profileId),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SurgeonForm(profileId: profileId, existingData: const {}),
              ),
            );
          }
        } catch (_) {
          if (!mounted) return;
          if (surgeonProfile) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProfessionalProfileViewPage(profileId: profileId),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SurgeonForm(profileId: profileId, existingData: const {}),
              ),
            );
          }
        }
      } else {
        // Default to surgeon flow if role unknown
        if (!mounted) return;
        final surgeonProfile = await SessionManager.getSurgeonProfileFlag() ?? false;
        if (surgeonProfile) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfessionalProfileViewPage(profileId: profileId),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SurgeonForm(profileId: profileId, existingData: const {}),
            ),
          );
        }
      }
    } else {
      debugPrint('🚪 No active session found. Redirecting to Login.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🌟 App logo
            Image.asset('assets/logo2.png', height: 120, width: 120),
            const SizedBox(height: 25),
            const Text(
              'Surgeon Search',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
