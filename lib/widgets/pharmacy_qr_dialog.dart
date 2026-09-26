import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../ar.dart';
import '../models/home_pharmacy.dart';
import '../services/storage_service.dart';

class PharmacyQrDialog extends StatelessWidget {
  final HomePharmacy pharmacy;
  final StorageService storageService;

  const PharmacyQrDialog({
    super.key,
    required this.pharmacy,
    required this.storageService,
  });

  static Future<void> show(
    BuildContext context, {
    required HomePharmacy pharmacy,
    required StorageService storageService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PharmacyQrDialog(
        pharmacy: pharmacy,
        storageService: storageService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final payload = storageService.exportPharmacyPayload(pharmacy);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Color(0xFF0D9488),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Ar.pharmacyQrTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pharmacy.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D9488),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                Ar.pharmacyQrSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // QR Code Card
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0D9488),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pharmacy Credentials Summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'معرف الصيدلية',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pharmacy.id,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                    Container(height: 28, width: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                    Column(
                      children: [
                        Text(
                          'كلمة المرور',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pharmacy.password.isNotEmpty ? pharmacy.password : 'بدون',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(height: 28, width: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                    Column(
                      children: [
                        Text(
                          'الأدوية المشتركة',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${pharmacy.items.length} أدوية',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Instructions Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  Ar.pharmacyQrInstructions,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0D9488),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Copy Sharing Code Button
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: payload));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(Ar.pharmacyCodeCopied),
                      backgroundColor: Color(0xFF0D9488),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded, size: 20),
                label: const Text(
                  Ar.copyPharmacyCodeBtn,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
