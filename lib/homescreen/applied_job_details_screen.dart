import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:doc/utils/app_config.dart';
import 'package:logger/logger.dart';


class AppliedJobDetailsScreen extends StatefulWidget {
  final String jobId;

  const AppliedJobDetailsScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<AppliedJobDetailsScreen> createState() => _AppliedJobDetailsScreenState();
}

class _AppliedJobDetailsScreenState extends State<AppliedJobDetailsScreen> {
  final _logger = Logger();
  Map<String, dynamic> _jobData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/job-profile/${widget.jobId}');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _logger.i("AppliedJobDetailsScreen: fetched job data for ${widget.jobId}: $body");
        final data = body is Map && body['data'] != null ? body['data'] : body;
        if (data is Map<String, dynamic>) {
          if (mounted) {
            setState(() {
              _jobData = data;
              _isLoading = false;
            });
          }
        } else {
           _logger.e("AppliedJobDetailsScreen: Invalid data format");
           if (mounted) {
            setState(() {
              _error = 'Invalid data format';
              _isLoading = false;
            });
           }
        }
      } else {
        _logger.e("AppliedJobDetailsScreen: Failed Fetch ${response.statusCode}");
        if (mounted) {
          setState(() {
            _error = 'Failed to fetch job details: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching job details: $e';
          _isLoading = false;
        });
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

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
           backgroundColor: Colors.white,
           elevation: 0,
           leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: Text(_error!)),
      );
    }
    
    final job = _jobData;
    final title = job['jobTitle'] ?? job['title'] ?? 'Job Title';
    final postedOn = job['postedOn'] ?? ''; 
    
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
    final designation = (job['designation'] != null && job['designation'].toString().trim().isNotEmpty)
        ? job['designation'].toString()
        : null;
    final recruiter = (job['recruiter'] != null && job['recruiter'].toString().trim().isNotEmpty)
        ? job['recruiter'].toString()
        : null;
    final salary = job['salaryRange'] ?? 'Salary';
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
    
    // Hospital Name handling
    String hospitalName = "Hospital"; 
    if (job['healthcare_id'] is Map) {
       hospitalName = job['healthcare_id']['hospitalName'] ?? job['healthcare_id']['name'] ?? "Hospital";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16),
                        SizedBox(width: 6),
                        Text("Back", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  if (postedOn.isNotEmpty)
                    Text(
                      "Posted on $postedOn",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     const SizedBox(height: 6),
                     Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        image: job['hospitalLogo'] != null &&
                                job['hospitalLogo'].toString().isNotEmpty &&
                                !job['hospitalLogo'].toString().contains('null')
                            ? DecorationImage(
                                image: NetworkImage(job['hospitalLogo']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: job['hospitalLogo'] == null ||
                              job['hospitalLogo'].toString().isEmpty ||
                              job['hospitalLogo'].toString().contains('null')
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset('assets/logo.png'), 
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: _iconText(Icons.local_hospital, hospitalName)),
                        const SizedBox(width: 18),
                        Flexible(child: _iconText(
                          Icons.location_on_outlined,
                          location,
                        )),
                        const SizedBox(width: 18),
                        Flexible(child: _iconText(Icons.school, experience)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Full Time + Salary Pill
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0062FF), Color(0xFF3E8BFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.work, color: Colors.white, size: 26),
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
                          Container(
                            width: 1,
                            height: 45,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.currency_rupee, color: Colors.white, size: 26),
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
                    _sectionText(responsibilities),
                    _sectionTitle("Preferred Qualifications:"),
                    _sectionText(qualifications),
                    _sectionTitle("Application Deadline:"),
                    _sectionText(deadline),
                    const SizedBox(height: 40),
                    // No Apply button here as per requirements since it's "Applied" jobs view
                  ],
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
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
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
}
