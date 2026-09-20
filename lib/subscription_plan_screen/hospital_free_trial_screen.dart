import 'package:flutter/material.dart';
import 'package:doc/subscription_plan_screen/hospital_subscription_activated_screen.dart';

class HospitalFreeTrialScreen extends StatelessWidget {
  final int paymentAmount;
  final String facilityCategory;
  final String healthcareId;
  final Map<String, dynamic> hospitalData;

  const HospitalFreeTrialScreen({
    super.key,
    required this.paymentAmount,
    required this.facilityCategory,
    required this.healthcareId,
    required this.hospitalData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "Subscription Plan",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              const Text(
                "Your subscription will start after 1 month. No charge today.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 25),

              // Free Trial Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    Text(
                      "Enjoy 1 month free!",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "You can explore jobs with full access.\n"
                      "You’ll be charged only after 1 month.\n"
                      "Cancel anytime.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // Plan Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0072FF), Color(0xFF0053CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$facilityCategory Plan", // e.g. Corporate Plan
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "₹$paymentAmount for 6 months",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildFeatureRow("Unlimited job post"),
                    const SizedBox(height: 6),
                    _buildFeatureRow("Unlimited job scheduling"),
                    const SizedBox(height: 6),
                    _buildFeatureRow("All Surgeons profiles"),
                    const SizedBox(height: 6),
                    _buildFeatureRow("Secure and privacy data handling"),

                    const SizedBox(height: 20),

                    // Button
                    InkWell(
                      onTap: () {
                        // Show subscription activated popup
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HospitalSubscriptionActivatedPopup(
                              hospitalData: hospitalData,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Activate",
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 10),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
          ),
        ),
      ],
    );
  }
}
