import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'subscription_active.dart';
import 'package:doc/utils/app_config.dart';


class HospitalFreeTrialEndedPopup extends StatefulWidget {
  final String planTitle;
  final String planPrice;
  final int amount;
  final String healthcareId;

  const HospitalFreeTrialEndedPopup({
    super.key,
    required this.planTitle,
    required this.planPrice,
    required this.amount,
    required this.healthcareId,
  });

  @override
  State<HospitalFreeTrialEndedPopup> createState() => _HospitalFreeTrialEndedPopupState();
}

class _HospitalFreeTrialEndedPopupState extends State<HospitalFreeTrialEndedPopup> {
  bool _isProcessing = false;

  Future<void> _subscribe() async {
    setState(() => _isProcessing = true);

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/payment/hospitalorder');

// Removed debug print
// Removed debug print

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.amount,
          'healthcare_id': widget.healthcareId,
        }),
      );

// Removed debug print
// Removed debug print

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HospitalSubscriptionActivatedPopup(),
          ),
        );
      } else {
        // Error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate subscription: ${response.body}')),
        );
      }
    } catch (e) {
// Removed debug print
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Dimmed background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.25),
          ),

          /// Curved popup at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(110),
                  topRight: Radius.circular(110),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Sad icon
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE6F0FF),
                    ),
                    child: const Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 45,
                      color: Color(0xFF005BCF),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Title
                  const Text(
                    "Your free trial has ended!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF005BD4),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  /// Subtitle
                  const Text(
                    "Subscribe to continue posting jobs and accessing surgeons.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  /// You have chosen
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "You have chosen,",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Selected Plan Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0072FF), Color(0xFF0053CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Title
                        Text(
                          widget.planTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// Price
                        Text(
                          widget.planPrice,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// Bullet items
                        Text(
                          "•  Auto-renews every year\n•  Cancel anytime",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// Subscribe Button
                        InkWell(
                          onTap: _isProcessing ? null : _subscribe,
                          child: Container(
                            width: double.infinity,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0052CC),
                                    ),
                                  )
                                : const Text(
                                    "Subscribe Now",
                                    style: TextStyle(
                                      color: Color(0xFF0052CC),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Change plan
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: const Text(
                        "Change",
                        style: TextStyle(
                          color: Color(0xFF005BD4),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// Footer note
                  const Text(
                    "Your subscription will be activated only after verification is completed.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
