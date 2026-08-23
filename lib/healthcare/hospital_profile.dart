import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/app_config.dart';

import 'package:doc/screens/signin_screen.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/healthcare/hospial_form.dart';
import 'package:doc/controllers/auth_controller.dart';
import 'package:get/get.dart';

class HospitalProfile extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool showBottomBar;

  const HospitalProfile({
    super.key,
    required this.data,
    this.showBottomBar = true,
  });

  @override
  State<HospitalProfile> createState() => _HospitalProfileState();
}

class _HospitalProfileState extends State<HospitalProfile> {
  final _logger = Logger();
  Map<String, dynamic> _profileData = {};
  bool _isLoadingProfile = true;
  bool _isDeleting = false;

  List<Map<String, dynamic>> _jobs = [];
  bool _isLoadingJobs = true;
  String? _jobsError;

  @override
  void initState() {
    super.initState();
    _profileData = widget.data;
    _fetchProfile();
    _fetchJobs();
  }

  Future<void> _fetchProfile() async {
    final healthcareId = widget.data['healthcare_id']?.toString() ??
        widget.data['_id']?.toString() ??
        '';

    if (healthcareId.isEmpty) {
      setState(() {
        _isLoadingProfile = false;
      });
      return;
    }

    try {
      final uri = Uri.parse(
          '${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$healthcareId');

      _logger.i('🏥 Fetching profile from: $uri');
      
      final response = await http.get(uri);
      _logger.i('🏥 Profile API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map && body['data'] != null ? body['data'] : body;
        
        if (data is Map<String, dynamic>) {
          if (mounted) {
            setState(() {
              // Merge existing data with fetched data, fetched takes precedence
              _profileData = {..._profileData, ...data};
              _isLoadingProfile = false;
            });
          }
        }
      } else {
        _logger.w('🏥 Failed to fetch profile: ${response.statusCode}');
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      _logger.e('🏥 Error fetching profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _logout() async {
    await AuthController.to.logout();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoadingJobs = true;
      _jobsError = null;
    });

    try {
      // Get healthcare_id from widget data
      final healthcareId = widget.data['healthcare_id']?.toString() ??
          widget.data['_id']?.toString() ??
          '';

      _logger.i('🏥 Fetching jobs for healthcare_id: $healthcareId');

      if (healthcareId.isEmpty) {
        setState(() {
          _jobsError = 'Healthcare ID not found';
          _isLoadingJobs = false;
        });
        return;
      }

      // Use the same API endpoint as MyJobsPage
      final uri = Uri.parse(
          '${AppConfig.apiBaseUrl}/healthcare/joblist-healthcare/$healthcareId');

      final response = await http.get(uri);

      _logger.i('🏥 Jobs API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body.trimLeft();
        dynamic decoded;
        try {
          decoded = jsonDecode(body);
        } catch (_) {
          decoded = {};
        }

        final data = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;
        final list = data is List
            ? data
            : (data is Map && data['jobs'] is List ? data['jobs'] : <dynamic>[]);

        final jobs = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is Map) {
            jobs.add(Map<String, dynamic>.from(item));
          }
        }

        _logger.i('🏥 ✅ Fetched ${jobs.length} jobs');

        if (!mounted) return;
        setState(() {
          _jobs = jobs;
          _isLoadingJobs = false;
        });
      } else if (response.statusCode == 404) {
        // No jobs found - not an error, just empty list
        _logger.i('🏥 No jobs found for this hospital');
        if (!mounted) return;
        setState(() {
          _jobs = [];
          _jobsError = null;
          _isLoadingJobs = false;
        });
      } else {
        _logger.w('🏥 ❌ Failed to fetch jobs: ${response.statusCode}');
        if (!mounted) return;
        setState(() {
          _jobsError = 'Failed to load jobs';
          _isLoadingJobs = false;
        });
      }
    } catch (e) {
      _logger.e('🏥 ❌ Error fetching jobs: $e');
      if (!mounted) return;
      setState(() {
        _jobsError = 'Error loading jobs';
        _isLoadingJobs = false;
      });
    }
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
              'Are you sure you want to delete your hospital account?',
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
      if (!mounted) return;
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final healthcareId = widget.data['healthcare_id']?.toString() ??
        widget.data['_id']?.toString() ??
        '';

    if (healthcareId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Healthcare ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/account/delete/$healthcareId?healthcare_id=$healthcareId',

      );
      
      _logger.i('🗑️ Deleting hospital account: $uri');
      
      final response = await http.delete(uri);
      
      _logger.i('🗑️ Delete response: ${response.statusCode}');
      _logger.d('🗑️ Delete body: ${response.body}');

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
      _logger.e('🗑️ Delete error: $e');
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
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Hospital Profile",
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 15),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.edit, color: Colors.blueAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HospitalForm(
                    healthcareId: widget.data['healthcare_id']?.toString() ?? 
                                 widget.data['_id']?.toString() ?? '',
                    existingData: _profileData,
                  ),
                ),
              ).then((_) => _fetchProfile());
            },
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await AuthController.to.logout();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              "Logout",
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Hospital Logo
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipOval(
                  child: Builder(
                    builder: (context) {
                      var logoUrl = (_profileData['hospitalLogo'] ?? '').toString();
                      // Add base URL if logo is a relative path
                      if (logoUrl.isNotEmpty && !logoUrl.startsWith('http')) {
                        logoUrl = '${AppConfig.serverUrl}/$logoUrl';

                      }
                      
                      return logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset('assets/logo2.png', fit: BoxFit.cover),
                            )
                          : Image.asset('assets/logo2.png', fit: BoxFit.cover);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Hospital Name & City
            Text(
              (_profileData['hospitalName'] ?? '').toString(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              (_profileData['location'] ?? '').toString(),
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue),
            ),

            const SizedBox(height: 20),

            // ✅ Contact Info Section
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 15,
              children: [
                _contactInfo(Iconsax.sms, "Email", (_profileData['email'] ?? '').toString()),
                _contactInfo(
                  Iconsax.global,
                  "Website",
                  (_profileData['hospitalWebsite'] ?? '').toString(),
                ),
                _contactInfo(Iconsax.call, "Phone", (_profileData['phoneNumber'] ?? '').toString()),
                _contactInfo(
                  Iconsax.location,
                  "Address",
                  (_profileData['location'] ?? '').toString(),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ✅ About Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "About :",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (_profileData['hospitalOverview'] ?? '').toString(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 25),

            // ✅ Departments Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Departments:",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...List<String>.from((_profileData['departmentsAvailable'] ?? const []))
                    .map((d) => _departmentChip(d)),
              ],
            ),


            const SizedBox(height: 30),

            // ✅ Job Listings Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Open Job Listings:",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Show loading, error, or job listings
            if (_isLoadingJobs)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_jobsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _jobsError!,
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              )
            else if (_jobs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No job openings available at the moment',
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              )
            else
              Column(
                children: _jobs.map((job) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _jobCard(job),
                )).toList(),
              ),

            const SizedBox(height: 30),

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

            const SizedBox(height: 50),

          ],
        ),
      ),

      // ✅ Bottom Navigation Bar
      bottomNavigationBar: widget.showBottomBar
          ? Container(
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
                      _bottomIcon(Iconsax.search_normal, "Search", false),
                      _bottomIcon(Iconsax.document, "Applied Jobs", false),
                      _bottomIcon(Iconsax.user, "Profile", true),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // 🔹 Contact Info Widget
  Widget _contactInfo(IconData icon, String label, String value) {
    return SizedBox(
      width: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Department Chip
  Widget _departmentChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD6EDFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 🔹 Job Listing Card
  Widget _jobCard(Map<String, dynamic> job) {
    // Extract job data
    final jobTitle = job['jobTitle']?.toString() ?? 'Job Opening';
    final hospitalName = _profileData['hospitalName']?.toString() ?? 'Hospital';
    
    // Build location from state and district
    final jobState = (job['state'] ?? '').toString();
    final jobDistrict = (job['district'] ?? '').toString();
    String location;
    if (jobDistrict.isNotEmpty && jobState.isNotEmpty) {
      location = '$jobDistrict, $jobState';
    } else if (jobState.isNotEmpty) {
      location = jobState;
    } else if (jobDistrict.isNotEmpty) {
      location = jobDistrict;
    } else {
      // Fallback for old jobs: try job location, then hospital location
      location = job['location']?.toString() ?? _profileData['location']?.toString() ?? 'Location';
    }
    
    final aboutRole = job['aboutRole']?.toString() ?? 'No description available';
    final subSpeciality = job['subSpeciality']?.toString() ?? '';
    final employmentType = job['employmentType']?.toString() ?? '';
    final experienceRequired = job['experienceRequired']?.toString() ?? '';
    
    // Get applicant count - need to fetch from applications
    // For now, show a placeholder or calculate if data is available
    final applicantCount = job['applicantCount']?.toString() ?? '0';
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/logo2.png',
                height: 40,
                width: 40,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 36, color: Colors.grey),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      hospitalName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6EDFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.people, color: Colors.blue, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      "$applicantCount Applicants",
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text(
            aboutRole,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (subSpeciality.isNotEmpty) _tag(subSpeciality),
              if (employmentType.isNotEmpty) _tag(employmentType),
              if (experienceRequired.isNotEmpty) _tag('Exp: $experienceRequired'),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Job Tag Widget
  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD6EDFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade900),
      ),
    );
  }

  // 🔹 Bottom Navigation Item
  Widget _bottomIcon(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
