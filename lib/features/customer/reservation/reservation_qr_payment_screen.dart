import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/api_service.dart';
import '../../../routes/app_routes.dart';

class ReservationQRPaymentScreen extends StatefulWidget {
  final String qrString;
  final String md5;
  final int reservationId;
  final String depositAmount;

  const ReservationQRPaymentScreen({
    super.key,
    required this.qrString,
    required this.md5,
    required this.reservationId,
    required this.depositAmount,
  });

  @override
  State<ReservationQRPaymentScreen> createState() =>
      _ReservationQRPaymentScreenState();
}

class _ReservationQRPaymentScreenState
    extends State<ReservationQRPaymentScreen> {

  bool isPaid = false;
  bool isChecking = true;
  Timer? timer;
  int attemptCount = 0;
  final int maxAttempts = 40; // 40 × 3 sec = 2 minutes

  @override
  void initState() {
    super.initState();
    startCheckingPayment();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startCheckingPayment() {
    timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || isPaid) {
        timer.cancel();
        return;
      }

      attemptCount++;

      if (attemptCount >= maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() {
            isChecking = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Payment check timed out. Please try again."),
            ),
          );
        }
        return;
      }

      try {
        final response = await ApiService.get(
          "/reservations/bakong/check/${widget.reservationId}",
        );

        print("CHECK RESPONSE => $response");

        if (response['paid'] == true) {
          timer.cancel();

          if (!mounted) return;

          setState(() {
            isPaid = true;
            isChecking = false;
          });
        }
      } catch (e) {
        print("CHECK ERROR => $e");
      }
    });
  }

  void handleConfirm() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.booking,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservation Deposit QR"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: isPaid
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 120,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Deposit Payment Successful!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                    ),
                    child: const Text(
                      "Confirm",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: widget.qrString,
                          size: 250,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Deposit: \$${widget.depositAmount}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  isChecking
                      ? const CircularProgressIndicator()
                      : const Text(
                          "Waiting for deposit payment...",
                          style: TextStyle(color: Colors.grey),
                        ),
                ],
              ),
      ),
    );
  }
}