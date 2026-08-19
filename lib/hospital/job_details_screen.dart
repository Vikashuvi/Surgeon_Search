import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:doc/utils/app_config.dart';

import 'package:doc/model/doctor_profile_data.dart';
import 'package:doc/model/api_service.dart';
import 'package:doc/hospital/interview_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:doc/widgets/skeleton_loader.dart';
import 'package:shimmer/shimmer.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final void Function(Map<String, dynamic>) onEdit;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onViewApplicants;
  final void Function(String candidateId)? onScheduleInterview;

  const JobDetailScreen({
    super.key,
    required this.job,
    required this.onEdit,
    required this.onClose,
    required this.onDelete,
    required this.onViewApplicants,
    this.onScheduleInterview,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Map<String, dynamic> _jobData;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _jobData = widget.job;
    _fetchJobDetails();
  }

  // Additional state for hospital details if not populated in job
  String? _hospitalName;
  String? _hospitalLogo;

  Future<void> _fetchJobDetails() async {
    final rawId = _jobData['_id'] ?? _jobData['id'];
    if (rawId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final jobId = rawId.toString();

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/job-profile/$jobId');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map && body['data'] != null ? body['data'] : body;
        if (data is Map<String, dynamic>) {
           _jobData = data;
        
           // Check if healthcare_id is a String (ID) and fetch profile if so
           final hcId = data['healthcare_id'];
           if (hcId is String && hcId.isNotEmpty) {
             await _fetchHospitalProfile(hcId);
           } else if (hcId is Map) {
             // Already populated
             if (mounted) {
               setState(() {
                  _hospitalName = hcId['hospitalName'] ?? hcId['name'];
                  _hospitalLogo = hcId['hospitalLogo'];
                  _isLoading = false;
               });
             }
           } else {
             if (mounted) setState(() => _isLoading = false);
           }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching job details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHospitalProfile(String id) async {
    try {
       final uri = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$id');

       final response = await http.get(uri);
       if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final data = body is Map && body['data'] != null ? body['data'] : body;
          if (data is Map) {
             if (mounted) {
               setState(() {
                 _hospitalName = data['hospitalName'] ?? data['name'] ?? data['organizationName'];
                 _hospitalLogo = data['hospitalLogo'];
                 _isLoading = false;
               });
             }
          }
       } else {
         if (mounted) setState(() => _isLoading = false);
       }
    } catch (e) {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _jobData;
    // Use fetched data or fallbacks
    final title = job['jobTitle'] ?? job['title'] ?? 'Job Title';
    final postedOn = job['postedOn'] ?? ''; // You might need to format this date
    
    // Build location from state and district
    final jobState = job['state'] ?? '';
    final jobDistrict = job['district'] ?? '';
    String location;
    if (jobDistrict.isNotEmpty && jobState.isNotEmpty) {
      location = '$jobDistrict, $jobState';
    } else if (jobState.isNotEmpty) {
      location = jobState;
    } else if (jobDistrict.isNotEmpty) {
      location = jobDistrict;
    } else {
      location = job['location'] ?? 'Location'; // Fallback for old jobs
    }
    
    final experience = job['minYearsOfExperience'] != null ? '${job['minYearsOfExperience']} Years' : 'Experience';
    final jobType = job['jobType'] ?? 'Full Time';
    final salary = job['salaryRange'] ?? 'Salary';
    final designation = (job['designation'] != null && job['designation'].toString().trim().isNotEmpty)
        ? job['designation'].toString()
        : null;
    final recruiter = (job['recruiter'] != null && job['recruiter'].toString().trim().isNotEmpty)
        ? job['recruiter'].toString()
        : null;
    final department = job['department'] ?? 'N/A';
    final subSpeciality = job['subSpeciality'] ?? 'N/A';
    final interviewMode = job['interviewMode'] ?? 'In-person';
    final aboutRole = job['aboutRole'] ?? 'N/A';
    final responsibilities = job['keyResponsibilities'] ?? '';
    final qualifications = job['preferredQualifications'] ?? '';
    String deadline = job['applicationDeadline'] ?? 'N/A';
    if (deadline != 'N/A' && deadline.contains('T')) {
      deadline = deadline.split('T')[0];
    }
    
    // Hospital Name - try to get from healthcare_id if populated, otherwise hardcoded fallback or from job map
    // The API might return healthcare_id as an object if populated, or just an ID string.
    // For now, we'll check if it's a map and has a name.
    String hospitalName = _hospitalName ?? "Hospital"; 
    String? hospitalLogo = _hospitalLogo;

    if (job['healthcare_id'] is Map) {
       hospitalName = job['healthcare_id']['hospitalName'] ?? job['healthcare_id']['name'] ?? hospitalName;
       hospitalLogo = job['healthcare_id']['hospitalLogo'] ?? hospitalLogo;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            // Top bar + posted date + action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _hasChanges),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16),
                        SizedBox(width: 6),
                        Text("Back", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (postedOn.isNotEmpty)
                        Text(
                          "Posted on $postedOn",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
            // Take Action dropdown - disabled when job is closed
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Builder(
                  builder: (context) {
                    final status = (job['status'] ?? 'active').toString().toLowerCase();
                    final isClosed = status == 'closed' || status == 'job filled';
                    
                    return GestureDetector(
                      onTap: isClosed ? null : () => _showTakeActionMenu(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isClosed ? Colors.grey : Colors.blue),
                          color: isClosed ? Colors.grey.shade100 : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isClosed ? "Job Closed" : "Take Action",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isClosed ? Colors.grey : Colors.blue,
                              ),
                            ),
                            if (!isClosed) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    Center(
                      child: ClipOval(
                        child: Container(
                          height: 90,
                          width: 90,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: (hospitalLogo != null && hospitalLogo.isNotEmpty)
                              ? Image.network(
                                  hospitalLogo,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.white),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      "assets/logo.png",
                                      fit: BoxFit.contain,
                                    );
                                  },
                                )
                              : Image.asset(
                                  "assets/logo.png",
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        _iconText(Icons.local_hospital, hospitalName),
                        _iconText(
                          Icons.location_on_outlined,
                          location,
                        ),
                        _iconText(Icons.school, experience),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // full-time + salary pill
                    // ---------- FULL TIME + SALARY BOX (Exact UI) ----------
                    Container(
                      height: 70,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0062FF), Color(0xFF3E8BFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0062FF).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // ---------- LEFT SIDE ----------
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.work,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  jobType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ---------- DIVIDER ----------
                          Container(
                            width: 1,
                            height: 45,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),

                          // ---------- RIGHT SIDE ----------
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.currency_rupee, // Changed to Rupee
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  salary,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    if (designation != null && designation.isNotEmpty) ...[
                      _sectionTitle("Designation:"),
                      _sectionText(designation),
                    ],
                    if (recruiter != null && recruiter.isNotEmpty) ...[
                      _sectionTitle("Posted By / Recruiter:"),
                      _sectionText(recruiter),
                    ],
                    _sectionTitle("Department:"),
                    _sectionText(department),
                    _sectionTitle("Sub-Speciality:"),
                    _sectionText(subSpeciality),
                    _sectionTitle("Interview Mode:"),
                    _sectionText(interviewMode),
                    _sectionTitle("About the Role:"),
                    _sectionText(aboutRole),
                    _sectionTitle("Key Responsibilities:"),
                    _sectionText(responsibilities), // Displaying as text
                    _sectionTitle("Preferred Qualifications:"),
                    _sectionText(qualifications), // Displaying as text
                    _sectionTitle("Application Deadline:"),
                    _sectionText(deadline),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0062FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: widget.onViewApplicants,
                  child: const Text(
                    "View Applicants",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _iconText(IconData icon, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            title,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  );

  Widget _sectionText(String text) => SizedBox(
    width: double.infinity,
    child: Text(
      text,
      textAlign: TextAlign.left,
      style: const TextStyle(fontSize: 14, height: 1.6),
    ),
  );



  // Take Action menu: shows Job filled / Extended / Closed
  void _showTakeActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text("Job filled"),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateJobStatus("job filled");
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.orange),
                title: const Text("Extended"),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleExtendJob(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text("Closed"),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Close Job"),
                      content: const Text(
                          "Do you want to close all the interviews scheduled for this job?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("No"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateJobStatus("closed");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            "Yes",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleExtendJob(BuildContext context) async {
    // Get the current deadline from the job data
    DateTime firstSelectableDate = DateTime.now().add(const Duration(days: 1));
    
    final currentDeadline = _jobData['applicationDeadline']?.toString() ?? '';
    if (currentDeadline.isNotEmpty && currentDeadline != 'N/A') {
      try {
        // Parse the deadline (could be in format "2025-12-08" or "2025-12-08T00:00:00.000Z")
        final deadlineDate = DateTime.parse(currentDeadline.split('T')[0]);
        // The new deadline must be after the current deadline
        firstSelectableDate = deadlineDate.add(const Duration(days: 1));
      } catch (e) {
// Removed debug print
      }
    }
    
    // If the calculated first date is in the past, use tomorrow
    if (firstSelectableDate.isBefore(DateTime.now())) {
      firstSelectableDate = DateTime.now().add(const Duration(days: 1));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: firstSelectableDate,
      firstDate: firstSelectableDate,
      lastDate: DateTime(2100),
      helpText: 'Select a date after the current deadline',
    );

    if (picked != null) {
      // Format date as YYYY-MM-DD
      final formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _updateJobStatus("extended", deadline: formattedDate);
    }
  }

  Future<void> _updateJobStatus(String status, {String? deadline}) async {
    final jobId = (_jobData['_id'] ?? _jobData['id'] ?? '').toString();
    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job id not found')),
      );
      return;
    }

    // Use the endpoint provided by the user
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/healthcare/job-edit/$jobId',

    );

    final Map<String, dynamic> payload = {
      'status': status,
    };

    if (deadline != null) {
      payload['applicationDeadline'] = deadline;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            _jobData['status'] = status;
            if (deadline != null) {
              _jobData['applicationDeadline'] = deadline;
            }
            _isLoading = false;
            _hasChanges = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Job marked as $status')),
          );
          // If extended, we might want to refresh the UI to show the new deadline immediately
          // The setState above updates the local map, so the UI should rebuild.
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update job: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job: $e')),
        );
      }
    }
  }


}

// ----------------- ApplicantsListPage -----------------
class ApplicantsListPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final List<Map<String, dynamic>> applicants;
  final String? jobStatus;

  const ApplicantsListPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.applicants,
    this.jobStatus,
  });

  @override
  State<ApplicantsListPage> createState() => _ApplicantsListPageState();
}

class _ApplicantsListPageState extends State<ApplicantsListPage> {
  late List<Map<String, dynamic>> _applicants;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _applicants = widget.applicants;
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/jobs/applied-jobs/specific-jobs/${widget.jobId}',

      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = response.body.trimLeft();
        dynamic decoded;
        try {
          decoded = jsonDecode(body);
        } catch (_) {
          decoded = [];
        }

        final data = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;
        final list = data is List
            ? data
            : (data is Map && data['applications'] is List
                ? data['applications']
                : <dynamic>[]);

        final applicants = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is! Map) continue;
          final m = item;
          
          // Debug logs
          debugPrint('🔍 Debug Applicant Item: $m');

          // Extract profile data
          // If 'applicant' is a Map, use it. If it's missing, 'm' might be the flat object.
          final profileData = m['applicant'] is Map ? m['applicant'] as Map : (m['applicant'] == null ? m : <String, dynamic>{});
          
          // Create a mutable map starting with profile data
          final merged = Map<String, dynamic>.from(profileData);
          
          // Overlay Application-level fields specific to this job application
          // This ensures we see the status of THIS application, not the user's generic status.
          if (m.containsKey('status')) {
            merged['status'] = m['status'];
          }

          // Check for boolean flag to robustly set status
          // The API returns 'isInterviewscheduled' (lowercase s) or potentially 'isInterviewScheduled'
          if (m['isInterviewscheduled'] == true || m['isInterviewScheduled'] == true) {
             merged['status'] = 'Interview Scheduled';
          }
          
          // Use 'createdAt' from the application object as 'appliedOn'
          if (m.containsKey('createdAt')) {
            merged['appliedOn'] = m['createdAt'];
            merged['createdAt'] = m['createdAt'];
          }
          
          // Capture Application ID (crucial for rejection/updates)
          if (m.containsKey('_id')) {
             // heavily prefer Application ID for list actions
            merged['_id'] = m['_id']; 
            merged['applicationId'] = m['_id'];
          }
          
          // Ensure profilePic is available (fallback to what's in 'm' if profile doesn't have it)
          if (!merged.containsKey('profilePicture') && m.containsKey('profileImage')) {
             merged['profilePicture'] = m['profileImage'];
          }
          
          // Capture surgeonprofile_id (crucial for rejecting applications)
          // The API may return it as 'surgeonprofile_id' or 'surgeonProfileId'
          if (m.containsKey('surgeonprofile_id')) {
            merged['surgeonprofile_id'] = m['surgeonprofile_id'];
          } else if (m.containsKey('surgeonProfileId')) {
            merged['surgeonprofile_id'] = m['surgeonProfileId'];
          } else if (profileData.containsKey('_id')) {
            // If surgeonprofile_id is not explicitly present, the profile's _id might be it
            merged['surgeonprofile_id'] = profileData['_id'];
          }
          
          // Also capture healthcare_id if present
          if (m.containsKey('healthcare_id')) {
            merged['healthcare_id'] = m['healthcare_id'];
          }
          
          // Capture job_id if present
          if (m.containsKey('job_id')) {
            merged['job_id'] = m['job_id'];
          } else if (m.containsKey('jobId')) {
            merged['job_id'] = m['jobId'];
          }

          applicants.add(merged);
        }

        if (mounted) {
          setState(() {
            _applicants = applicants;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInitials(String name) {
    return Container(
      width: 50,
      height: 50,
      color: const Color(0xFFE0F0FF),
      child: Center(
        child: Text(
          (name.isNotEmpty && name.trim().isNotEmpty) ? name.trim()[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0062FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Applicants",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonLoader(itemCount: 6, height: 100),
            )
          : _applicants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.people, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No applicants yet",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applicants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final a = _applicants[index];
                    final firstName =
                        (a['firstName'] ?? a['name'] ?? '').toString();
                    final lastName = (a['lastName'] ?? '').toString();
                    final name = [firstName, lastName]
                        .where((s) => s.isNotEmpty)
                        .join(' ')
                        .trim();
                    final createdRaw =
                        (a['createdAt'] ?? a['appliedOn'] ?? '').toString();
                    final appliedOn = createdRaw.contains('T')
                        ? createdRaw.split('T').first
                        : createdRaw;
                    final status = (a['status'] ?? 'Pending').toString();
                    final isShortlisted = status.toLowerCase() == 'shortlisted';
                    final isInterviewScheduled = status.toLowerCase().contains('interview');

                    final profilePic = (a['profilePicture'] ?? a['profilePic'] ?? a['profileImage'] ?? '').toString();

                    return Container(
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
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final isJobClosed = (widget.jobStatus ?? '').toLowerCase() == 'closed' ||
                                                (widget.jobStatus ?? '').toLowerCase() == 'job filled';
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApplicantProfilePage(
                                  applicant: a,
                                  jobId: widget.jobId,
                                  isJobClosed: isJobClosed,
                                ),
                              ),
                            );
                            if (result == true) {
                              _fetchApplicants();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: profilePic.isNotEmpty
                                      ? Image.network(
                                          profilePic.startsWith('http') 
                                              ? profilePic 
                                              : '${AppConfig.serverUrl}/$profilePic',

                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(color: Colors.white),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return _buildInitials(name);
                                          },
                                        )
                                      : _buildInitials(name),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.isNotEmpty
                                            ? name
                                            : 'Unknown Candidate',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Iconsax.calendar_1,
                                              size: 14,
                                              color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            appliedOn.isNotEmpty
                                                ? appliedOn
                                                : "N/A",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isShortlisted
                                        ? const Color(0xFFE8F5E9)
                                        : isInterviewScheduled 
                                            ? Colors.blue.shade50
                                            : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.isNotEmpty ? status : 'Pending',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isShortlisted
                                          ? Colors.green[700]
                                          : isInterviewScheduled
                                              ? Colors.blue[700]
                                              : Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ----------------- ApplicantProfilePage -----------------
class ApplicantProfilePage extends StatefulWidget {
  final Map<String, dynamic> applicant;
  final String? jobId;
  final bool isJobClosed;
  final bool viewOnly;

  const ApplicantProfilePage({
    super.key,
    required this.applicant,
    this.jobId,
    this.isJobClosed = false,
    this.viewOnly = false,
  });

  @override
  State<ApplicantProfilePage> createState() => _ApplicantProfilePageState();
}

class _ApplicantProfilePageState extends State<ApplicantProfilePage> {
  bool _isLoadingProfile = true;
  DoctorProfileData? _profile;
  String? _error;
  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profileId =
          (widget.applicant['surgeonprofile_id'] ?? '').toString().trim();
      if (profileId.isEmpty) {
        setState(() {
          _isLoadingProfile = false;
        });
        return;
      }

      final result = await ApiService.fetchProfileInfo(profileId);
      if (result['success'] == true) {
        setState(() {
          _profile = DoctorProfileData.fromMap(result['data']);
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load profile';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading profile: $e';
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _rejectApplication() async {
    // Get the surgeonprofile_id from the applicant data
    final surgeonProfileId = (widget.applicant['surgeonprofile_id'] ?? 
        widget.applicant['surgeonProfileId'] ?? 
        widget.applicant['profileId'] ?? 
        '').toString().trim();
    
    // Get the job_id from widget.jobId
    final jobId = (widget.jobId ?? '').toString().trim();
    
    if (surgeonProfileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surgeon profile ID not found')),
      );
      return;
    }
    
    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job ID not found')),
      );
      return;
    }

    setState(() => _isRejecting = true);

    try {
      // Use the correct API endpoint format: /api/jobs/applied-jobs/jobs-edit/:surgeonprofile_id/:job_id
      final uri = Uri.parse(
          '${AppConfig.apiBaseUrl}/jobs/applied-jobs/jobs-edit/$surgeonProfileId/$jobId');


      final body = {
        'status': 'rejected',
      };

      debugPrint('🔴 Rejecting application - surgeonProfileId: $surgeonProfileId, jobId: $jobId');
      debugPrint('🔴 API URL: ${uri.toString()}');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('🔴 Response status: ${response.statusCode}');
      debugPrint('🔴 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application rejected successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); 
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isRejecting = false);
        }
      }
    } catch (e) {
      debugPrint('🔴 Error rejecting application: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isRejecting = false);
      }
    }
  }

  void _confirmReject() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: const Text(
            'Are you sure you want to reject this application? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _rejectApplication();
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog() {
    String selectedDate = 'DD/MM/YYYY';
    String startTime = 'Start time';
    String endTime = 'End time';
    DateTime? pickedDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reschedule Interview'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date Picker
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (d != null) {
                          pickedDate = d;
                          setDialogState(() {
                            selectedDate = '${d.day}/${d.month}/${d.year}';
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              selectedDate,
                              style: TextStyle(
                                color: selectedDate == 'DD/MM/YYYY' ? Colors.grey : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Start Time Picker
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (t != null) {
                          setDialogState(() {
                            startTime = t.format(context);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              startTime,
                              style: TextStyle(
                                color: startTime == 'Start time' ? Colors.grey : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // End Time Picker
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (t != null) {
                          setDialogState(() {
                            endTime = t.format(context);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              endTime,
                              style: TextStyle(
                                color: endTime == 'End time' ? Colors.grey : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pickedDate == null || startTime == 'Start time' || endTime == 'End time') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select date and time')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    _rescheduleInterview(pickedDate!, startTime, endTime);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Reschedule', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rescheduleInterview(
    DateTime newDate,
    String newStartTime,
    String newEndTime,
  ) async {
    // Get the surgeon profile ID and job ID
    final surgeonProfileId = (widget.applicant['surgeonprofile_id'] ?? 
        widget.applicant['surgeonProfileId'] ?? 
        widget.applicant['profileId'] ?? 
        '').toString().trim();
    final jobId = (widget.jobId ?? '').toString().trim();

    if (surgeonProfileId.isEmpty || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing interview details. Cannot reschedule.')),
      );
      return;
    }

    // Format the date as ISO string
    final isoDate = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}T00:00:00.000+00:00';

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/interview/interview-edit/$surgeonProfileId/$jobId',

    );

    final payload = {
      'interviewDate': isoDate,
      'startTime': newStartTime,
      'endTime': newEndTime,
    };

    debugPrint('📅 Rescheduling interview: $uri');
    debugPrint('📅 Payload: $payload');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      debugPrint('📅 Reschedule response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interview rescheduled successfully!')),
        );
        // Pop back with true to refresh the list
        if (mounted) Navigator.pop(context, true);
      } else {
        String errorMsg = 'Failed to reschedule interview (${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rescheduling: $e')),
      );
    }
  }

  void _showEditStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Applicant Status'),
          content: const Text('Select the status for this applicant after the interview:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _updateApplicantStatus('rejected');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Rejected', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _updateApplicantStatus('selected');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Selected', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateApplicantStatus(String newStatus) async {
    final surgeonProfileId = (widget.applicant['surgeonprofile_id'] ?? 
        widget.applicant['surgeonProfileId'] ?? 
        widget.applicant['profileId'] ?? 
        '').toString().trim();
    final jobId = (widget.jobId ?? '').toString().trim();

    if (surgeonProfileId.isEmpty || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing details. Cannot update status.')),
      );
      return;
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/jobs/applied-jobs/jobs-edit/$surgeonProfileId/$jobId',

    );

    final payload = {
      'status': newStatus,
    };

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Applicant marked as $newStatus!')),
        );
        // Pop back with true to refresh the list
        if (mounted) Navigator.pop(context, true);
      } else {
        String errorMsg = 'Failed to update status (${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  // Check if interview date has passed
  bool _isInterviewDatePassed() {
    final interviewDateStr = widget.applicant['interviewDate']?.toString() ?? '';
    if (interviewDateStr.isEmpty) return false;
    
    try {
      final interviewDate = DateTime.parse(interviewDateStr);
      // Show Edit Status if today is after the interview date
      return DateTime.now().isAfter(interviewDate);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        (widget.applicant['firstName'] ?? widget.applicant['name'] ?? '')
            .toString();
    final lastName = (widget.applicant['lastName'] ?? '').toString();
    final fullNameFromApp = [firstName, lastName]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();

    final createdRaw =
        (widget.applicant['createdAt'] ?? widget.applicant['appliedOn'] ?? '')
            .toString();
    final appliedOn = createdRaw.contains('T')
        ? createdRaw.split('T').first
        : createdRaw;
    final status = (widget.applicant['status'] ?? '').toString();

    final isCvFromProfile = (widget.applicant['isCvFromProfile'] ?? 'false').toString().toLowerCase() == 'true';
    final manualCv = (widget.applicant['cvResume'] ?? widget.applicant['resume'] ?? widget.applicant['cv'] ?? '').toString();
    final profileCv = _profile?.cv ?? '';
    final resume = isCvFromProfile ? profileCv : manualCv;
    final location = (widget.applicant['location'] ?? '').toString();
    final notes = (widget.applicant['notes'] ?? '').toString();

    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("Applicant Profile",
              style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Profile not found', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    final displayName =
        profile != null && profile.name.isNotEmpty ? profile.name : fullNameFromApp;
    final speciality = profile?.speciality ?? '';

    final profilePic = (profile?.profilePicture ?? widget.applicant['profilePicture'] ?? widget.applicant['profilePic'] ?? widget.applicant['profileImage'] ?? '').toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Applicant Profile",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipOval(
                child: Container(
                  width: 100,
                  height: 100,
                  color: const Color(0xFFE0F0FF),
                  child: profilePic.isNotEmpty
                      ? Image.network(
                          profilePic.startsWith('http')
                              ? profilePic
                              : '${AppConfig.serverUrl}/$profilePic',

                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                              return Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.white),
                              );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0062FF),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0062FF),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Column(
                children: [
                  Text(
                    displayName.isNotEmpty ? displayName : 'Applicant Name',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    speciality.isNotEmpty ? speciality : 'Speciality not provided',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            _infoHeader("Personal Information"),
            _infoTile(Iconsax.call, "Phone", profile?.phone),
            _infoTile(Iconsax.sms, "Email", profile?.email),
            _infoTile(Iconsax.location, "Location",
                profile?.location.isNotEmpty == true ? profile!.location : location),

            const SizedBox(height: 10),
            _infoHeader("Professional Details"),
            _infoTile(Iconsax.teacher, "Degree", profile?.degree),
            _infoTile(Iconsax.briefcase, "Sub-Speciality", profile?.subSpeciality),
            _infoTile(Iconsax.building, "Organization", profile?.organization),
            _infoTile(Iconsax.verify, "Designation", profile?.designation),
            _infoTile(Iconsax.map, "Work Location", profile?.workLocation),
            _infoTile(Iconsax.clock, "Experience", profile?.period),
            _infoTile(Iconsax.link, "Portfolio", profile?.portfolio),

            const SizedBox(height: 16),
            _infoHeader("Summary"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profile != null && profile.summary.isNotEmpty
                    ? profile.summary
                    : "No summary provided",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),
            _infoHeader("Application Details"),
            _infoTile(Iconsax.calendar_1, "Applied On",
                appliedOn.isNotEmpty ? appliedOn : 'N/A'),
            _infoTile(Iconsax.info_circle, "Status",
                status.isNotEmpty ? status : 'N/A'),
            _infoTile(Iconsax.note, "Notes", notes.isNotEmpty ? notes : null),

            const SizedBox(height: 20),
            Text("Resume",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.document_text,
                      color: Colors.redAccent),
                ),
                title: Text(
                  resume.isNotEmpty
                      ? resume.split('/').last
                      : 'No resume uploaded',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  resume.isNotEmpty ? 'Tap to view' : 'No file available',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                onTap: () async {
                  if (resume.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening resume...')),
                    );
                    
                    String url = resume;
                    if (!url.startsWith('http')) {
                       url = '${AppConfig.serverUrl}/$url';

                    }

                    try {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        throw 'Could not launch $url';
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error opening resume: $e')),
                      );
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 20),
            
            // Show action buttons only if not viewOnly and job is not closed
            if (widget.viewOnly || widget.isJobClosed) ...[
              // View Only or Job Closed - Show status only, no action buttons
              if (widget.isJobClosed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Job is closed - No actions available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              // Show current status indicator
              if (status.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: status.toLowerCase() == 'rejected'
                        ? const Color(0xFFFFF3E0)
                        : status.toLowerCase().contains('interview')
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Status: ${status.isNotEmpty ? status : 'Applied'}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status.toLowerCase() == 'rejected'
                            ? Colors.orange[800]
                            : status.toLowerCase().contains('interview')
                                ? Colors.green[700]
                                : Colors.blue[700],
                      ),
                    ),
                  ),
                ),
              ],
            ] else if (status.toLowerCase() == 'selected')
              // Applicant is Selected - Show selected status indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Candidate Selected',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This applicant has been selected for the position',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              )
            else if (status.toLowerCase() == 'rejected')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF3E0),
                    disabledBackgroundColor: const Color(0xFFFFF3E0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Application Rejected',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else ...[
              // Only show Reject button if interview is NOT scheduled
              if (!status.toLowerCase().contains('interview')) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isRejecting ? null : _confirmReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isRejecting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : Text(
                            'Reject Application',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Schedule Interview Button
              status.toLowerCase().contains('interview')
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: null, // Disabled
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withValues(alpha: 0.8),
                              disabledBackgroundColor: Colors.green.withValues(alpha: 0.8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Interview Scheduled',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Show Edit Status button if interview date has passed
                        if (_isInterviewDatePassed())
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => _showEditStatusDialog(),
                              icon: const Icon(Icons.edit, size: 18),
                              label: Text(
                                'Edit Status',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () => _showRescheduleDialog(),
                              icon: const Icon(Icons.edit_calendar, size: 18),
                              label: Text(
                                'Reschedule Interview',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScheduleInterviewPage(
                                jobId: widget.jobId,
                                candidateId:
                                    (widget.applicant['surgeonprofile_id'] ?? '')
                                        .toString(),
                              ),
                            ),
                          );
                          
                          if (result == true) {
                            if (context.mounted) Navigator.pop(context, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0062FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Schedule Interview',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0062FF),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
}

class ApplicantsOverview extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> applicantsByJobId;
  const ApplicantsOverview({super.key, required this.applicantsByJobId});

  @override
  Widget build(BuildContext context) {
    final total = applicantsByJobId.values.fold<int>(0, (p, e) => p + e.length);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Applicants",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Total applicants across jobs: $total",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: applicantsByJobId.entries
                    .map(
                      (e) => Card(
                        child: ListTile(
                          title: Text(e.key),
                          subtitle: Text("${e.value.length} applicants"),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApplicantsListPage(
                                  jobId: e.key,
                                  jobTitle: e.key,
                                  applicants: e.value,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostJobPlaceholder extends StatelessWidget {
  const PostJobPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text("Post Job (placeholder)")));
  }
}

class InterviewsPlaceholder extends StatelessWidget {
  final void Function(BuildContext) onScheduleInterview;
  const InterviewsPlaceholder({super.key, required this.onScheduleInterview});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            "Interviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => onScheduleInterview(context),
            child: const Text("Schedule Interview (global)"),
          ),
        ],
      ),
    );
  }
}
                                    