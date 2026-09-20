import 'package:flutter/material.dart';

import 'hospital_subscription_screen.dart';

class HospitalSubscriptionPlanScreen extends StatelessWidget {
  const HospitalSubscriptionPlanScreen({super.key});

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
              Text(
                "Choose your Subscription Plan",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Post job openings and search for surgeons without limits.\nNo payment required today.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 25),

              Text(
                "Choose your plan based on your hospital category.",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0053CC),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                "Our representative will verify your hospital details.\nOnboarding is completed only after verification.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 22),

              /// PLAN CARDS
              buildPlanCard(
                context: context,
                title: "Small Hospital (<50 beds)",
                price: "₹5,500 for 1 year",
              ),

              const SizedBox(height: 18),

              buildPlanCard(
                context: context,
                title: "Medium Hospital (50–100 beds)",
                price: "₹5,500 for 1 year",
              ),

              const SizedBox(height: 18),

              buildPlanCard(
                context: context,
                title: "Large Hospital (>100 beds)",
                price: "₹5,500 for 1 year",
              ),

              const SizedBox(height: 25),

              Text(
                "Your bed count will be validated by our representative before activating the plan.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// UPDATED Plan Card Widget (with context)
  Widget buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            price,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "No charge today",
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),

          const SizedBox(height: 18),

          /// 🔥 ADDED NAVIGATION HERE
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectedHospitalPlanScreen(
                    planTitle: title,
                    planPrice: price,
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
                "Get Started",
                style: TextStyle(
                  color: Color(0xFF0053CC),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// SECOND SCREEN — RECEIVES DATA
/// ===============================
class SecondScreen extends StatelessWidget {
  final String planTitle;
  final String planPrice;

  const SecondScreen({
    super.key,
    required this.planTitle,
    required this.planPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Selected Plan")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planTitle,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(planPrice, style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
