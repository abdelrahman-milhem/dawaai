import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../ar.dart';
import '../models/home_pharmacy.dart';
import '../services/storage_service.dart';

class PharmacyQrScannerDialog extends StatefulWidget {
  final StorageService storageService;

  const PharmacyQrScannerDialog({
    super.key,
    required this.storageService,
  });

  static Future<HomePharmacy?> show(
    BuildContext context, {
    required StorageService storageService,
  }) {
    return showDialog<HomePharmacy?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PharmacyQrScannerDialog(
        storageService: storageService,
      ),
    );
  }

  @override
  State<PharmacyQrScannerDialog> createState() => _PharmacyQrScannerDialogState();
}

class _PharmacyQrScannerDialogState extends State<PharmacyQrScannerDialog>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processPayload(String rawCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      HapticFeedback.mediumImpact();
      final currentProfile = widget.storageService.getActiveProfile();
      final imported = await widget.storageService.importPharmacyFromPayload(
        rawCode,
        memberName: currentProfile.name,
      );

      if (!mounted) return;

      if (imported != null) {
        Navigator.of(context).pop(imported);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Ar.pharmacyImportSuccess} (${imported.name} • ${imported.items.length} أدوية)',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(Ar.pharmacyImportFailed),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(Ar.pharmacyImportFailed),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الحافظة فارغة! انسخ كود الصيدلية أولاً.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    await _processPayload(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF0D9488),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Ar.scanPharmacyQrBtn,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Ar.scanPharmacyQrSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              // Camera Viewport
              SizedBox(
                height: 290,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) {
                        if (_isProcessing) return;
                        final barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          final val = barcode.rawValue;
                          if (val != null && val.trim().isNotEmpty) {
                            _processPayload(val.trim());
                            break;
                          }
                        }
                      },
                    ),

                    // Targeting Viewfinder Box
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF0D9488),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Animated Laser line
                    AnimatedBuilder(
                      animation: _laserAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 35 + (_laserAnimation.value * 215),
                          child: Container(
                            width: 200,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF14B8A6).withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Torch & Camera Controls
                    Positioned(
                      bottom: 12,
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () async {
                              await _scannerController.toggleTorch();
                              setState(() => _isTorchOn = !_isTorchOn);
                            },
                            icon: Icon(
                              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: _isTorchOn ? const Color(0xFFF59E0B) : Colors.white,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            onPressed: () => _scannerController.switchCamera(),
                            icon: const Icon(
                              Icons.cameraswitch_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isProcessing)
                      Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF0D9488),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'جاري فحص ومزامنة الصيدلية...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Actions (Paste text code fallback)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _pasteFromClipboard,
                      icon: const Icon(Icons.paste_rounded, size: 20),
                      label: const Text(
                        Ar.pastePharmacyCodeBtn,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'أو إذا أرسل لك أحد أفراد عائلتك كود الصيدلية على واتساب، اضغط على لصق الكود للانضمام فوراً دون الحاجة للكاميرا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        height: 1.4,
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
}
