import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:doc/model/doctor_profile_data.dart';
import 'package:doc/model/api_service.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/screens/signin_screen.dart';
import 'package:doc/homescreen/search_job_screen.dart';
import 'package:doc/homescreen/applied_jobs.dart';
import 'package:doc/profileprofile/surgeon_form.dart';
import 'package:doc/admin/surgeon_tab.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:doc/controllers/auth_controller.dart';
import 'package:get/get.dart';

import 'package:doc/utils/subscription_guard.dart';
import 'package:doc/utils/app_config.dart';


class ProfessionalProfileViewPage extends StatefulWidget {
  final String profileId;
  const ProfessionalProfileViewPage({super.key, required this.profileId});

  @override
  State<ProfessionalProfileViewPage> createState() =>
      _ProfessionalProfileViewPageState();
}

class _ProfessionalProfileViewPageState
    extends State<ProfessionalProfileViewPage> {
  bool _isLoading = true;
  bool _isDeleting = false;
  DoctorProfileData? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ApiService.fetchProfileInfo(widget.profileId);
      if (result['success'] == true) {
        setState(() {
          _profile = DoctorProfileData.fromMap(result['data']);
          _isLoading = false;
        });
      } else {
        // Fallback to empty profile with session data
        final name = await SessionManager.getUserName() ?? '';
        final phone = await SessionManager.getUserPhone() ?? '';
        final email = await SessionManager.getUserEmail() ?? '';

        setState(() {
          _profile = DoctorProfileData(
            name: name,
            speciality: '',
            summary: '',
            degree: '',
            subSpeciality: '',
            designation: '',
            organization: '',
            period: '',
            workLocation: '',
            phone: phone,
            email: email,
            location: '',
            portfolio: '',
            profilePicture: '',
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback on error
      final name = await SessionManager.getUserName() ?? '';
      final phone = await SessionManager.getUserPhone() ?? '';
      final email = await SessionManager.getUserEmail() ?? '';

      setState(() {
        _profile = DoctorProfileData(
          name: name,
          speciality: '',
          summary: '',
          degree: '',
          subSpeciality: '',
          designation: '',
          organization: '',
          period: '',
          workLocation: '',
          phone: phone,
          email: email,
          location: '',
          portfolio: '',
          profilePicture: '',
        );
        _isLoading = false;
      });
    }
  }

  double _calculateCompletion() {
    if (_profile == null) return 0.0;
    int total = 10;
    int filled = 0;

    if (_profile!.name.isNotEmpty) filled++;
    if (_profile!.speciality.isNotEmpty) filled++;
    if (_profile!.degree.isNotEmpty) filled++;
    if (_profile!.phone.isNotEmpty) filled++;
    if (_profile!.email.isNotEmpty) filled++;
    if (_profile!.location.isNotEmpty) filled++;
    if (_profile!.summary.isNotEmpty) filled++;
    if (_profile!.profilePicture.isNotEmpty) filled++;
    if (_profile!.designation.isNotEmpty) filled++;
    if (_profile!.organization.isNotEmpty) filled++;

    return filled / total;
  }

  void _navigateToEdit() {
    final data = {
      'fullName': _profile?.name,
      'speciality': _profile?.speciality,
      'subSpeciality': _profile?.subSpeciality,
      'degree': _profile?.degree,
      'summaryProfile': _profile?.summary,
      'phoneNumber': _profile?.phone,
      'email': _profile?.email,
      'location': _profile?.location,
      'portfolioLinks': _profile?.portfolio,
      'profilePicture': _profile?.profilePicture,
      'yearsOfExperience': _profile?.period,
      'state': _profile?.state,
      'district': _profile?.district,
      'cv': _profile?.cv,
      'highestDegree': _profile?.highestDegree,
      'uploadLogBook': _profile?.logBook,
      'surgicalExperience': _profile?.surgicalExperience,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurgeonForm(
          profileId: widget.profileId,
          existingData: data,
        ),
      ),
    ).then((_) => _loadProfile());
  }

  Future<void> _logout() async {
    await AuthController.to.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  /// Delete account with confirmation dialog
  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.warning_2,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.info_circle,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action is permanent and cannot be undone. You will lose all your data.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete Account',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/account/delete/${widget.profileId}?profile_id=${widget.profileId}',
      );

      
      final response = await http.delete(uri);
      

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Clear session and navigate to login
        await AuthController.to.logout();
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } else {
        // Parse error message
        String errorMsg = 'Failed to delete account';
        try {
          final body = jsonDecode(response.body);
          errorMsg = body['message'] ?? body['error'] ?? errorMsg;
        } catch (_) {}
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // No error check needed here as we fallback to empty profile

    // Display the doctor profile directly in this widget
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Doctor Profile",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.edit, color: Colors.blueAccent),
            onPressed: _navigateToEdit,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Iconsax.logout, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Show trial expiry banner if subscription expired
          FutureBuilder<bool?>(
            future: SessionManager.getFreeTrialFlag(),
            builder: (context, snapshot) {
              if (snapshot.data == false) {
                // Trial expired - show warning banner
                return SubscriptionGuard.buildTrialExpiredBanner(context);
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Main profile content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 120,
                height: 120,
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                child: ClipOval(
                  child: _profile!.profilePicture.isNotEmpty
                      ? Image.network(
                          _profile!.profilePicture,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Iconsax.user,
                                size: 50, color: Colors.grey);
                          },
                        )
                      : const Icon(Iconsax.user, size: 50, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Column(
                children: [
                  Text(
                    _profile!.name.isNotEmpty
                        ? _profile!.name
                        : 'Surgeon Name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _profile!.speciality.isNotEmpty
                        ? _profile!.speciality
                        : 'Speciality not provided',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),

            _infoHeader("Personal Information"),
            _infoTile(Iconsax.call, "Phone", _profile!.phone),
            _infoTile(Iconsax.sms, "Email", _profile!.email),
            _infoTile(Iconsax.location, "Location", _profile!.location),

            const SizedBox(height: 10),
            _infoHeader("Professional Details"),
            _infoTile(Iconsax.book, "Degree", _profile!.degree),
            _infoTile(
                Iconsax.activity, "Sub-Speciality", _profile!.subSpeciality),
            _infoTile(Iconsax.hospital, "Organization", _profile!.organization),
            _infoTile(Iconsax.briefcase, "Designation", _profile!.designation),
            _infoTile(Iconsax.location, "Work Location", _profile!.workLocation),
            _infoTile(Iconsax.calendar, "Experience", _profile!.period),
            _infoTile(Iconsax.link, "Portfolio", _profile!.portfolio),
            
            // State and District
            if (_profile!.state.isNotEmpty)
              _infoTile(Iconsax.map, "State", _profile!.state),
            if (_profile!.district.isNotEmpty)
              _infoTile(Iconsax.location, "District", _profile!.district),

            const SizedBox(height: 16),
            _infoHeader("Summary"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _profile!.summary.isNotEmpty
                    ? _profile!.summary
                    : "No summary provided",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),

            // Documents Section (CV, Degree, Log Book)
            const SizedBox(height: 20),
            _infoHeader("Documents"),
            const SizedBox(height: 8),
            _buildDocumentSection(),

            const SizedBox(height: 30),

            // Logout Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Iconsax.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Delete Account Button
            Center(
              child: TextButton.icon(
                onPressed: _isDeleting ? null : _showDeleteAccountDialog,
                icon: _isDeleting 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : Icon(Iconsax.trash, color: Colors.red.shade600, size: 18),
                label: Text(
                  _isDeleting ? "Deleting..." : "Delete Account",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
          ),
        ],
      ),

      // Bottom Navigation Bar (Unified with SafeArea)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bottomNavItem(
                  Iconsax.search_normal,
                  "Search",
                  false,
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                _bottomNavItem(
                  Icons.medical_services_outlined,
                  "Surgeons",
                  false,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SurgeonTab(showAppBar: true),
                      ),
                    );
                  },
                ),
                _bottomNavItem(
                  Iconsax.document,
                  "Applied Jobs",
                  false,
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppliedJobsScreen(),
                      ),
                    );
                  },
                ),
                _bottomNavItem(
                  Iconsax.user,
                  "Profile",
                  true,
                  () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _calculateCompletion();
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Profile Completion",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
              Text(
                "$percentage%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white,
            color: Colors.blueAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          if (percentage < 100) ...[
            const SizedBox(height: 8),
            Text(
              "Complete your profile to get better job recommendations.",
              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
            ),
          ]
        ],
      ),
    );
  }

  //  Section Header Widget
  Widget _infoHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  // Info Row Widget
  Widget _infoTile(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Documents Section Widget
  Widget _buildDocumentSection() {
    final hasCV = _profile!.cv.isNotEmpty;
    final hasDegree = _profile!.highestDegree.isNotEmpty;
    final hasLogBook = _profile!.logBook.isNotEmpty;

    if (!hasCV && !hasDegree && !hasLogBook) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          "No documents uploaded yet",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        if (hasCV) _buildDocumentItem("CV / Resume", _profile!.cv, Iconsax.document_text),
        if (hasDegree) _buildDocumentItem("Highest Degree", _profile!.highestDegree, Iconsax.award),
        if (hasLogBook) _buildDocumentItem("Log Book", _profile!.logBook, Iconsax.book_1),
      ],
    );
  }

  Widget _buildDocumentItem(String title, String url, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          url.split('/').last,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Iconsax.export_1, color: Colors.blueAccent),
          onPressed: () => _openDocument(url),
          tooltip: "View Document",
        ),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    // Construct full URL if it's just a filename or relative path
    String fullUrl = url;
    if (!url.startsWith('http')) {
      // Assuming files are served from the root. 
      // If your server uses a specific path for uploads (e.g. /uploads/), add it here.
      // Example: ${AppConfig.serverUrl}/uploads/$url

      fullUrl = '${AppConfig.serverUrl}/$url'; 

    }

    final uri = Uri.parse(fullUrl);
    debugPrint("Launching Document URL: $uri"); 

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open document: $fullUrl")),
        );
      }
    }
  }

  // Bottom Navigation Item (Unified visual style)
  Widget _bottomNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF0062FF) : Colors.grey.shade400, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isActive ? const Color(0xFF0062FF) : Colors.grey.shade400,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
