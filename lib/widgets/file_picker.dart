import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doc/utils/colors.dart';

class JobDetailsScreen extends StatefulWidget {
  final String title;
  final String org;
  final String location;
  final String applicants;
  final String logo;

  const JobDetailsScreen({
    super.key,
    required this.title,
    required this.org,
    required this.location,
    required this.applicants,
    required this.logo,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool alreadyApplied = false;
  String? appliedDate;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyApplied();
  }

  /// 🔹 Check if this job is already applied
  Future<void> _checkIfAlreadyApplied() async {
    final prefs = await SharedPreferences.getInstance();
    final appliedJobs = prefs.getStringList('applied_jobs') ?? [];

    for (var job in appliedJobs) {
      final decoded = jsonDecode(job);
      if (decoded['title'] == widget.title &&
          decoded['org'] == widget.org &&
          decoded['location'] == widget.location) {
        setState(() {
          alreadyApplied = true;
          appliedDate = decoded['date'];
        });
        break;
      }
    }
  }

  /// ✅ Save applied job locally
  Future<void> _saveAppliedJob(
    String title,
    String org,
    String location,
    String? resume,
    String appliedFrom,
    String? linkedin,
    String? notes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('applied_jobs') ?? [];

    final newJob = jsonEncode({
      'title': title,
      'org': org,
      'location': location,
      'resume': resume ?? '',
      'linkedin': linkedin ?? '',
      'notes': notes ?? '',
      'appliedFrom': appliedFrom,
      'date': DateTime.now().toIso8601String(),
    });

    existing.add(newJob);
    await prefs.setStringList('applied_jobs', existing);

    setState(() {
      alreadyApplied = true;
      appliedDate = DateTime.now().toIso8601String();
    });
  }

  /// ❌ Withdraw Application
  Future<void> _withdrawApplication() async {
    final prefs = await SharedPreferences.getInstance();
    final appliedJobs = prefs.getStringList('applied_jobs') ?? [];

    appliedJobs.removeWhere((job) {
      final decoded = jsonDecode(job);
      return decoded['title'] == widget.title &&
          decoded['org'] == widget.org &&
          decoded['location'] == widget.location;
    });

    await prefs.setStringList('applied_jobs', appliedJobs);

    setState(() {
      alreadyApplied = false;
      appliedDate = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Application withdrawn successfully."),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ Success dialog
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, //  <-- ADD THIS LINE
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 26),
            SizedBox(width: 10),
            Text(
              "Application Submitted 🎉",
              style: TextStyle(
                fontWeight: FontWeight.w100,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: const Text(
          "Thank you for applying!\n\nYour job has been saved under 'Applied Jobs'.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "OK",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Apply Form Dialog
  void _showApplyFormDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final linkedinController = TextEditingController();
    final notesController = TextEditingController();

    String selectedLocation = "Bangalore, India";
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => Dialog(
            backgroundColor: Colors.white, //  <-- ADD THIS LINE
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
                    "Apply for this position",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            hintText: "First name",
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            hintText: "Last name",
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

                  // Phone
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: "(+91) 98765 43210",
                      filled: true,
                      fillColor: Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "yourname@example.com",
                      filled: true,
                      fillColor: Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location
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
                        value: "Bangalore, India",
                        child: Text("Bangalore, India"),
                      ),
                      DropdownMenuItem(
                        value: "Chennai, India",
                        child: Text("Chennai, India"),
                      ),
                      DropdownMenuItem(
                        value: "Hyderabad, India",
                        child: Text("Hyderabad, India"),
                      ),
                      DropdownMenuItem(
                        value: "Delhi, India",
                        child: Text("Delhi, India"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) selectedLocation = value;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Resume Upload
                  const Text(
                    "Upload CV/Resume",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'doc', 'docx'],
                          );
                      if (result != null) {
                        setState(() {
                          selectedFileName = result.files.single.name;
                        });
                      }
                    },
                    icon: const Icon(Iconsax.export_3, size: 18),
                    label: Text(selectedFileName ?? "Choose File"),
                  ),
                  if (selectedFileName != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      "📄 $selectedFileName",
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // LinkedIn
                  const Text(
                    "LinkedIn",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: linkedinController,
                    decoration: InputDecoration(
                      prefixIcon: const FaIcon(
                        FontAwesomeIcons.linkedinIn,
                        color: AppColors.primary,
                      ),
                      hintText: "LinkedIn Profile URL",
                      filled: true,
                      fillColor: Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  const Text(
                    "Add Notes:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Type here...",
                      filled: true,
                      fillColor: Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                              await _saveAppliedJob(
                                widget.title,
                                widget.org,
                                widget.location,
                                selectedFileName,
                                selectedLocation,
                                linkedinController.text,
                                notesController.text,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(ctx);
                              _showSuccessDialog(context);
                          },
                          icon: const Icon(
                            Iconsax.send_1,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Submit Application",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appliedDateFormatted = appliedDate != null
        ? DateTime.parse(appliedDate!).toLocal().toString().split(' ').first
        : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Job Details"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset(widget.logo, height: 90),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.org,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    widget.location,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 🏥 Department Info
            const Text(
              "Department:",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              "Orthopedics",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            const Text(
              "Sub-Speciality:",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              "General Orthopedics",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // 💼 Job Type & Salary
            const Text(
              "Job Type: Full Time",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              "Salary: ₹28,00,000 / yr",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // 🧠 About the Role
            const Text(
              "About the Role",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              "We are seeking a skilled healthcare professional to join our team in a fast-paced hospital environment.",
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 20),

            // 📋 Key Responsibilities
            const Text(
              "Key Responsibilities",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              "• Conduct medical examinations\n"
              "• Perform surgeries\n"
              "• Provide follow-up care",
            ),
            const SizedBox(height: 20),
            SizedBox(height: 30),

            Center(
              child: alreadyApplied
                  ? Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "✅ Already Applied",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (appliedDateFormatted != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Applied on: $appliedDateFormatted",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _withdrawApplication,
                          icon: const Icon(Iconsax.trash, color: Colors.red),
                          label: const Text(
                            "Withdraw Application",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () => _showApplyFormDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 80,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Apply Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
