import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:iconsax/iconsax.dart';
import 'package:doc/model/api_service.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:logger/logger.dart';
import 'package:doc/model/indian_states_districts.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:doc/utils/app_config.dart';
import 'package:doc/screens/signin_screen.dart';

 
const Map<String, List<String>> surgicalSpecialities = {
  'General Surgery': [
    'Lower GI Surgery',
    'Laparoscopic Surgery',
    'Trauma Surgery',
    'Breast / Endocrine Surgery',
    'Endocrine Surgery',
    'Head and Neck Surgery',
    'Musculoskeletal Surgery',
  ],
  'Cardiothoracic & Vascular Surgery': [
    'Paediatric Cardiothoracic & Vascular Surgery',
    'Thoracic Surgery',
    'Vascular Surgery',
    'Cardiac and Lung transplant',
  ],
  'Neurosurgery': [
    'Spine Surgery',
    'Cerebrovascular Surgery',
    'Skull base surgery',
    'Stereotactic radiosurgery',
    'Pediatric Neurosurgery',
    'Neuro-oncology',
    'Functional and epilepsy Neurosurgery',
    'Peripheral nerve surgery',
  ],
  'Orthopedic Surgery': [
    'Hand Surgery',
    'Sports Medicine',
    'Arthroplasty (Joint Replacement)',
    'Pediatric Orthopedics',
    'Orthopaedic Oncology',
    'Spine Surgery',
    'Trauma Surgery',
    'Arthroscopy',
  ],
  'ENT (Otorhinolaryngology) Surgery': [
    'Otology and Neurotology',
    'Rhinology',
    'Laryngology',
    'Head & Neck Surgery',
    'Skull Base Surgery',
  ],
  'Ophthalmic Surgery': [
    'Glaucoma',
    'Corneal Surgery',
    'Vitreo-retinal Surgery',
    'Pediatric Ophthalmology',
    'Refractive Surgery',
  ],
  'Urology': [
    'Pediatric Urology',
    'Uro-oncology',
    'Reconstructive Urology',
    'Laparoscopic/Robotic Urology',
  ],
  'Pediatric Surgery': [
    'Neonatal Surgery',
    'Thoracic Surgery',
    'Pediatric Urology',
    'Pediatric Gastrointestinal Surgery',
  ],
  'Plastic and Reconstructive Surgery': [
    'Hand Surgery',
    'Microsurgery',
    'Craniofacial Surgery',
    'Aesthetic Surgery',
    'Oncoplasty',
  ],
  'Surgical Oncology': [
    'Breast Oncology',
    'Gynecological Oncology',
    'Gastrointestinal Oncology',
    'Head & Neck Oncology',
    'Thoracic oncology',
    'Robotic onco-surgery',
  ],
  'Gastrointestinal Surgery': [
    'Bariatric Surgery',
    'Upper GI',
    'Lower GI',
    'Transplant Surgery',
    'Hepatobiliary Surgery',
    'Minimally Invasive Surgery/Robotic GI surgery',
  ],
  'Trauma and Critical Care Surgery': [],
  'Vascular Surgery': [],
  'Obstetrics and Gynaecology': [],
  'Interventional Radiology': [
    'Vascular Interventions including trauma',
    'Oncology Interventions',
    'Neurointervention',
    'Musculoskeletal Interventions',
    'Thyroid/Uterine artery embolisation',
  ],
  'Interventionists': [],
};

class SurgeonForm extends StatefulWidget {
  final String profileId;
  final Map<String, dynamic>? existingData;

  const SurgeonForm({
    super.key,
    required this.profileId,
    required this.existingData,
  });

  @override
  State<SurgeonForm> createState() => _SurgeonFormState();
}

final _logger = Logger();

class SurgeonProfileView extends StatelessWidget {
  final Map<String, dynamic> data;
  const SurgeonProfileView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    final profile = d['data'] ?? d;
    final p = profile is Map && profile['profile'] != null ? profile['profile'] : profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Surgeon Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Full Name: ${p['fullName'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Speciality: ${p['speciality'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Degree: ${p['degree'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Experience: ${p['yearsOfExperience'] ?? ''}'),
          ],
        ),
      ),
    );
  }
}

class _SurgeonFormState extends State<SurgeonForm> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController fullName;
  late TextEditingController speciality;
  late TextEditingController subSpeciality;
  late TextEditingController degree;
  late TextEditingController experience;
  late TextEditingController surgicalExp;
  late TextEditingController portfolio;
  late TextEditingController summary;
  late TextEditingController phoneNumber;
  late TextEditingController email;
  late TextEditingController location;
  late TextEditingController stateCtrl;
  late TextEditingController districtCtrl;
 
  File? profilePic;
  File? cv;
  File? highestDegree;
  File? logBook;
  String? profilePicUrl;
  String? cvUrl;
  String? highestDegreeUrl;
  String? logBookUrl;

  String? selectedSurgicalExperience;
  String? selectedState;
  String? selectedDistrict;
  List<String> districts = [];

  final List<String> expOptions = const [
    "0-10",
    "10-50",
    "50-100",
    "100-500",
    "1000-5000",
    "5000-10000",
    "More than 10000",
  ];

  final List<String> yearsOptions = List.generate(40, (index) => '${index + 1}');

  bool isLoading = false;
  bool hasProfile = false;
  bool termsAccepted = false;
  List<Map<String, dynamic>> workExperiences = [
    {"designation": "", "organization": "", "from": "", "to": "", "location": "", "tillDate": false}
  ];
  List<List<TextEditingController>> workExpControllers = [];

  @override
  void initState() {
    super.initState();

    final d = widget.existingData ?? {};
    profilePicUrl = d['profilePicture'];
    cvUrl = d['cv'];
    highestDegreeUrl = d['highestDegree'];
    logBookUrl = d['uploadLogBook'];

    fullName = TextEditingController(text: d['fullName'] ?? '');
    speciality = TextEditingController(text: d['speciality'] ?? '');
    subSpeciality = TextEditingController(text: d['subSpeciality'] ?? '');
    degree = TextEditingController(text: d['degree'] ?? '');
    experience = TextEditingController(
      text: d['yearsOfExperience']?.toString() ?? '',
    );
    surgicalExp = TextEditingController(text: d['surgicalExperience'] ?? '');
    portfolio = TextEditingController(text: d['portfolioLinks'] ?? '');
    summary = TextEditingController(text: d['summaryProfile'] ?? '');
    phoneNumber = TextEditingController(text: d['phoneNumber'] ?? '');
    email = TextEditingController(text: d['email'] ?? '');
    location = TextEditingController(text: d['location'] ?? '');
    stateCtrl = TextEditingController(text: d['state'] ?? '');
    districtCtrl = TextEditingController(text: d['district'] ?? '');
    selectedState = d['state'];
    selectedDistrict = d['district'];
    if (selectedState != null && IndianStatesAndDistricts.data.containsKey(selectedState)) {
      districts = IndianStatesAndDistricts.data[selectedState]!;
    }

    selectedSurgicalExperience = d['surgicalExperience']?.toString().isNotEmpty == true
        ? d['surgicalExperience'].toString()
        : null;

    // If existingData is provided, we already have a profile
    if (widget.existingData != null && widget.existingData!.isNotEmpty) {
      hasProfile = true;
    }

    // Initialize work experience controllers
    _initializeWorkExpControllers();
    
    // Prefill from session immediately
    _prefillFromSession();

    // Fetch and prefill if profile exists for given profileId
    _loadProfileIfAny();
  }

  Future<void> _prefillFromSession() async {
    final sessionName = await SessionManager.getUserName();
    if (sessionName != null && sessionName.isNotEmpty && fullName.text.isEmpty) {
      setState(() => fullName.text = sessionName);
    }
    final sessionPhone = await SessionManager.getUserPhone();
    if (sessionPhone != null && sessionPhone.isNotEmpty && phoneNumber.text.isEmpty) {
      setState(() => phoneNumber.text = sessionPhone);
    }
    final sessionEmail = await SessionManager.getUserEmail();
    if (sessionEmail != null && sessionEmail.isNotEmpty && email.text.isEmpty) {
      setState(() => email.text = sessionEmail);
    }
  }

  Future<void> _loadProfileIfAny() async {
    _logger.i("🔍 SurgeonForm: Loading profile for ID: ${widget.profileId}");
    _logger.i("🔍 SurgeonForm: Existing data provided: ${widget.existingData != null}");
    
    setState(() => isLoading = true);
    
    // Always fetch from API to get the latest data (especially file URLs)
    final res = await ApiService.fetchProfileInfo(widget.profileId);
    if (res['success'] == true) {
      final body = res['data'];
      // Some APIs wrap data again; try common shapes
      final data = body is Map && body['data'] != null ? body['data'] : body;
      final p = data is Map && data['profile'] != null ? data['profile'] : data;
      if (p is Map) {
        hasProfile = true;
        profilePicUrl = p['profilePicture'];
        cvUrl = p['cv'];
        highestDegreeUrl = p['highestDegree'];
        logBookUrl = p['uploadLogBook'];
        _logger.d("🔍 SurgeonForm: Profile Data: $p");
        fullName.text = (p['fullName'] ?? 
                         p['fullname'] ?? 
                         p['name'] ?? 
                         p['username'] ?? 
                         p['full_name'] ??
                         fullName.text).toString();
        speciality.text = (p['speciality'] ?? speciality.text) as String;
        subSpeciality.text = (p['subSpeciality'] ?? subSpeciality.text) as String;
        degree.text = (p['degree'] ?? degree.text) as String;
        experience.text = p['yearsOfExperience']?.toString() ?? experience.text;
        selectedSurgicalExperience = (p['surgicalExperience'] ?? selectedSurgicalExperience)?.toString();
        portfolio.text = (p['portfolioLinks'] ?? portfolio.text) as String;
        summary.text = (p['summaryProfile'] ?? summary.text) as String;
        phoneNumber.text = (p['phoneNumber'] ?? phoneNumber.text) as String;
        email.text = (p['email'] ?? email.text) as String;
        location.text = (p['location'] ?? location.text) as String;
        stateCtrl.text = (p['state'] ?? stateCtrl.text) as String;
        districtCtrl.text = (p['district'] ?? districtCtrl.text) as String;
        
        if (p['state'] != null) {
          selectedState = p['state'];
          if (IndianStatesAndDistricts.data.containsKey(selectedState)) {
            districts = IndianStatesAndDistricts.data[selectedState]!;
          }
        }
        if (p['district'] != null) {
          selectedDistrict = p['district'];
        }
        final wx = p['workExperience'];
        if (wx is List) {
          workExperiences = wx.map<Map<String, dynamic>>((e) {
            final m = (e is Map) ? e : {};
            return {
              'designation': m['designation'] ?? '',
              'organization': m['healthcareOrganization'] ?? m['organization'] ?? '',
              'from': m['from']?.toString() ?? '',
              'to': m['to']?.toString() ?? '',
              'location': m['location'] ?? '',
              'tillDate': m['tillDate'] == true,
            };
          }).toList();
          if (workExperiences.isEmpty) {
            workExperiences = [{"designation": "", "organization": "", "from": "", "to": "", "location": "", "tillDate": false}];
          }
        }
      }
    }

    
    // Auto-populate from session if still empty
    if (email.text.isEmpty) {
      final sessionEmail = await SessionManager.getUserEmail();
      if (sessionEmail != null) email.text = sessionEmail;
    }
    if (phoneNumber.text.isEmpty) {
      final sessionPhone = await SessionManager.getUserPhone();
      if (sessionPhone != null) phoneNumber.text = sessionPhone;
    }
    if (fullName.text.isEmpty) {
      final sessionName = await SessionManager.getUserName();
      if (sessionName != null) fullName.text = sessionName;
    }

    // Reinitialize work experience controllers with new data
    _initializeWorkExpControllers();

    setState(() => isLoading = false);
  }

  Future<File?> pickFile(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (result != null) return File(result.files.single.path!);
    return null;
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final uri = Uri.parse(
      "${AppConfig.apiBaseUrl}/sugeon/edit-profile/${widget.profileId}",
    );


    var req = http.MultipartRequest("PUT", uri);

    req.fields.addAll({
      "fullName": fullName.text,
      "speciality": speciality.text,
      "subSpeciality": subSpeciality.text,
      "degree": degree.text,
      "yearsOfExperience": experience.text,
      "surgicalExperience": selectedSurgicalExperience ?? '',
      "portfolioLinks": portfolio.text,
      "summaryProfile": summary.text,
      "state": selectedState ?? stateCtrl.text,
      "district": selectedDistrict ?? districtCtrl.text,
    });

    if (profilePic != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "profilePicture",
          profilePic!.path,
          filename: p.basename(profilePic!.path),
        ),
      );
    }
    if (cv != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "cv",
          cv!.path,
          filename: p.basename(cv!.path),
        ),
      );
    }
    if (highestDegree != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "highestDegree",
          highestDegree!.path,
          filename: p.basename(highestDegree!.path),
        ),
      );
    }
    if (logBook != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "uploadLogBook",
          logBook!.path,
          filename: p.basename(logBook!.path),
        ),
      );
    }

    var res = await req.send();
    var msg = await res.stream.bytesToString();
 
    if (res.statusCode == 200) {
      Get.snackbar("✅ Success", "Profile Updated Successfully");
      final prof = await ApiService.fetchProfileInfo(widget.profileId);
      if (prof['success'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfessionalProfileViewPage(profileId: widget.profileId),
          ),
        );
      } else {
        Get.snackbar("Profile", "Updated, but failed to fetch profile");
      }
    } else {
      Get.snackbar("❌ Update Failed", msg);
    }

    setState(() => isLoading = false);
  }

  Future<void> createProfile() async {
    if (!formKey.currentState!.validate()) {
      _logger.w('🔴 VALIDATION FAILED - Form not valid');
      return;
    }

    _logger.i('🟢 VALIDATION PASSED - Starting profile creation');
    setState(() => isLoading = true);
    
    // Update work experience data from controllers
    _updateWorkExperienceData();

    _logger.i('🔵 Calling ApiService.createProfile...');
    final result = await ApiService.createProfile(
      fullName: fullName.text,
      phoneNumber: phoneNumber.text,
      email: email.text,
      location: '',
      degree: degree.text,
      speciality: speciality.text,
      subSpeciality: subSpeciality.text,
      summaryProfile: summary.text,
      termsAccepted: termsAccepted,
      profileId: widget.profileId,
      portfolioLinks: portfolio.text,
      workExperience: workExperiences,
      departmentsAvailable: const [],
      imageFile: profilePic,
      cvFile: cv,
      highestDegreeFile: highestDegree,
      logBookFile: logBook,
      yearsOfExperience: experience.text,
      surgicalExperience: selectedSurgicalExperience ?? '',
      state: selectedState ?? stateCtrl.text,
      district: selectedDistrict ?? districtCtrl.text,
    );

    _logger.d('🔵 API Response received: $result');
    _logger.d('🔵 Success value: ${result['success']}');
    _logger.d('🔵 Success type: ${result['success'].runtimeType}');

    if (result['success'] == true) {
      _logger.i('✅ SUCCESS - Profile created successfully!');
      hasProfile = true;
      Get.snackbar("✅ Success", "Profile Created Successfully");
      
      // ✅ Save Free Trial Flag
      _logger.i('💾 Saving free trial flag...');
      await SessionManager.saveFreeTrialFlag(true);
      _logger.i('💾 Free trial flag saved!');

      if (!mounted) {
        _logger.w('⚠️ Widget not mounted, cannot navigate');
        return;
      }
      
      _logger.i('🚀 Navigating to ProfessionalProfileViewPage (Bypassing Subscription)...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfessionalProfileViewPage(profileId: widget.profileId),
        ),
      );
      _logger.i('✅ Navigation completed!');
    } else {
      _logger.e('❌ FAILED - Profile creation failed');
      _logger.e('❌ Error message: ${result['message']}');
      Get.snackbar("❌ Create Failed", result['message']?.toString() ?? 'Error');
    }

    setState(() => isLoading = false);
  }

// Helpers to match provided UI
InputDecoration inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      filled: true,
      fillColor: Colors.white,
    );

Widget titleText(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
    );

  Future<void> pickProfileImage() async {
    try {
      // Use ImagePicker which leverages Android's Photo Picker API (Android 13+)
      // This is fully compliant with Google Play policies and doesn't require
      // READ_EXTERNAL_STORAGE or READ_MEDIA_IMAGES permissions.
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80, // Compress to 80% quality
      );
      
      if (pickedFile != null) {
        final originalFile = File(pickedFile.path);
        final fileSize = await originalFile.length();
        
        // If file > 1MB, compress it further
        if (fileSize > 1024 * 1024) {
          try {
            final dir = await Directory.systemTemp.createTemp();
            final targetPath = "${dir.path}/${p.basename(originalFile.path)}";
            
            final compressedFile = await FlutterImageCompress.compressAndGetFile(
              originalFile.path,
              targetPath,
              quality: 70,
              minWidth: 800,
              minHeight: 800,
            );
            
            if (compressedFile != null) {
              setState(() => profilePic = File(compressedFile.path));
            } else {
              setState(() => profilePic = originalFile);
            }
          } catch (e) {
            _logger.e("Error compressing image: $e");
            setState(() => profilePic = originalFile);
          }
        } else {
          setState(() => profilePic = originalFile);
        }
      }
    } catch (e) {
      _logger.e("Error picking image: $e");
      Get.snackbar(
        "Error",
        "Failed to pick image. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

Future<void> pickCVFile() async {
  final result = await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
  if (result != null) {
    setState(() => cv = File(result.files.single.path!));
  }
}

void _initializeWorkExpControllers() {
  workExpControllers.clear();
  for (int i = 0; i < workExperiences.length; i++) {
    workExpControllers.add([
      TextEditingController(text: workExperiences[i]['designation'] ?? ''),
      TextEditingController(text: workExperiences[i]['organization'] ?? ''),
      TextEditingController(text: workExperiences[i]['from'] ?? ''),
      TextEditingController(text: workExperiences[i]['to'] ?? ''),
      TextEditingController(text: workExperiences[i]['location'] ?? ''),
    ]);
  }
}

void addWorkExperience() {
  // Check if any existing work experience has tillDate enabled
  final hasTillDate = workExperiences.any((w) => w['tillDate'] == true);
  if (hasTillDate) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot add new work experience while "Till Date" is enabled for current job'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  setState(() {
    workExperiences.add(
        {"designation": "", "organization": "", "from": "", "to": "", "location": "", "tillDate": false});
    workExpControllers.add([
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ]);
  });
}

void removeWorkExperience(int index) {
  setState(() {
    workExperiences.removeAt(index);
    // Dispose controllers before removing
    for (var controller in workExpControllers[index]) {
      controller.dispose();
    }
    workExpControllers.removeAt(index);
  });
}

void _updateWorkExperienceData() {
  for (int i = 0; i < workExpControllers.length; i++) {
    workExperiences[i] = {
      'designation': workExpControllers[i][0].text,
      'healthcareOrganization': workExpControllers[i][1].text,
      'from': workExpControllers[i][2].text,
      'to': workExperiences[i]['tillDate'] == true ? '' : workExpControllers[i][3].text,
      'location': workExpControllers[i][4].text,
      'tillDate': workExperiences[i]['tillDate'] ?? false,
    };
  }
}

  Future<void> _handleSkip() async {
    // Ensure work exp data is up to date
    _updateWorkExperienceData();

    // 1. Validate 'Required for Skip' fields
    final bool hasName = fullName.text.trim().isNotEmpty;
    final bool hasEmail = email.text.trim().isNotEmpty;
    final bool hasPic = profilePic != null || (profilePicUrl != null && profilePicUrl!.isNotEmpty);
    // For CV, we check if file is selected OR url exists
    final bool hasCv = cv != null || (cvUrl != null && cvUrl!.isNotEmpty);
    
    // Check work experience (at least one valid entry)
    // We consider it valid if at least desig & org are not empty
    final bool hasWorkExp = workExperiences.any((w) => 
      (w['designation']?.toString().trim().isNotEmpty == true) && 
      (w['healthcareOrganization']?.toString().trim().isNotEmpty == true)
    );

    if (!hasName || !hasEmail || !hasPic || !hasCv || !hasWorkExp) {
      Get.snackbar(
        "Required Fields Missing", 
        "To skip, you must provide: Name, Email, Profile Picture, Work Experience, and CV.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // 2. Perform 'Partial Submit' / Claim Trial
    setState(() => isLoading = true);

    try {
      final result = await ApiService.createProfile(
        fullName: fullName.text,
        phoneNumber: phoneNumber.text,
        email: email.text,
        location: location.text,
        degree: degree.text,
        speciality: speciality.text,
        subSpeciality: subSpeciality.text,
        summaryProfile: summary.text,
        termsAccepted: true, // Assuming skip implies partial acceptance
        profileId: widget.profileId,
        portfolioLinks: portfolio.text,
        workExperience: workExperiences,
        departmentsAvailable: const [],
        imageFile: profilePic,
        cvFile: cv,
        highestDegreeFile: highestDegree,
        logBookFile: logBook,
        yearsOfExperience: experience.text,
        surgicalExperience: selectedSurgicalExperience ?? '',
        state: selectedState ?? stateCtrl.text,
        district: selectedDistrict ?? districtCtrl.text,
      );

      if (result['success'] == true) {
        hasProfile = true;
        // Save Free Trial Flag
        await SessionManager.saveFreeTrialFlag(true);
        
        if (mounted) {
          // Bypassing SubscriptionPlanScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfessionalProfileViewPage(profileId: widget.profileId),
            ),
          );
        }
      } else {
        Get.snackbar("Error", result['message']?.toString() ?? 'Failed to save profile');
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

@override
void dispose() {
  // Dispose all text controllers
  fullName.dispose();
  speciality.dispose();
  subSpeciality.dispose();
  degree.dispose();
  experience.dispose();
  surgicalExp.dispose();
  portfolio.dispose();
  summary.dispose();
  phoneNumber.dispose();
  email.dispose();
  location.dispose();
  stateCtrl.dispose();
  districtCtrl.dispose();
  
  // Dispose work experience controllers
  for (var controllerList in workExpControllers) {
    for (var controller in controllerList) {
      controller.dispose();
    }
  }
  
  super.dispose();
}

  Future<void> _selectYear(BuildContext context, TextEditingController controller, {int? minYear}) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Year"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: minYear != null ? DateTime(minYear) : DateTime(1950),
              lastDate: DateTime.now(),
              selectedDate: minYear != null ? DateTime(minYear) : DateTime.now(),
              onChanged: (DateTime dateTime) {
                controller.text = dateTime.year.toString();
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    bottomNavigationBar: SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: hasProfile ? updateProfile : createProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              hasProfile ? "Update" : "Submit",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    ),
    backgroundColor: Colors.white,
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          }
        },
      ),
      title: const Text("Professional profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
      centerTitle: false,
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        TextButton(
          onPressed: _handleSkip,
          child: const Text(
            "Skip",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  "Connect with the best hospitals and build your career.",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),

                  titleText("Full Name as per the records"),
                  TextFormField(controller: fullName, decoration: inputDecoration("Full name as per the records"), validator: (v)=> (v==null||v.isEmpty)?'Required':null),

                  titleText("Phone number"),
                  TextFormField(controller: phoneNumber, decoration: inputDecoration("Your number"), keyboardType: TextInputType.phone),

                  titleText("Email"),
                  TextFormField(controller: email, decoration: inputDecoration("Your email"), keyboardType: TextInputType.emailAddress),

                  titleText("State"),
                  DropdownSearch<String>(
                    popupProps: const PopupProps.menu(
                      menuProps: MenuProps(backgroundColor: Colors.white),
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
                      dropdownSearchDecoration: inputDecoration("Select State"),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedState = value;
                        districts = IndianStatesAndDistricts.data[value] ?? [];
                        selectedDistrict = null; // Reset district when state changes
                      });
                    },
                    selectedItem: selectedState,
                    validator: (v) => v == null ? "Required" : null,
                  ),

                  titleText("District"),
                  DropdownSearch<String>(
                    popupProps: const PopupProps.menu(
                      menuProps: MenuProps(backgroundColor: Colors.white),
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
                      dropdownSearchDecoration: inputDecoration("Select District"),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedDistrict = value;
                      });
                    },
                    selectedItem: selectedDistrict,
                    enabled: selectedState != null, // Disable if no state selected
                    validator: (v) => v == null ? "Required" : null,
                  ),

                  titleText("Your Profile Picture"),
                  GestureDetector(
                    onTap: pickProfileImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          if (profilePic != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(profilePic!, width: 50, height: 50, fit: BoxFit.cover),
                            )
                          else if (profilePicUrl != null && profilePicUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                profilePicUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Iconsax.image, color: Colors.black54, size: 20),
                              ),
                            )
                          else
                            const Icon(Iconsax.image, color: Colors.black54, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              profilePic != null
                                  ? "Image selected ✅"
                                  : (profilePicUrl != null && profilePicUrl!.isNotEmpty
                                      ? "Profile picture available (Tap to change)"
                                      : "Upload your image"),
                              style: TextStyle(
                                color: (profilePic != null || (profilePicUrl != null && profilePicUrl!.isNotEmpty))
                                    ? Colors.green
                                    : Colors.black54,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  titleText("Qualification(s)"),
                  TextFormField(controller: degree, decoration: inputDecoration("Your Qualification")),

                  titleText("Highest Degree (file)"),
                  GestureDetector(
                    onTap: () async {
                      final picked = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf','jpg','jpeg','png'],
                      );
                      if (picked != null) {
                        setState(() => highestDegree = File(picked.files.single.path!));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Iconsax.document_upload, color: Colors.black54, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              highestDegree != null
                                  ? "Highest degree uploaded ✅"
                                  : (highestDegreeUrl != null && highestDegreeUrl!.isNotEmpty
                                      ? "Current Degree: ${highestDegreeUrl!.split('/').last} (Tap to change)"
                                      : "Upload highest degree (PDF/Image)"),
                              style: TextStyle(
                                color: (highestDegree != null || (highestDegreeUrl != null && highestDegreeUrl!.isNotEmpty))
                                    ? Colors.green
                                    : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  titleText("Upload Log Book"),
                  GestureDetector(
                    onTap: () async {
                      final picked = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf','xlsx','xls'],
                      );
                      if (picked != null) {
                        setState(() => logBook = File(picked.files.single.path!));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Iconsax.document_upload, color: Colors.black54, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              logBook != null
                                  ? "Log Book uploaded ✅"
                                  : (logBookUrl != null && logBookUrl!.isNotEmpty
                                      ? "Current LogBook: ${logBookUrl!.split('/').last} (Tap to change)"
                                      : "Upload Log Book (PDF/Excel)"),
                              style: TextStyle(
                                color: (logBook != null || (logBookUrl != null && logBookUrl!.isNotEmpty))
                                    ? Colors.green
                                    : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  titleText("Speciality"),
                  DropdownSearch<String>(
                    popupProps: const PopupProps.menu(
                      menuProps: MenuProps(backgroundColor: Colors.white),
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
                      dropdownSearchDecoration: inputDecoration("Select Speciality"),
                    ),
                    selectedItem: speciality.text.isEmpty ? null : speciality.text,
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    onChanged: (value) {
                      setState(() {
                        speciality.text = value ?? '';
                        subSpeciality.text = '';
                      });
                    },
                  ),

                  if ((surgicalSpecialities[speciality.text] ?? const <String>[]).isNotEmpty) ...[
                    titleText("Sub-speciality"),
                    DropdownSearch<String>(
                      popupProps: const PopupProps.menu(
                        menuProps: MenuProps(backgroundColor: Colors.white),
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Search Sub-speciality",
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      items: speciality.text.isEmpty
                          ? const <String>[]
                          : (surgicalSpecialities[speciality.text] ?? const <String>[]),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: inputDecoration("Select Sub-speciality"),
                      ),
                      selectedItem: subSpeciality.text.isEmpty ? null : subSpeciality.text,
                      enabled: speciality.text.isNotEmpty,
                      validator: (v) {
                        final subs = surgicalSpecialities[speciality.text] ?? const <String>[];
                        if (subs.isEmpty) return null; // No subspecialities required
                        return v == null || v.isEmpty ? "Required" : null;
                      },
                      onChanged: (value) {
                        setState(() {
                          subSpeciality.text = value ?? '';
                        });
                      },
                    ),
                  ],

                  titleText("Years of experience"),
                  DropdownButtonFormField<String>(
                    value: yearsOptions.contains(experience.text) ? experience.text : null,
                    items: yearsOptions
                        .map((e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        experience.text = value ?? '';
                      });
                    },
                    decoration: inputDecoration("Select years of experience"),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),

                  titleText("Surgical experience (No. of cases performed/assisted)"),
                  DropdownButtonFormField<String>(
                    value: selectedSurgicalExperience,
                    items: expOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => selectedSurgicalExperience = v),
                    decoration: inputDecoration("Select surgical experience"),
                  ),

                  titleText("Summary profile"),
                  TextFormField(controller: summary, maxLines: 4, decoration: inputDecoration("Tell about yourself")),

                  titleText("Work experience"),
                  ...workExpControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    List<TextEditingController> controllers = entry.value;
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black12)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: controllers[0],
                              decoration: inputDecoration("Designation"),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: controllers[1],
                              decoration: inputDecoration("Healthcare Organization"),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: TextFormField(
                                  controller: controllers[2],
                                  readOnly: true,
                                  onTap: () async {
                                    await _selectYear(context, controllers[2]);
                                    // Clear 'To' year if 'From' changes to ensure validity
                                    setState(() {
                                      controllers[3].clear();
                                    });
                                  },
                                  decoration: inputDecoration("From (Year)"),
                                )),
                                const SizedBox(width: 10),
                                Expanded(child: TextFormField(
                                  controller: controllers[3],
                                  readOnly: true,
                                  onTap: () {
                                    int? startYear = int.tryParse(controllers[2].text);
                                    if (startYear == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please select Start Year first")),
                                      );
                                      return;
                                    }
                                    _selectYear(context, controllers[3], minYear: startYear);
                                  },
                                  decoration: inputDecoration("To (Year)"),
                                )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Till Date Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: workExperiences[index]['tillDate'] == true,
                                  onChanged: (value) {
                                    setState(() {
                                      workExperiences[index]['tillDate'] = value ?? false;
                                      if (value == true) {
                                        // Clear the 'To' year when Till Date is checked
                                        controllers[3].clear();
                                      }
                                    });
                                  },
                                ),
                                const Text(
                                  "Till Date (Current Job)",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: controllers[4],
                              decoration: inputDecoration("Location"),
                            ),
                            if (workExpControllers.length > 1)
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Iconsax.trash, color: Colors.red),
                                  onPressed: () => removeWorkExperience(index),
                                ),
                              ),

                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: addWorkExperience,
                    icon: const Icon(Iconsax.add_square, color: Colors.blueAccent),
                    label: const Text("Add more work experience", style: TextStyle(color: Colors.blueAccent)),
                  ),

                  titleText("CV"),
                  GestureDetector(
                    onTap: pickCVFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Iconsax.document_upload, color: Colors.black54, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cv != null
                                  ? "CV uploaded ✅"
                                  : (cvUrl != null && cvUrl!.isNotEmpty
                                      ? "Current CV: ${cvUrl!.split('/').last} (Tap to change)"
                                      : "Upload your CV in PDF"),
                              style: TextStyle(
                                color: (cv != null || (cvUrl != null && cvUrl!.isNotEmpty))
                                    ? Colors.green
                                    : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  titleText("Portfolio"),
                  TextFormField(controller: portfolio, decoration: inputDecoration("URL links")),

                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: termsAccepted,
                          onChanged: (v) => setState(() => termsAccepted = v!),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 12, color: Colors.black),
                            children: [
                              const TextSpan(text: "I agree to the "),
                              TextSpan(
                                text: "terms & conditions",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    final Uri url = Uri.parse('https://surgeonsearch.in/terms-conditions/');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    }
                                  },
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 12),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
    );
  }
}
