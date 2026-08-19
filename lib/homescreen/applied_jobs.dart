import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/app_config.dart';

import 'package:doc/utils/session_manager.dart';
import 'package:doc/homescreen/search_job_screen.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';
import 'package:doc/homescreen/applied_job_details_screen.dart';
import 'package:doc/admin/surgeon_tab.dart';

class AppliedJobsScreen extends StatefulWidget {
  const AppliedJobsScreen({super.key});

  @override
  State<AppliedJobsScreen> createState() => _AppliedJobsScreenState();
}

class _AppliedJobsScreenState extends State<AppliedJobsScreen> {
  List<Map<String, dynamic>> appliedJobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
  }

  /// 🔹 Load applied jobs from backend for current user/profile
  Future<void> _loadAppliedJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileId = await SessionManager.getProfileId();
      if (profileId == null || profileId.isEmpty) {
        setState(() {
          _error = 'Profile id not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // 1. Fetch ALL jobs first to create a lookup map
      // This is the same API used in SearchScreen: ${AppConfig.apiBaseUrl}/healthcare/joblist-surgeons

      final allJobsLookup = await _fetchAllJobsLookup();

      // 2. Fetch Applied Jobs
      final url = Uri.parse(
          '${AppConfig.apiBaseUrl}/jobs/applied-jobs/$profileId');

      final response = await http.get(url);

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
        
        // Process each job application
        for (final item in list) {
          if (item is! Map) continue;
          final m = item;
          
// Removed debug print
// Removed debug print
// Removed debug print
// Removed debug print
// Removed debug print

          // 🔍 Improved Job ID Extraction
          String? jobId;
          
          // 1. Direct fields
          if (m['jobId'] != null) { jobId = m['jobId'].toString(); }
          else if (m['job_id'] != null) { jobId = m['job_id'].toString(); }
          
          // 2. Nested objects or strings
          if (jobId == null) {
            if (m['job'] is Map) {
               jobId = m['job']['_id']?.toString() ?? m['job']['id']?.toString();
            } else if (m['job'] is String) {
               jobId = m['job'];
            }
          }
          
          if (jobId == null) {
             if (m['jobProfile'] is Map) {
                if (m['jobProfile']['job'] is Map) {
                   jobId = m['jobProfile']['job']['_id']?.toString();
                } else if (m['jobProfile']['job'] is String) {
                   jobId = m['jobProfile']['job'];
                } else {
                   jobId = m['jobProfile']['_id']?.toString();
                }
             } else if (m['jobProfile'] is String) {
               jobId = m['jobProfile'];
             }
          }

          // Initial extraction from the list endpoint
          Map rawJob;
          if (m['job'] is Map) {
            rawJob = m['job'] as Map;
          } else if (m['jobProfile'] is Map &&
              (m['jobProfile']['job'] is Map)) {
            rawJob = m['jobProfile']['job'] as Map;
          } else if (m['jobProfile'] is Map) {
            rawJob = m['jobProfile'] as Map;
          } else {
            rawJob = m;
          }

          String title = (rawJob['jobTitle'] ??
                  rawJob['title'] ??
                  rawJob['jobRole'] ??
                  rawJob['role'] ??
                  rawJob['position'])
              ?.toString()
              .trim() ?? '';

          String org = (rawJob['healthcareName'] ??
                  rawJob['hospitalName'] ??
                  rawJob['healthcareOrganization'] ??
                  rawJob['organisation'] ??
                  rawJob['organization'])
              ?.toString()
              .trim() ?? '';

          String location = rawJob['location']?.toString() ?? '';
          String desc = (rawJob['aboutRole'] ??
                  rawJob['description'] ??
                  rawJob['jobDescription'] ??
                  rawJob['roleDescription'])
              ?.toString()
              .trim() ?? '';

          // 🌟 MAGIC FIX: Use the lookup map if details are missing!
          if ((title.isEmpty || org.isEmpty) && jobId != null) {
// Removed debug print
             
             if (allJobsLookup.containsKey(jobId)) {
               final lookupJob = allJobsLookup[jobId]!;
// Removed debug print
               
               if (title.isEmpty) title = (lookupJob['jobTitle'] ?? lookupJob['title'] ?? '').toString();
               if (org.isEmpty) org = (lookupJob['healthcareName'] ?? lookupJob['hospitalName'] ?? lookupJob['healthcareOrganization'] ?? '').toString();
               if (location.isEmpty) location = (lookupJob['location'] ?? '').toString();
               if (desc.isEmpty) desc = (lookupJob['aboutRole'] ?? lookupJob['description'] ?? '').toString();
             } else {
// Removed debug print
               // Fallback: If not in lookup (maybe expired/closed?), try individual fetch
               try {
                  final details = await _fetchJobDetails(jobId);
// Removed debug print
                  if (details != null) {
// Removed debug print
                  if (title.isEmpty) title = (details['jobTitle'] ?? details['title'] ?? '').toString();
                  if (org.isEmpty) org = (details['healthcareName'] ?? details['hospitalName'] ?? details['healthcareOrganization'] ?? '').toString();
                  if (location.isEmpty) location = (details['location'] ?? '').toString();
                  if (desc.isEmpty) desc = (details['aboutRole'] ?? details['description'] ?? '').toString();
                } else {
// Removed debug print
                }
              } catch (e) {
// Removed debug print
              }
             }
          }

          final statusValue = (m['status'] ??
                  m['applicationStatus'] ??
                  m['jobStatus'] ??
                  rawJob['status'])
              ?.toString()
              .trim();

          final logoUrl = rawJob['hospitalLogo']?.toString();

          jobs.add({
            'id': jobId, // Store ID for navigation
            'title': title.isNotEmpty ? title : 'Unknown Role',
            'org': org.isNotEmpty ? org : 'Healthcare Organization',
            'location': location.isNotEmpty ? location : 'Location not specified',
            'status': statusValue ?? 'Applied',
            'description': desc.isNotEmpty ? desc : 'No description available for this position.',
            'logo': logoUrl,
          });
        }

        if (mounted) {
          setState(() {
            appliedJobs = jobs;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            appliedJobs = [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load applied jobs (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading applied jobs: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Helper to fetch ALL jobs and create a lookup map by ID
  Future<Map<String, Map<String, dynamic>>> _fetchAllJobsLookup() async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/joblist-surgeons');

      final response = await http.get(url);

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
        
        final Map<String, Map<String, dynamic>> lookup = {};
        
        for (final item in list) {
          if (item is Map) {
            final id = (item['_id'] ?? item['id'])?.toString();
            if (id != null && id.isNotEmpty) {
              lookup[id] = Map<String, dynamic>.from(item);
            }
          }
        }
        return lookup;
      }
    } catch (e) {
      // Error fetching job list for lookup
    }
    return {};
  }

  /// Helper to fetch individual job details
  Future<Map<String, dynamic>?> _fetchJobDetails(String jobId) async {
    try {
      final url = Uri.parse(
          '${AppConfig.apiBaseUrl}/healthcare/job-profile/$jobId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = response.body.trimLeft();
        final decoded = jsonDecode(body);
        final data = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;
        return data is Map<String, dynamic> ? data : null;
      }
    } catch (_) {
      // Ignore errors, just return null
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background as per design
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo2.png', // Assuming this is the Surgeon Search logo
                      height: 50,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Applied Jobs",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 40),
                              const SizedBox(height: 10),
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                              TextButton(
                                onPressed: _loadAppliedJobs,
                                child: const Text("Retry"),
                              )
                            ],
                          ),
                        )
                      : appliedJobs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Iconsax.document,
                                      size: 60, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No applied jobs yet",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: appliedJobs.length,
                              itemBuilder: (context, index) {
                                final job = appliedJobs[index];
                                return _buildJobCard(job);
                              },
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final rawStatus = job['status'].toString();
    final statusLower = rawStatus.toLowerCase();

    // Determine status color and text
    Color statusColor;
    String statusText;

    if (statusLower.contains('interview')) {
      statusColor = const Color(0xFF00C853); // Green for Interview
      statusText = "Interview Scheduled";
    } else if (statusLower.contains('reject') ||
        statusLower.contains('declined')) {
      statusColor = const Color(0xFFFF3B30); // Red for Rejected
      statusText = "Rejected";
    } else if (statusLower.contains('shortlist')) {
      statusColor = const Color(0xFFFFAB00); // Amber for Shortlisted
      statusText = "Shortlisted";
    } else if (statusLower.contains('hired') ||
        statusLower.contains('offer') ||
        statusLower.contains('accepted')) {
      statusColor = const Color(0xFF00C853); // Green for Hired/Offer
      statusText = "Offer Received";
    } else if (statusLower == 'applied') {
      statusColor = const Color(0xFF0062FF); // Blue for Applied
      statusText = "Applied";
    } else {
      statusColor = const Color(0xFF0062FF); // Blue for others
      // Capitalize first letter of the status
      if (rawStatus.isNotEmpty) {
        statusText = rawStatus[0].toUpperCase() + rawStatus.substring(1);
      } else {
        statusText = "Applied";
      }
    }

    return GestureDetector(
      onTap: () {
        final jobId = job['id'];
        if (jobId != null && jobId.toString().isNotEmpty) {
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppliedJobDetailsScreen(jobId: jobId.toString()),
            ),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Job details not available')),
            );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Logo + Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    image: job['logo'] != null &&
                            job['logo'].toString().isNotEmpty &&
                            !job['logo'].toString().contains('null')
                        ? DecorationImage(
                            image: NetworkImage(job['logo']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: job['logo'] == null ||
                          job['logo'].toString().isEmpty ||
                          job['logo'].toString().contains('null')
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset('assets/logo.png'),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0062FF), // Blue color
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['org'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['location'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              job['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Status Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Iconsax.search_normal, "Search", false, () {
             Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              );
          }),
          _navItem(Icons.medical_services_outlined, "Surgeons", false, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SurgeonTab(showAppBar: true),
              ),
            );
          }),
          _navItem(Icons.bookmark, "Applied Jobs", true, () {}), // Using bookmark icon to match design closer
          _navItem(Iconsax.user, "Profile", false, () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final profileId = await SessionManager.getProfileId();
              if (!mounted) return;
              if (profileId == null || profileId.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content:
                        Text('Profile not found. Please complete your profile.'),
                  ),
                );
                return;
              }
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => ProfessionalProfileViewPage(
                    profileId: profileId,
                  ),
                ),
              );
          }),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF0062FF) : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF0062FF) : Colors.grey.shade400,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
