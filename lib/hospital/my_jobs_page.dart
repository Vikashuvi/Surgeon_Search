import 'package:flutter/material.dart';
import 'package:doc/hospital/applicants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:doc/subscription_plan_screen/hospital_after_2_months.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/utils/app_config.dart';


class MyJobsPage extends StatefulWidget {
  final VoidCallback? onHospitalNameTap;
  final String? healthcareId;
  final Map<String, dynamic>? hospitalData;

  const MyJobsPage({super.key, this.onHospitalNameTap, this.healthcareId, this.hospitalData});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  int bottomIndex = 0;
  int tabIndex = 0; // 0 = Active, 1 = Closed
  String _hospitalName = '';
  String? _hospitalLogoUrl;

  @override
  void initState() {
    super.initState();
    // Use passed data immediately if available
    if (widget.hospitalData != null) {
      _hospitalName = widget.hospitalData!['hospitalName']?.toString() ?? '';
      var logo = widget.hospitalData!['hospitalLogo']?.toString() ?? '';
      // Add base URL if logo is a relative path
      if (logo.isNotEmpty && !logo.startsWith('http')) {
        logo = '${AppConfig.serverUrl}/$logo';

      }
      _hospitalLogoUrl = logo.isNotEmpty ? logo : null;
      debugPrint('📋 PostJob: Using passed data - Name: $_hospitalName, Logo: $_hospitalLogoUrl');
    }
    // Then fetch fresh data from API
    _fetchHospitalName();
  }

  Future<void> _fetchHospitalName() async {
    try {
      String healthcareId = widget.healthcareId ?? '';
      if (healthcareId.isEmpty) {
        healthcareId = await SessionManager.getHealthcareId() ?? '';
      }
      if (healthcareId.isEmpty) {
        healthcareId = await SessionManager.getProfileId() ?? '';
      }
      
      if (healthcareId.isNotEmpty) {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$healthcareId');

        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final profile = data is Map && data['data'] != null ? data['data'] : data;
          if (profile is Map) {
             final name = profile['hospitalName'] ?? profile['name'] ?? profile['organizationName'];
             var logo = profile['hospitalLogo']?.toString() ?? '';
             // Add base URL if logo is a relative path
             if (logo.isNotEmpty && !logo.startsWith('http')) {
               logo = '${AppConfig.serverUrl}/$logo';

             }
             if (mounted) {
               setState(() {
                 if (name != null) _hospitalName = name.toString();
                 if (logo.isNotEmpty) _hospitalLogoUrl = logo;
               });
             }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching hospital name: $e');
    }
  }

  Future<void> _handlePostJob() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Try widget ID first
      String healthcareId = widget.healthcareId ?? '';
      
      // 2. If empty, try session
      if (healthcareId.isEmpty) {
        healthcareId = await SessionManager.getHealthcareId() ?? '';
      }
      if (healthcareId.isEmpty) {
        healthcareId = await SessionManager.getProfileId() ?? '';
      }
      if (healthcareId.isEmpty) {
        healthcareId = await SessionManager.getUserId() ?? '';
      }

      if (healthcareId.isEmpty) {
        if (mounted) Navigator.pop(context); // hide loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Healthcare ID is missing')),
          );
        }
        return;
      }

      debugPrint('🩺 Initial ID check: $healthcareId');

      // Helper function to check eligibility
      Future<http.Response> checkEligibility(String id) {
        final uri = Uri.parse(
            '${AppConfig.apiBaseUrl}/healthcare/job-posteligible/$id');

        debugPrint('🩺 Checking eligibility for ID: $id');
        return http.get(uri);
      }

      var resp = await checkEligibility(healthcareId);
      debugPrint('🩺 Response for $healthcareId: ${resp.statusCode}');

      // If 404, it might be the wrong ID type. Try others from session.
      if (resp.statusCode == 404) {
        debugPrint('🩺 404 received. Trying fallback IDs from session...');
        
        final sessionHealthcareId = await SessionManager.getHealthcareId();
        final sessionProfileId = await SessionManager.getProfileId();
        final sessionUserId = await SessionManager.getUserId();

        final List<String> candidates = [
          if (sessionHealthcareId != null) sessionHealthcareId,
          if (sessionProfileId != null) sessionProfileId,
          if (sessionUserId != null) sessionUserId,
        ];

        // Remove duplicates and the one we already tried
        final uniqueCandidates = candidates.toSet().toList();
        uniqueCandidates.remove(healthcareId);

        for (final candidate in uniqueCandidates) {
          if (candidate.isNotEmpty) {
            debugPrint('🩺 Retrying with candidate ID: $candidate');
            final retryResp = await checkEligibility(candidate);
            if (retryResp.statusCode == 200) {
              resp = retryResp;
              healthcareId = candidate; // Update to the working ID
              debugPrint('🩺 Found working ID: $healthcareId');
              break;
            }
          }
        }
      }
      
      if (!mounted) return;
      Navigator.pop(context); // hide loading

      debugPrint('🩺 Final Eligibility response: ${resp.statusCode} ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final bool freeTrial = data['hasAccess'] == true || 
            data['freetrail1month'] == true || 
            data['freetrail2month'] == true ||
            data['isSubscribed'] == true;

        if (freeTrial) {
          // Eligible -> Go to Post Job Form
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Applicants(
                healthcareId: healthcareId,
              ),
            ),
          );
        } else {
          // Not Eligible -> Show Subscription Popup
          final int amount = data['paymentAmount'] is int 
              ? data['paymentAmount'] 
              : int.tryParse(data['paymentAmount']?.toString() ?? '5500') ?? 5500;
          
          final String hospitalType = data['hospitalType']?.toString() ?? 'Hospital Plan';
          
          // Construct price string: ₹5500 for 1 year
          final String priceString = "₹${amount.toString()} for 1 year";

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HospitalFreeTrialEndedPopup(
                planTitle: hospitalType,
                planPrice: priceString,
                amount: amount,
                healthcareId: healthcareId,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check eligibility (${resp.statusCode}): ${resp.body}')),
        );
      }
    } catch (e) {
      debugPrint('🩺 Error checking eligibility: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- HEADER CARD ----------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Hospital Logo
                    ClipOval(
                      child: (_hospitalLogoUrl != null && _hospitalLogoUrl!.isNotEmpty)
                          ? Image.network(
                              _hospitalLogoUrl!,
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "assets/logo2.png",
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              "assets/logo2.png",
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Hospital Name (tappable to go to profile)
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onHospitalNameTap,
                        child: Text(
                          _hospitalName.isNotEmpty ? _hospitalName : "Hospital",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    // Notification Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "0 Results",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // ---------- EMPTY JOBS CARD ----------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                  const Text(
                      "Create a New Job Opening",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _handlePostJob,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Post a Job"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ---------- BOTTOM NAVIGATION ----------
    );
  }
}
  // Custom Bottom Navigation