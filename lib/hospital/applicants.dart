import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
import 'package:doc/utils/app_config.dart';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:doc/profileprofile/surgeon_form.dart';
import 'package:doc/navbar.dart';
import 'package:doc/model/indian_states_districts.dart';

class Applicants extends StatefulWidget {
  final String? healthcareId;

  const Applicants({super.key, this.healthcareId});

  @override
  State<Applicants> createState() => _ApplicantsState();
}

class _ApplicantsState extends State<Applicants> {
  final TextEditingController jobTitleCtrl = TextEditingController();
  final TextEditingController aboutCtrl = TextEditingController();
  final TextEditingController responsibilitiesCtrl = TextEditingController();
  final TextEditingController qualificationCtrl = TextEditingController();
  final TextEditingController experienceCtrl = TextEditingController();
  


  // Hospital Profile Logic
  String _hospitalName = '';
  String? _hospitalLogoUrl;
  bool _isKYCVerified = true; // Default to true to avoid showing banner incorrectly

  // State and District for job location
  String? selectedState;
  String? selectedDistrict;
  List<String> districts = [];

  final TextEditingController deadlineCtrl = TextEditingController();

  String? department;
  String? subSpeciality;
  String? jobType;
  String? interviewMode;
  String? salaryRange;
  String? selectedExperience;
  String? selectedDesignation;
  String? selectedRecruiter;

  final List<String> designationOptions = [
    "Fellowship",
    "Senior Resident / Registrar",
    "Assistant / Associate Professor",
    "Associate Consultant",
    "Consultant / Professor",
    "Senior Consultant / Professor / Lead",
    "HOD / Chairman",
  ];

  final List<String> recruiterOptions = [
    "HR / Management",
    "HOD / Senior Consultant / Hospital Owner",
    "Co-surgeon / Doctor",
  ];

  bool agree = false;

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchHospitalProfile();
  }

  Future<void> _fetchHospitalProfile() async {
    try {
      String? id = widget.healthcareId;
      if (id == null || id.isEmpty) {
        id = await SessionManager.getHealthcareId();
      }
      if (id == null || id.isEmpty) {
        id = await SessionManager.getProfileId();
      }

      if (id != null && id.isNotEmpty) {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$id');

        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final data = body is Map && body['data'] != null ? body['data'] : body;
          if (data is Map) {
             final name = data['hospitalName'] ?? data['name'] ?? data['organizationName'];
             final logo = data['hospitalLogo'];
             final kycVerified = data['isKYCVerified'];
             if (mounted) {
               setState(() {
                 if (name != null) _hospitalName = name.toString();
                 if (logo != null) _hospitalLogoUrl = logo.toString();
                 _isKYCVerified = kycVerified == true;
               });
             }
          }
        }
      } else {
        // Handle case where ID is null
      }
    } catch (e) {
      debugPrint('Error fetching hospital name: $e');
    }
  }

  // ------------------ DATE PICKER ------------------
  Future<void> pickDeadline() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4AB3F4)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Store in YYYY-MM-DD format so backend can parse it as a Date
        deadlineCtrl.text =
            "${picked.year.toString().padLeft(4, '0')}-"
            "${picked.month.toString().padLeft(2, '0')}-"
            "${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }
  // --------------------------------------------------

  Future<void> _submitJob() async {
    if (!agree || isSubmitting) return;

    final title = jobTitleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job title')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // Get healthcare_id from multiple sources
      final storedHealthcareId = await SessionManager.getHealthcareId();
      final storedProfileId = await SessionManager.getProfileId();
      final storedUserId = await SessionManager.getUserId();
      
      debugPrint('🩺 Stored healthcare_id: $storedHealthcareId');
      debugPrint('🩺 Stored profile_id: $storedProfileId');
      debugPrint('🩺 Stored user_id: $storedUserId');
      debugPrint('🩺 Widget healthcare_id: ${widget.healthcareId}');

      // Priority: widget.healthcareId > storedHealthcareId > storedProfileId > storedUserId
      String? healthcareId;
      if (widget.healthcareId != null && widget.healthcareId!.isNotEmpty) {
        healthcareId = widget.healthcareId!;
        debugPrint('🩺 Using healthcare_id from widget: $healthcareId');
      } else if (storedHealthcareId != null && storedHealthcareId.isNotEmpty) {
        healthcareId = storedHealthcareId;
        debugPrint('🩺 Using healthcare_id from session: $healthcareId');
      } else if (storedProfileId != null && storedProfileId.isNotEmpty) {
        healthcareId = storedProfileId;
        debugPrint('🩺 Using profile_id as healthcare_id: $healthcareId');
      } else if (storedUserId != null && storedUserId.isNotEmpty) {
        healthcareId = storedUserId;
        debugPrint('🩺 Using user_id as healthcare_id: $healthcareId');
      }

      if (healthcareId == null || healthcareId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log out and log in again.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isSubmitting = false);
        return;
      }

      // ---------------------------------------------------------
      // 🛡️ SECURITY & STABILITY CHECK
      // Verify the healthcare_id is valid BEFORE posting
      // This prevents "profile corruption" caused by posting with invalid IDs
      // ---------------------------------------------------------
      String finalHealthcareId = healthcareId;
      bool idVerified = false;

      debugPrint('🩺 🛡️ Verifying healthcare_id: $finalHealthcareId');
      
      try {
        // 1. Check if current ID works
        final checkUri = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$finalHealthcareId');
        final checkResp = await http.get(checkUri).timeout(const Duration(seconds: 5));
        
        if (checkResp.statusCode == 200) {
          final body = jsonDecode(checkResp.body);
          final data = (body is Map && body['data'] != null) ? body['data'] : body;
          if (data is Map && (data['hospitalName'] != null || data['email'] != null)) {
            debugPrint('🩺 🛡️ ID $finalHealthcareId is VALID');
            idVerified = true;
          }
        }
      } catch (e) {
        debugPrint('🩺 🛡️ ID check failed: $e');
      }

      // 2. If ID is invalid, try to recover via Email
      if (!idVerified) {
        debugPrint('🩺 ⚠️ ID $finalHealthcareId seems invalid. Attempting recovery via email...');
        final userEmail = await SessionManager.getUserEmail();
        
        if (userEmail != null && userEmail.isNotEmpty) {
          try {
            final emailUri = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/email/$userEmail');

            final emailResp = await http.get(emailUri).timeout(const Duration(seconds: 5));
            
            if (emailResp.statusCode == 200) {
              final body = jsonDecode(emailResp.body);
              final data = (body is Map && body['data'] != null) ? body['data'] : body;
              
              if (data is Map) {
                // PRIORITY: healthcare_id first (that's what edit API uses)
                final recoveredId = data['healthcare_id'] ?? data['healthcareId'] ?? data['_id'];
                if (recoveredId != null) {
                  debugPrint('🩺 ✅ Recovered valid healthcare_id via email: $recoveredId');
                  finalHealthcareId = recoveredId.toString();
                  await SessionManager.saveHealthcareId(finalHealthcareId);
                  idVerified = true;
                }
              }
            }
          } catch (e) {
            debugPrint('🩺 ❌ Email recovery failed: $e');
          }
        } else {
          debugPrint('🩺 ⚠️ No user email found for recovery');
        }
      }

      if (!idVerified) {
        debugPrint('🩺 ⚠️ Proceeding with unverified ID: $finalHealthcareId (Risk of failure)');
      }
      // ---------------------------------------------------------

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/jobpost');

      final Map<String, String> payload = {
        'jobTitle': jobTitleCtrl.text.trim(),
        'designation': selectedDesignation ?? '',
        'recruiter': selectedRecruiter ?? '',
        'department': department ?? '',
        'subSpeciality': subSpeciality ?? '',
        'jobType': jobType ?? '',
        'state': selectedState ?? '',
        'district': selectedDistrict ?? '',
        'aboutRole': aboutCtrl.text.trim(),
        'keyResponsibilities': responsibilitiesCtrl.text.trim(),
        'preferredQualifications': qualificationCtrl.text.trim(),
        'minYearsOfExperience': selectedExperience ?? '',
        'salaryRange': salaryRange ?? '',
        'interviewMode': interviewMode ?? '',
        'applicationDeadline': deadlineCtrl.text.trim(),
        'healthcare_id': finalHealthcareId, // Use the verified ID
        'status': 'Active', // Default status for new jobs
      };

      debugPrint('🩺 Final healthcare_id being sent: $healthcareId');
      
      // Get auth token
      final token = await SessionManager.getToken();
      
      // ✅ Use MultipartRequest for job image
      var request = http.MultipartRequest('POST', uri);
      
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.fields.addAll(payload);



      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);

      debugPrint('🩺 Response status: ${resp.statusCode}');
      debugPrint('🩺 Response body: ${resp.body}');

      if (!mounted) return;

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Job posted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Redirect to My Jobs screen (Navbar)
          // We need to pass valid hospitalData. We have healthcare_id.
          final Map<String, dynamic> navData = {
            'healthcare_id': finalHealthcareId,
            'hospitalName': _hospitalName,
            'hospitalLogo': _hospitalLogoUrl,
            'isKYCVerified': _isKYCVerified, // Include KYC status to prevent banner from showing incorrectly
          };

          // We use pushAndRemoveUntil to reset the stack and go to the Navbar (which defaults to Tab 0 - My Jobs)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => Navbar(hospitalData: navData),
            ),
            (route) => false,
          );
        } else {
        // Parse error message from backend
        String errorMsg = 'Failed to post job';
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map) {
            errorMsg = decoded['message']?.toString() ?? 
                      decoded['error']?.toString() ?? 
                      'Failed to post job (${resp.statusCode})';
          }
        } catch (_) {
          errorMsg = 'Failed to post job (${resp.statusCode})';
        }

        debugPrint('🩺 Error: $errorMsg');

        // Check if it's a healthcare_id issue
        if (errorMsg.toLowerCase().contains('healthcare') || 
            errorMsg.toLowerCase().contains('hospital') ||
            errorMsg.toLowerCase().contains('not found')) {
          
          // Try to fetch the profile to see what's wrong
          try {
            final profileUri = Uri.parse(
              '${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$healthcareId',
            );

            final profileResp = await http.get(profileUri).timeout(const Duration(seconds: 5));
            
            debugPrint('🩺 Profile check status: ${profileResp.statusCode}');
            debugPrint('🩺 Profile check body: ${profileResp.body}');
            
            if (profileResp.statusCode != 200) {
              errorMsg = 'Hospital profile not found. Please complete your hospital profile first.';
            } else {
              // Profile exists but job post failed - might be ID mismatch
              try {
                final profileData = jsonDecode(profileResp.body);
                final data = (profileData is Map && profileData['data'] != null) 
                    ? profileData['data'] 
                    : profileData;
                
                if (data is Map) {
                  final backendHealthcareId = data['healthcare_id']?.toString() ?? 
                                             data['healthcareId']?.toString() ?? 
                                             data['_id']?.toString() ?? '';
                  
                  debugPrint('🩺 Backend healthcare_id: $backendHealthcareId');
                  debugPrint('🩺 Sent healthcare_id: $healthcareId');
                  
                  if (backendHealthcareId.isNotEmpty && backendHealthcareId != healthcareId) {
                    // ID mismatch! Save the correct one and retry
                    await SessionManager.saveHealthcareId(backendHealthcareId);
                    errorMsg = 'ID mismatch detected. Please try posting the job again.';
                  }
                }
              } catch (e) {
                debugPrint('🩺 Error parsing profile: $e');
              }
            }
          } catch (e) {
            debugPrint('🩺 Error checking profile: $e');
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('🩺 Exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Post a job opening",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- HEADER CARD ----------


            const Text("Find the right surgeon for your team.\n"),



            _label("Job Title"),
            _input(jobTitleCtrl, "e.g., Consultant Orthopedic Surgeon"),

            _label("Designation"),
            _dropdown(
              value: selectedDesignation,
              hint: "Select Designation",
              items: designationOptions,
              onChanged: (v) => setState(() => selectedDesignation = v),
            ),

            _label("Speciality"),
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search Speciality",
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              items: surgicalSpecialities.keys.toList(),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: "Select Speciality",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
                  ),
                ),
              ),
              selectedItem: department,
              onChanged: (value) {
                setState(() {
                  department = value;
                  subSpeciality = null; // Reset sub-speciality
                });
              },
            ),

            if (department != null &&
                (surgicalSpecialities[department] ?? []).isNotEmpty) ...[
              _label("Sub-Speciality"),
              DropdownSearch<String>(
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Search Sub-speciality",
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                items: surgicalSpecialities[department] ?? [],
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    hintText: "Select Sub-speciality",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
                    ),
                  ),
                ),
                selectedItem: subSpeciality,
                onChanged: (value) {
                  setState(() {
                    subSpeciality = value;
                  });
                },
              ),
            ],

            _label("Job Type"),
            _dropdown(
              value: jobType,
              hint: "Job Type",
              items: ["Full Time", "Part Time/Locum", "Fee for service"],
              onChanged: (v) => setState(() => jobType = v),
            ),

            _label("Recruiter Role / Posted By"),
            _dropdown(
              value: selectedRecruiter,
              hint: "Select Recruiter Role",
              items: recruiterOptions,
              onChanged: (v) => setState(() => selectedRecruiter = v),
            ),

            _label("State"),
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search State",
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              items: IndianStatesAndDistricts.data.keys.toList(),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: "Select State",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
                  ),
                ),
              ),
              selectedItem: selectedState,
              onChanged: (value) {
                setState(() {
                  selectedState = value;
                  districts = IndianStatesAndDistricts.data[value] ?? [];
                  selectedDistrict = null; // Reset district when state changes
                });
              },
            ),

            _label("District"),
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search District",
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              items: districts,
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: "Select District",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
                  ),
                ),
              ),
              selectedItem: selectedDistrict,
              enabled: selectedState != null, // Disable if no state selected
              onChanged: (value) {
                setState(() {
                  selectedDistrict = value;
                });
              },
            ),

            _label("About the Role"),
            _input(aboutCtrl, "Brief description about the role", maxLines: 4),

            _label("Key Responsibilities"),
            _input(
              responsibilitiesCtrl,
              "Detailed responsibilities & expectations",
              maxLines: 4,
            ),

            _label("Preferred Qualifications"),
            _input(qualificationCtrl, "e.g., MS Orthopedics, MCh Neurosurgery"),

            _label("Minimum Years of Experience Required"),
            _dropdown(
              value: selectedExperience,
              hint: "Select Experience (Years)",
              items: List.generate(31, (index) => index.toString()),
              onChanged: (v) => setState(() => selectedExperience = v),
            ),

            _label("Salary Range"),
            _dropdown(
              value: salaryRange,
              hint: "Select Salary Range",
              items: [
                "5 - 10 LPA",
                "10 - 15 LPA",
                "15 - 20 LPA",
                "20 - 25 LPA",
                "25 - 30 LPA",
                "30 - 35 LPA",
                "35 - 40 LPA",
                "40 - 45 LPA",
                "45 - 50 LPA",
                "50 - 60 LPA",
                "60 - 70 LPA",
                "70 - 80 LPA",
                "80 - 90 LPA",
                "90+ LPA",
                "Negotiable",
                "Not Disclosed"
              ],
              onChanged: (v) => setState(() => salaryRange = v),
            ),

            _label("Interview Mode"),
            _dropdown(
              value: interviewMode,
              hint: "Interview Mode",
              items: ["In-person", "Online"],
              onChanged: (v) => setState(() => interviewMode = v),
            ),

            _label("Application Deadline:"),
            TextField(
              controller: deadlineCtrl,
              readOnly: true,
              onTap: pickDeadline,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.calendar_today,
                  color: Colors.grey,
                ),
                hintText: "DD/MM/YYYY",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Checkbox(
                  value: agree,
                  onChanged: (v) => setState(() => agree = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    "I confirm that the information provided is accurate and complies with the platform's posting guidelines.",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: agree && !isSubmitting ? _submitJob : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Post Job", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ---------------- Helper Widgets ----------------

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 18),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _input(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
