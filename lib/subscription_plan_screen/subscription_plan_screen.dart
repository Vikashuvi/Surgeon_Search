import 'package:doc/utils/session_manager.dart';
import 'package:flutter/material.dart';

import 'freetrial_ended_screen.dart';
import 'subscription_activated_popup.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  bool? isFreeTrial;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final flag = await SessionManager.getFreeTrialFlag();
    if (mounted) {
      setState(() {
        isFreeTrial = flag; // null means not set (assume false or handle gracefully)
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If free trial is explicitly FALSE, show the ended screen
    if (isFreeTrial == false) {
      return const FreeTrialEndedScreen();
    }

    // Otherwise (true or null/default), show the "Enjoy 2 months free" screen
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Subscription Plan",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              Text(
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Enjoy 1 month free!",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
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

              // Surgeon Plan Card
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
                      "Surgeon Plan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "₹1750 for 1 year",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [bullet(), textWhite("Unlimited job search")],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        bullet(),
                        textWhite("Unlimited job applications"),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        bullet(),
                        textWhite("Profile visibility to hospitals"),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        bullet(),
                        textWhite("Secure and private data handling"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Button
                    InkWell(
                      onTap: () {
                        // Show subscription activated popup
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => const SubscriptionActivatedScreen(),
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
                        child: Text(
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

  Widget bullet() {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    );
  }

  Widget textWhite(String text) {
    return Expanded(
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
      ),
    );
  }
}
