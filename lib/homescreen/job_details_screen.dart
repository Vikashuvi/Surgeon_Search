import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/app_config.dart';

import 'package:file_picker/file_picker.dart';
import 'package:doc/utils/colors.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:get/get.dart';

void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔵 Title Row (Clean & Identical to Screenshot)
              Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Application Submitted",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ✨ Message Texts
              const Text(
                "Thank you for applying!",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your job has been saved under 'Applied Jobs'.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

              const SizedBox(height: 25),

              /// 🔘 OK Button (Right-aligned like screenshot)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showAlreadyAppliedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.orange, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Application Check",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "You have already applied for this job.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 25),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _job;

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
          '${AppConfig.apiBaseUrl}/healthcare/job-profile/${widget.jobId}');

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

        Map<String, dynamic> jobMap = <String, dynamic>{};
        if (data is Map) {
          jobMap = Map<String, dynamic>.from(data);
        }

        setState(() {
          _job = jobMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load job details (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading job details: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _submitApplication({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String location,
    String? linkedIn,
    String? notes,
    PlatformFile? cvFile,
    bool isCvFromProfile = false,
  }) async {
    try {
      final surgeonProfileId = await SessionManager.getProfileId();
      if (surgeonProfileId == null || surgeonProfileId.isEmpty) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile id not found. Please login again.'),
          ),
        );
        return false;
      }

      final job = _job ?? {};
      final healthcareId = (job['healthcare_id'] ??
              job['healthcareId'] ??
              job['healthcareProfileId'] ??
              '')
          .toString();

      if (healthcareId.isEmpty) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Healthcare ID is missing for this job. Cannot apply.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      final url =
          Uri.parse('${AppConfig.apiBaseUrl}/jobs/apply');

// Removed debug print
      
      final request = http.MultipartRequest('POST', url);

      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['phone'] = phone;
      request.fields['email'] = email;
      request.fields['location'] = location;
      request.fields['linkedIn'] = linkedIn ?? '';
      request.fields['notes'] = notes ?? '';
      request.fields['healthcare_id'] = healthcareId;
      request.fields['surgeonprofile_id'] = surgeonProfileId;
      request.fields['job_id'] = widget.jobId;
      request.fields['isCvFromProfile'] = isCvFromProfile.toString();

// Removed debug print

      if (cvFile != null && cvFile.path != null && cvFile.path!.isNotEmpty) {
// Removed debug print
        request.files.add(
          await http.MultipartFile.fromPath('cv', cvFile.path!),
        );
      } else {
// Removed debug print
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

// Removed debug print
// Removed debug print

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        if (!mounted) return false;
        String msg = 'Failed to submit application (${response.statusCode})';
        try {
          final body = response.body.trimLeft();
          final decoded = jsonDecode(body);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}
        
        if (msg.toLowerCase().contains('already applied')) {
          _showAlreadyAppliedDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
        return false;
      }
    } catch (e) {
// Removed debug print
// Removed debug print
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting application: $e')),
      );
      return false;
    }
  }

  void _showApplyFormDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    // lastNameController removed
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final linkedinController = TextEditingController();
    final notesController = TextEditingController();

    // Auto-fetch user details
    SessionManager.getUserEmail().then((email) {
      if (email != null && email.isNotEmpty) {
        emailController.text = email;
      }
    });
    SessionManager.getUserPhone().then((phone) {
      if (phone != null && phone.isNotEmpty) {
        phoneController.text = phone;
      }
    });
    SessionManager.getUserName().then((name) {
      if (name != null && name.isNotEmpty) {
        firstNameController.text = name;
      }
    });

    // Attempt to fetch profile name if possible, or just use what we have
    // Since we don't have a direct "getUserName" in SessionManager shown in context, 
    // we might need to rely on what's available or fetch profile. 
    // However, the user asked to auto-fetch "first name".
    // Let's try to fetch profile info to get the name if not readily available.
    SessionManager.getProfileId().then((pid) async {
      if (pid != null) {
        try {
           final url = Uri.parse('${AppConfig.apiBaseUrl}/sugeon/profile-info/$pid');

           final response = await http.get(url);
           if (response.statusCode == 200) {
             final data = jsonDecode(response.body);
             final p = data['data'] is Map && data['data']['profile'] != null 
                 ? data['data']['profile'] 
                 : (data['data'] is Map ? data['data'] : {});
             
             if (p is Map) {
               final fullName = (p['fullName'] ?? 
                                 p['fullname'] ?? 
                                 p['name'] ?? 
                                 p['username'] ?? 
                                 '').toString();
               if (fullName.isNotEmpty) {
                 firstNameController.text = fullName; // Using full name as first name field
               }
               // Also ensure phone/email are set if session didn't have them
               if (phoneController.text.isEmpty) {
                  phoneController.text = (p['phoneNumber'] ?? 
                                          p['phone'] ?? 
                                          p['mobile'] ?? 
                                          p['mobileNumber'] ?? 
                                          p['mobilenumber'] ?? 
                                          '').toString();
               }
               if (emailController.text.isEmpty) {
                  emailController.text = (p['email'] ?? '').toString();
               }
             }
           }
        } catch (_) {}
      }
    });

    String selectedLocation = 'Bangalore, India';
    PlatformFile? selectedFile;
    String? selectedFileName;
    bool isCvFromProfile = false;
    bool isFetchingCv = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Apply for this position',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              hintText: 'Full Name', // Changed to Full Name as we removed Last Name
                              filled: true,
                              fillColor: Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '(+91) 98765 43210',
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'yourname@example.com',
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Bangalore, India',
                          child: Text('Bangalore, India'),
                        ),
                        DropdownMenuItem(
                          value: 'Chennai, India',
                          child: Text('Chennai, India'),
                        ),
                        DropdownMenuItem(
                          value: 'Hyderabad, India',
                          child: Text('Hyderabad, India'),
                        ),
                        DropdownMenuItem(
                          value: 'Delhi, India',
                          child: Text('Delhi, India'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLocation = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Upload CV/Resume',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Manual Upload Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf', 'doc', 'docx'],
                              );
                              if (result != null && result.files.isNotEmpty) {
                                setState(() {
                                  selectedFile = result.files.first;
                                  selectedFileName = selectedFile!.name;
                                  isCvFromProfile = false;
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: const BorderSide(color: Colors.black54),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    selectedFileName ?? 'CV/Resume',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.upload_file,
                                    size: 20, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Fetch from Profile Button
                        Expanded(
                          child: ElevatedButton(
                                    onPressed: isFetchingCv
                                        ? null
                                        : () async {
// Removed debug print
                                            setState(() {
                                              isFetchingCv = true;
                                            });
                                            try {
                                              final pid = await SessionManager.getProfileId();
// Removed debug print
                                              if (pid == null) {
                                                throw 'Profile ID not found';
                                              }
                                              final url = Uri.parse(
                                                  '${AppConfig.apiBaseUrl}/sugeon/profile-info/$pid');

                                              final response = await http.get(url);
// Removed debug print
// Removed debug print
                                              
                                              if (response.statusCode == 200) {
                                                final data = jsonDecode(response.body);
                                                
                                                Map<String, dynamic> p = {};
                                                if (data is Map<String, dynamic>) {
                                                  if (data.containsKey('cv')) {
                                                     // Root object is the profile
                                                     p = data;
                                                  } else if (data['data'] is Map) {
                                                     final d = data['data'];
                                                     if (d['profile'] is Map) {
                                                       p = d['profile'];
                                                     } else {
                                                       p = d;
                                                     }
                                                  }
                                                }
                                                
// Removed debug print
// Removed debug print

                                                final cvUrl = p['cv'];
                                                if (cvUrl != null && cvUrl.toString().isNotEmpty) {
                                                  // Successfully found CV in profile
                                                  setState(() {
                                                    selectedFile = null; // Clear manual file
                                                    selectedFileName = 'CV from Profile';
                                                    isCvFromProfile = true;
                                                  });

                                                  Get.snackbar(
                                                    'Success',
                                                    'CV selected from profile!',
                                                    snackPosition: SnackPosition.TOP,
                                                    backgroundColor: Colors.green,
                                                    colorText: Colors.white,
                                                    margin: const EdgeInsets.all(10),
                                                    borderRadius: 8,
                                                    duration: const Duration(seconds: 2),
                                                  );
                                                } else {
                                                  Get.snackbar(
                                                    'Info',
                                                    'CV not found in profile. Please upload one.',
                                                    snackPosition: SnackPosition.TOP,
                                                    backgroundColor: Colors.orange,
                                                    colorText: Colors.white,
                                                    margin: const EdgeInsets.all(10),
                                                    borderRadius: 8,
                                                    duration: const Duration(seconds: 3),
                                                  );
                                                }
                                              } else {
                                                throw 'Failed to fetch profile info';
                                              }
                                            } catch (e) {
                                              Get.snackbar(
                                                'Error',
                                                e.toString(),
                                                snackPosition: SnackPosition.TOP,
                                                backgroundColor: Colors.red,
                                                colorText: Colors.white,
                                                margin: const EdgeInsets.all(10),
                                                borderRadius: 8,
                                                duration: const Duration(seconds: 3),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(() {
                                                  isFetchingCv = false;
                                                });
                                              }
                                            }
                                          },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0062FF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isFetchingCv
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    'Fetch from Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Selected: $selectedFileName',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ],
                    const SizedBox(height: 16),

                    const Text(
                      'LinkedIn',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: linkedinController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.link, color: AppColors.primary),
                        hintText: 'LinkedIn Profile URL',
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Add Notes:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Type here...',
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final fullName = firstNameController.text.trim();
                              final phone = phoneController.text.trim();
                              final email = emailController.text.trim();

                              if (fullName.isEmpty ||
                                  phone.isEmpty ||
                                  email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please fill at least full name, phone and email.'),
                                  ),
                                );
                                return;
                              }

                              String fName = fullName;
                              String lName = '';
                              if (fullName.contains(' ')) {
                                int idx = fullName.lastIndexOf(' ');
                                fName = fullName.substring(0, idx).trim();
                                lName = fullName.substring(idx + 1).trim();
                              }
                              
                              // Fallback for empty last name if backend requires it
                              if (lName.isEmpty) {
                                lName = '.';
                              }

                                final ok = await _submitApplication(
                                firstName: fName,
                                lastName: lName,
                                phone: phone,
                                email: email,
                                location: selectedLocation,
                                linkedIn: linkedinController.text.trim(),
                                notes: notesController.text.trim(),
                                cvFile: selectedFile,
                                isCvFromProfile: isCvFromProfile,
                              );

                              if (ok) {
                                if (ctx.mounted && Navigator.of(ctx).canPop()) {
                                  Navigator.of(ctx).pop();
                                }
                                if (context.mounted) {
                                  _showSuccessDialog(context);
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.send,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Submit Application',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawSalary = (_job?['salaryRange'] ?? '').toString();
    final String salaryPillDisplay =
        rawSalary.isNotEmpty ? '₹ $rawSalary LPA' : '';

    final rawDeadline = ((_job?['deadline'] ??
                _job?['applicationDeadline'] ??
                _job?['jobDeadline']) ?? '')
            .toString()
            .trim();
    String deadlineDisplay = rawDeadline;
    if (deadlineDisplay.contains('T')) {
      deadlineDisplay = deadlineDisplay.split('T').first;
    } else if (deadlineDisplay.contains(' ')) {
      deadlineDisplay = deadlineDisplay.split(' ').first;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Job Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _job == null
                  ? const Center(child: Text('Job not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: Builder(
                              builder: (context) {
                                String? logoUrl = (_job!['hospitalLogo'] ?? '').toString();
                                if (logoUrl.isEmpty && _job!['healthcare_id'] is Map) {
                                  final hc = _job!['healthcare_id'];
                                  logoUrl = (hc['profilePicture'] ?? hc['logo'] ?? '').toString();
                                }
                                
                                if (logoUrl.isNotEmpty) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(40), // Circular or rounded
                                    child: Image.network(
                                      logoUrl,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/logo.png',
                                          height: 80,
                                        );
                                      },
                                    ),
                                  );
                                } else {
                                  return Image.asset(
                                    'assets/logo.png',
                                    height: 80,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (_job!['jobTitle'] ?? '').toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (_job!['healthcareName'] ??
                                    _job!['hospitalName'] ??
                                    '')
                                .toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (_job!['location'] ?? '').toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),

                          const SizedBox(height: 16),

                          // Meta info chips (job type, department, speciality, salary)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if ((_job!['jobType'] ?? '').toString().isNotEmpty)
                                _chip((_job!['jobType'] ?? '').toString()),
                              if ((_job!['department'] ?? '').toString().isNotEmpty)
                                _chip((_job!['department'] ?? '').toString()),
                              if ((_job!['subSpeciality'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                _chip((_job!['subSpeciality'] ?? '').toString()),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Full Time + Salary pill (Figma-style)
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
                                      const Icon(
                                        Icons.work,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        (_job!['jobType'] ?? 'Full Time')
                                            .toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 45,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        salaryPillDisplay.isNotEmpty
                                            ? salaryPillDisplay
                                            : (_job!['salaryRange'] ?? '')
                                                .toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Detailed sections (left-aligned like Figma)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((_job!['designation'] ?? '').toString().trim().isNotEmpty) ...[
                                  _sectionTitle('Designation'),
                                  _sectionBody(
                                    (_job!['designation'] ?? '').toString().trim(),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                if ((_job!['recruiter'] ?? _job!['postedBy'] ?? '').toString().trim().isNotEmpty) ...[
                                  _sectionTitle('Posted By / Recruiter'),
                                  _sectionBody(
                                    (_job!['recruiter'] ?? _job!['postedBy'] ?? '').toString().trim(),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                _sectionTitle('Department'),
                                _sectionBody(
                                  (_job!['department'] ?? '').toString().trim(),
                                ),
                                const SizedBox(height: 12),

                                _sectionTitle('Sub-speciality'),
                                _sectionBody(
                                  (_job!['subSpeciality'] ?? '')
                                      .toString()
                                      .trim(),
                                ),
                                const SizedBox(height: 12),

                                _sectionTitle('Interview Mode'),
                                _sectionBody(
                                  (_job!['interviewMode'] ?? 'In-person')
                                      .toString()
                                      .trim(),
                                ),
                                const SizedBox(height: 16),

                                _sectionTitle('About Role'),
                                _sectionBody(
                                  (_job!['aboutRole'] ?? '')
                                      .toString()
                                      .trim(),
                                ),
                                const SizedBox(height: 16),

                                _sectionTitle('Key Responsibilities'),
                                _sectionBody(
                                  (_job!['keyResponsibilities'] ?? '')
                                      .toString()
                                      .trim(),
                                ),
                                const SizedBox(height: 16),

                                _sectionTitle('Preferred Qualifications'),
                                _sectionBody(
                                  (_job!['preferredQualifications'] ?? '')
                                      .toString()
                                      .trim(),
                                ),
                                const SizedBox(height: 16),

                                _sectionTitle('Experience Required'),
                                _sectionBody(
                                  'Minimum ${( _job!['minYearsOfExperience'] ?? '').toString()} years',
                                ),
                                const SizedBox(height: 16),

                                _sectionTitle('Application Deadline'),
                                _sectionBody(
                                  deadlineDisplay,
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showApplyFormDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Apply Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD6EDFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _sectionBody(String text) {
    if (text.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'Not specified',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }
}
