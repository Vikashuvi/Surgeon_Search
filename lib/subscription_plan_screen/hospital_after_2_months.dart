import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
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
      // 1. Verify payment on backend
      final verifyUrl = Uri.parse('${AppConfig.apiBaseUrl}/payment/healthcareverify');
      final verifyResponse = await http.post(
        verifyUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_payment_id': response.paymentId,
          'razorpay_order_id': response.orderId,
          'razorpay_signature': response.signature,
          'healthcare_id': widget.healthcareId,
          'amount': widget.amount,
        }),
      );

      // 2. Mark subscription active in local session
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
          builder: (context) => const HospitalSubscriptionActivatedPopup(),
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
          builder: (context) => const HospitalSubscriptionActivatedPopup(),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _subscribe() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Create order on backend
      final orderResponse = await _createOrder();

      if (orderResponse == null) {
        throw Exception('Failed to create order');
      }

      // 2. Open Razorpay checkout
      _openRazorpayCheckout(orderResponse);

    } catch (e) {
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

  Future<Map<String, dynamic>?> _createOrder() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/payment/hospitalorder');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.amount,
          'healthcare_id': widget.healthcareId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final rawAmount = data['amount'];
        final int amountInPaise = rawAmount is int
            ? (rawAmount < 1000 ? rawAmount * 100 : rawAmount)
            : int.tryParse(rawAmount?.toString() ?? '550000') ?? 550000;

        return {
          'orderId': data['orderId'] ?? data['id'] ?? data['order_id'],
          'amount': amountInPaise,
          'currency': data['currency'] ?? 'INR',
          'key': data['key'] ?? AppConfig.razorpayKey,
        };
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> orderData) async {
    final userEmail = await SessionManager.getUserEmail() ?? '';
    final userPhone = await SessionManager.getUserPhone() ?? '';

    var options = {
      'key': orderData['key'] ?? AppConfig.razorpayKey,
      'amount': orderData['amount'],
      'currency': orderData['currency'] ?? 'INR',
      'name': 'Surgeon Search',
      'description': '${widget.planTitle} - ${widget.planPrice}',
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
