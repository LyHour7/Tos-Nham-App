import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';

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
  final int maxAttempts = 40;

  static const Color teal = Color(0xFF009688);
  static const Color bakongRed = Color(0xFFCC1F27);

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
          setState(() => isChecking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Payment check timed out. Please try again."),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      try {
        final response = await ApiService.get(
          "/reservations/bakong/check/${widget.reservationId}",
        );

        if (response['paid'] == true) {
          timer.cancel();
          if (!mounted) return;
          setState(() {
            isPaid = true;
            isChecking = false;
          });
        }
      } catch (e) {
        debugPrint("CHECK ERROR => $e");
      }
    });
  }

  void handleConfirm() {
    _clearCartAndNavigate();
  }

  Future<void> _clearCartAndNavigate() async {
    try {
      // Fetch all cart items first
      final cartResponse = await ApiService.get("/cart");
      final cartItems = cartResponse['data']['cartItems'] ?? [];

      // Delete each item individually
      for (var item in cartItems) {
        try {
          await ApiService.delete("/cart/${item['menuItem']['id']}");
        } catch (e) {
          debugPrint("Failed to delete item: $e");
        }
      }
    } catch (e) {
      debugPrint("clear cart failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to clear cart. Proceeding anyway.")),
        );
      }
    }

    if (!mounted) return;

    // Navigate via bottom nav with booking tab selected
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const CustomerBottomNavBar(initialIndex: 3),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      body: SafeArea(
        child: isPaid ? _buildSuccessView() : _buildQRView(),
      ),
    );
  }

  /// ============================
  /// QR VIEW
  /// ============================
  Widget _buildQRView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          /// BACK BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: teal.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, color: teal, size: 13),
                        SizedBox(width: 2),
                        Text(
                          "Back",
                          style: TextStyle(
                            color: teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// BAKONG BRANDING
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: bakongRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ពាណិជ្ជ",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: bakongRed,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          "BAKONG",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: bakongRed,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  "Scan. Pay. Done.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                // Deposit badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: teal.withOpacity(0.3)),
                  ),
                  child: const Text(
                    "Reservation Deposit",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: teal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// QR CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // QR with corner brackets — NO animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: widget.qrString,
                          size: 230,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      // Scanner corner brackets
                      ..._buildScannerCorners(),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Deposit amount
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Deposit:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF444444),
                          ),
                        ),
                        Text(
                          "\$${widget.depositAmount}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// WAITING / TIMEOUT INDICATOR
          isChecking
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: teal.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Waiting for deposit payment...",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.orange.shade400, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Payment check timed out",
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 30),

          /// FOOTER — KHQR + accepted
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Member of",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "KHQR",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  width: 1,
                  height: 36,
                  color: Colors.grey.shade200,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Accepted here",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _paymentBadge("UnionPay", const Color(0xFFCC1F27)),
                          const SizedBox(width: 6),
                          _paymentBadge("AliPay", const Color(0xFF1677FF)),
                          const SizedBox(width: 6),
                          _paymentBadge("eSPAY", const Color(0xFF00A859)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// ============================
  /// SUCCESS VIEW
  /// ============================
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Deposit Paid!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Your reservation deposit has been confirmed.\nWe'll see you soon!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(30),
                border:
                    Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: Text(
                "Deposit Paid: \$${widget.depositAmount}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 36),

            GestureDetector(
              onTap: handleConfirm,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: teal,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: teal.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Done",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SCANNER CORNERS
  List<Widget> _buildScannerCorners() {
    const size = 18.0;
    const thickness = 3.0;
    const color = Color(0xFFAAAAAA);
    const offset = 14.0;

    Widget corner({required bool top, required bool left}) {
      return Positioned(
        top: top ? offset : null,
        bottom: top ? null : offset,
        left: left ? offset : null,
        right: left ? null : offset,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
              top: top,
              left: left,
              color: color,
              thickness: thickness,
            ),
          ),
        ),
      );
    }

    return [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ];
  }

  Widget _paymentBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// CORNER PAINTER
class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  final Color color;
  final double thickness;

  _CornerPainter({
    required this.top,
    required this.left,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}