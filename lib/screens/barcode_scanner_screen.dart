import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../ar.dart';
import '../data/drug_database.dart';
import '../models/drug_info.dart';
import '../models/medicine.dart';

class BarcodeScanResult {
  final DrugInfo? drug;
  final String barcode;

  BarcodeScanResult({
    this.drug,
    required this.barcode,
  });
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _cameraController;
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  bool _isProcessing = false;
  bool _isTorchOn = false;
  double _zoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      formats: const [
        BarcodeFormat.all,
      ],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _setZoom(double zoom) async {
    setState(() => _zoomScale = zoom);
    try {
      await _cameraController.setZoomScale(zoom);
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _handleScannedCode(rawValue.trim());
        break;
      }
    }
  }

  void _handleScannedCode(String code) {
    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();

    // البحث في موسوعة الأدوية الشاملة
    final foundDrug = DrugDatabase.findByBarcode(code);

    _showResultModal(code, foundDrug);
  }

  void _showResultModal(String code, DrugInfo? drug) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: drug != null
                    ? const Color(0xFF10B981)
                    : theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Status Indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: drug != null
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        drug != null
                            ? Icons.check_circle_rounded
                            : Icons.help_outline_rounded,
                        color: drug != null ? const Color(0xFF10B981) : Colors.amber[700],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drug != null ? Ar.drugRecognized : Ar.drugNotRecognized,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: drug != null
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.amber[300] : Colors.amber[800]),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Ar.scannedBarcodeLabel}$code',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Drug Details Card (If identified)
                if (drug != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                drug.tradeName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: drug.type == MedicineType.painkiller
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                    : const Color(0xFF0D9488).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                drug.type == MedicineType.painkiller
                                    ? Ar.typePainkillerLabel
                                    : Ar.typeTreatmentLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: drug.type == MedicineType.painkiller
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF0D9488),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.science_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                drug.genericName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.business_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                drug.company,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (drug.availableDosages.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: drug.availableDosages.take(3).map((dosage) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  dosage,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ] else ...[
                  // Unrecognized barcode info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'تم قراءة الرمز بنجاح. يمكنك استخدامه لإضافة دواء جديد وسيتذكر التطبيق هذا الباركود دائماً.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx); // Close modal
                    Navigator.pop(
                      context,
                      BarcodeScanResult(drug: drug, barcode: code),
                    ); // Return result to caller
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text(
                    drug != null ? Ar.useDrugData : 'متابعة وإدخال بيانات الدواء',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
                if (drug == null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openEncyclopediaLinkerModal(code);
                    },
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text(
                      'ربط مع دواء من الموسوعة (أنسولين، فيتامين د...)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D9488),
                      side: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _isProcessing = false;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(Ar.scanAgain),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEncyclopediaLinkerModal(String scannedBarcode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String query = '';

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered = DrugDatabase.search(query);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                margin: const EdgeInsets.only(top: 40),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ربط الباركود بدواء من الموسوعة',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اختر الدواء المطابق لعلبتك وسيتم ملء البيانات وربط الباركود ($scannedBarcode) به',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            autofocus: true,
                            onChanged: (val) => setModalState(() => query = val),
                            decoration: InputDecoration(
                              hintText: 'ابحث بالاسم (مثال: لانتوس، بيودال، بنادول...)',
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'لم يتم العثور على دواء مطابق',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (c, i) {
                                final drug = filtered[i];
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.medication_rounded, color: Color(0xFF0D9488), size: 20),
                                  ),
                                  title: Text(drug.tradeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                  subtitle: Text('${drug.genericName} • ${drug.category}', style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                                  trailing: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0D9488)),
                                  onTap: () {
                                    Navigator.pop(modalCtx);
                                    Navigator.pop(
                                      context,
                                      BarcodeScanResult(drug: drug, barcode: scannedBarcode),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openManualBarcodeInput() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.keyboard_alt_outlined, color: Color(0xFF0D9488), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(Ar.enterBarcodeDialogTitle, style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: Ar.barcodeFieldHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.qr_code_2_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildQuickBarcodeChip('لانتوس', '3582910034401', textController),
                  _buildQuickBarcodeChip('بيودال', '6251001001012', textController),
                  _buildQuickBarcodeChip('بنادول', '6291003440019', textController),
                  _buildQuickBarcodeChip('كونكور', '4027455101015', textController),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(Ar.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final code = textController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(ctx);
                  _handleScannedCode(code);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(Ar.searchAndApply),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickBarcodeChip(String name, String code, TextEditingController ctrl) {
    return InkWell(
      onTap: () => ctrl.text = code,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$name ($code)',
          style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanAreaSize = (screenSize.width * 0.72).clamp(240.0, 320.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ─── 1. Live Camera Preview ───
            MobileScanner(
              controller: _cameraController,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 54),
                        const SizedBox(height: 16),
                        const Text(
                          Ar.cameraPermissionRequired,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _openManualBarcodeInput,
                          icon: const Icon(Icons.keyboard_alt_outlined),
                          label: const Text(Ar.manualBarcodeInput),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ─── 2. Dark Overlay with Cutout ───
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.65),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── 3. Viewfinder Reticle & Animated Laser Line ───
            Center(
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: Stack(
                  children: [
                    // Corner Brackets
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isProcessing
                                ? const Color(0xFF10B981)
                                : const Color(0xFF2DD4BF).withValues(alpha: 0.8),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),

                    // Futuristic Animated Laser Scan Line
                    if (!_isProcessing)
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: scanAreaSize * _laserAnimation.value,
                            left: 12,
                            right: 12,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF2DD4BF),
                                    Color(0xFF14B8A6),
                                    Color(0xFF2DD4BF),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // ─── 4. Top Glassmorphic Navigation Bar ───
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                      tooltip: Ar.cancel,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Ar.scanBarcodeTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Ar.scanBarcodeSubtitle,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Torch Button
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isTorchOn ? Colors.amber : Colors.white70,
                        size: 22,
                      ),
                      onPressed: () async {
                        await _cameraController.toggleTorch();
                        setState(() => _isTorchOn = !_isTorchOn);
                      },
                      tooltip: _isTorchOn ? Ar.torchOff : Ar.torchOn,
                    ),
                    // Switch Camera Button
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70, size: 22),
                      onPressed: () => _cameraController.switchCamera(),
                      tooltip: Ar.switchCamera,
                    ),
                  ],
                ),
              ),
            ),

            // ─── 5. Zoom Quick Controls (1x, 2x, 3x) ───
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildZoomButton(1.0, '1x'),
                      const SizedBox(width: 4),
                      _buildZoomButton(1.7, '2x'),
                      const SizedBox(width: 4),
                      _buildZoomButton(2.5, '3x'),
                    ],
                  ),
                ),
              ),
            ),

            // ─── 6. Bottom Manual Barcode Button ───
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 32,
              right: 32,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _openManualBarcodeInput,
                  icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                  label: const Text(
                    Ar.manualBarcodeInput,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.65),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButton(double zoom, String label) {
    final isSelected = (_zoomScale - zoom).abs() < 0.2;
    return InkWell(
      onTap: () => _setZoom(zoom),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
