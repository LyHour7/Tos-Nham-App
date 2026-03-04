import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/api_service.dart';
import '../../../routes/app_routes.dart';

class QRPaymentScreen extends StatefulWidget {
  final String qrString;
  final String md5;
  final int orderId;
  final String total;

  const QRPaymentScreen({
    super.key,
    required this.qrString,
    required this.md5,
    required this.orderId,
    required this.total,
  });

  @override
  State<QRPaymentScreen> createState() =>
      _QRPaymentScreenState();
}

class _QRPaymentScreenState
    extends State<QRPaymentScreen> {

  bool isPaid = false;
  bool isProcessing = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startCheckingPayment();
  }

Future<void> startCheckingPayment() async {
  while (!isPaid && mounted) {
    await Future.delayed(const Duration(seconds: 3));

    try {
      final response = await ApiService.get(
        "/payments/bakong/check/${widget.orderId}",
      );

      print("CHECK RESPONSE => $response");

      if (response['paid'] == true) {
        if (!mounted) return;

        setState(() {
          isPaid = true;
        });

        break; // stop loop immediately
      }
    } catch (e) {
      print("CHECK ERROR => $e");
    }
  }
}

  Future<void> handleConfirm() async {
    setState(() {
      isProcessing = true;
    });

    // try to clear the cart but don’t block navigation if the call fails
    try {
      await ApiService.delete("/cart/clear");
    } catch (e) {
      debugPrint("clear cart failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to clear cart. Proceeding anyway.")),
        );
      }
    }

    if (!mounted) return;

    // regardless of outcome, pop back to the previous pages
    Navigator.of(context).pop(); // close QR screen
    Navigator.of(context).pop(); // back to cart/previous page

    setState(() {
      isProcessing = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: isPaid
            ? Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 120,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Payment Successful!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                    ),
                    child: isProcessing
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Confirm",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.teal),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: widget.qrString,
                          size: 250,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Total: \$${widget.total}",
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Waiting for payment...",
                    style:
                        TextStyle(color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }
}