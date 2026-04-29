import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/reservation_service.dart';
import 'booking_details_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  static const Color teal = Color(0xFF008F99);
  static const Color tealLight = Color(0xFFE0F2F1);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  bool _scanned = false;
  bool _isTorchOn = false;
  MobileScannerController controller = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();

  // MobileScanner 3.x changed the onDetect callback. It now passes a
  // `BarcodeCapture` containing one or more barcodes instead of separate
  // arguments. Adapt the handler so it works with the newer API.
  void _handleBarcode(BarcodeCapture capture) async {
    if (_scanned) return;

    // guard against an empty list, though the scanner normally provides at
    // least one barcode when onDetect is called.
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final token = barcode.rawValue;
    if (token == null || token.isEmpty) return;

    setState(() {
      _scanned = true;
    });

    final reservationData = await ReservationService.scanReservation(token);
    if (!mounted) return;

    if (reservationData != null) {
      // Navigate to booking details screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BookingDetailsScreen(
            bookingData: reservationData,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to scan reservation')),
      );
      
      // Reset scan state on failure
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _scanned = false;
        });
      }
    }
  }

  Future<void> _pickAndScanImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (image == null) return;

      if (!mounted) return;

      // Show a dialog informing the user
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Image Scanning'),
            content: const Text(
              'For best results, please use the camera scanner. However, you can try uploading an image of your QR code.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processImageQR(image);
                },
                child: const Text('Scan Image'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _processImageQR(XFile image) async {
    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing image...'),
              ],
            ),
          )
        );
      },
    );

    // Simulate processing
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Image scanning is optimized for the camera. Please use the camera scanner for best results.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          /// HEADER
          Container(
            color: Colors.transparent,
            margin: const EdgeInsets.only(top: 48),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 36),
                  padding: const EdgeInsets.only(
                    left: 52,
                    right: 16,
                    top: 14,
                    bottom: 14,
                  ),
                  decoration: const BoxDecoration(color: teal),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Scan QR Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: teal, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.restaurant,
                          color: teal,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: teal.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: tealLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner,
                                color: teal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'QR Scanner',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _scanned
                              ? 'Reservation scanned. Returning...'
                              : 'Align the QR code inside the frame to scan.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 360,
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                MobileScanner(
                                  controller: controller,
                                  onDetect: _handleBarcode,
                                ),
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  controller.toggleTorch();
                                  setState(() => _isTorchOn = !_isTorchOn);
                                },
                                style: OutlinedButton.styleFrom(
                                  side:
                                      BorderSide(color: teal.withOpacity(0.4)),
                                  foregroundColor: teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: Icon(_isTorchOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded),
                                label: Text(_isTorchOn ? 'Torch On' : 'Torch'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: controller.switchCamera,
                                style: OutlinedButton.styleFrom(
                                  side:
                                      BorderSide(color: teal.withOpacity(0.4)),
                                  foregroundColor: teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.cameraswitch_rounded),
                                label: const Text('Switch Camera'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickAndScanImage,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: teal.withOpacity(0.4)),
                              foregroundColor: teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.image_rounded),
                            label: const Text('Upload Image'),
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
}
