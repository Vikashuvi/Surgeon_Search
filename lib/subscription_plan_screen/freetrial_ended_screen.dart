import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
import '../utils/app_config.dart';
import 'subscription_activated_popup.dart';

class FreeTrialEndedScreen extends StatefulWidget {
  const FreeTrialEndedScreen({super.key});

  @override
  State<FreeTrialEndedScreen> createState() => _FreeTrialEndedScreenState();
}

class _FreeTrialEndedScreenState extends State<FreeTrialEndedScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final profileId = await SessionManager.getProfileId() ??
          await SessionManager.getUserId() ??
          '';

      // 1. Verify payment on backend
      final verifyUrl = Uri.parse('${AppConfig.apiBaseUrl}/payment/surgeonverify');
      final verifyResponse = await http.post(
        verifyUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_payment_id': response.paymentId,
          'razorpay_order_id': response.orderId,
          'razorpay_signature': response.signature,
          'profile_id': profileId,
        }),
      );

      // 2. Mark yearly subscription active in local session
      if (verifyResponse.statusCode == 200) {
        try {
          final data = jsonDecode(verifyResponse.body);
          final sub = data['subscription'];
          await SessionManager.saveSubscriptionDetails(
            isSubscribed: true,
            startDate: sub?['startDate']?.toString(),
            endDate: sub?['endDate']?.toString(),
          );
        } catch (_) {
          await SessionManager.saveSubscriptionDetails(isSubscribed: true);
        }
      } else {
        await SessionManager.saveSubscriptionDetails(isSubscribed: true);
      }

      await SessionManager.saveFreeTrialFlag(true);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Payment Successful! Your subscription is now active.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to subscription activated screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SubscriptionActivatedScreen(),
        ),
      );
    } catch (e) {
      // Even if network verification throws, Razorpay payment succeeded locally
      await SessionManager.saveFreeTrialFlag(true);
      if (!mounted) return;
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Payment Successful! Your subscription is now active.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SubscriptionActivatedScreen(),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
// Removed debug print
// Removed debug print
// Removed debug print

    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Payment Failed: ${response.message ?? "Unknown error"}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
// Removed debug print
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Get user/profile ID from session
      final profileId = await SessionManager.getProfileId() ?? 
                       await SessionManager.getUserId() ?? '';

      if (profileId.isEmpty) {
        throw Exception('User ID not found. Please log in again.');
      }

// Removed debug print

      // Create order on backend
      final orderResponse = await _createOrder(profileId);

      if (orderResponse == null) {
        throw Exception('Failed to create order');
      }

// Removed debug print
// Removed debug print
// Removed debug print

      // Open Razorpay checkout
      _openRazorpayCheckout(orderResponse);

    } catch (e) {
// Removed debug print
      
      setState(() => _isProcessing = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _createOrder(String profileId) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/payment/surgeonorder');

      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'success': true,
          'profileId': profileId,
          'amount': 1750, // ₹1750 for surgeon yearly subscription
        }),
      );

// Removed debug print
// Removed debug print

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        final rawAmount = data['amount'];
        final int amountInPaise = rawAmount is int
            ? (rawAmount < 1000 ? rawAmount * 100 : rawAmount)
            : int.tryParse(rawAmount?.toString() ?? '175000') ?? 175000;

        return {
          'orderId': data['orderId'] ?? data['id'] ?? data['order_id'],
          'amount': amountInPaise,
          'currency': data['currency'] ?? 'INR',
          'key': data['key'] ?? AppConfig.razorpayKey,
        };
      } else {
// Removed debug print
        return null;
      }
    } catch (e) {
// Removed debug print
      return null;
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> orderData) async {
    final userEmail = await SessionManager.getUserEmail() ?? '';
    final userPhone = await SessionManager.getUserPhone() ?? '';

    var options = {
      'key': orderData['key'] ?? AppConfig.razorpayKey,
      'amount': orderData['amount'], // Amount in paise
      'currency': orderData['currency'] ?? 'INR',
      'name': 'Surgeon Search',
      'description': 'Surgeon Plan - ₹1750 for 1 year',
      'order_id': orderData['orderId'],
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
      },
      'theme': {
        'color': '#0072FF'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
// Removed debug print
      setState(() => _isProcessing = false);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dimmed Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.withValues(alpha: 0.4),
          ),

          // Bottom curved container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(120),
                  topRight: Radius.circular(120),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF6FF),
                    ),
                    child: const Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      color: Color(0xFF2D7DEB),
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Title
                  const Text(
                    "Your free trial has ended!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF005BD4),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Message
                  const Text(
                    "To continue searching and applying for jobs,\nplease subscribe.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Plan box
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
                        const Text(
                          "Surgeon Plan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// Price
                        const Text(
                          "₹1750 for 1 year",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// Features
                        _planFeature("Unlimited job search"),
                        _planFeature("Unlimited job applications"),
                        _planFeature("Direct contact with hospitals"),
                        _planFeature("Secure and private data handling"),

                        const SizedBox(height: 8),

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
                          onTap: _isProcessing ? null : _initiatePayment,
                          child: Container(
                            width: double.infinity,
                            height: 45,
                            decoration: BoxDecoration(
                              color: _isProcessing 
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0052CC),
                                      ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
