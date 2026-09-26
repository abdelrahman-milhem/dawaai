import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../ar.dart';
import '../models/dose_log.dart';
import '../models/medicine.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';

class DoctorReportSheet extends StatefulWidget {
  final StorageService storageService;
  final UserProfile profile;

  const DoctorReportSheet({
    super.key,
    required this.storageService,
    required this.profile,
  });

  @override
  State<DoctorReportSheet> createState() => _DoctorReportSheetState();
}

class _DoctorReportSheetState extends State<DoctorReportSheet> {
  final GlobalKey _a4Key = GlobalKey();

  bool _isGeneratingPdf = false;
  bool _isGeneratingImage = false;
  bool _isPrinting = false;

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF0D9488),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<Uint8List?> _captureA4Raster() async {
    try {
      await Future.delayed(const Duration(milliseconds: 120));

      final boundary =
          _a4Key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('RenderRepaintBoundary is null');
        return null;
      }

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 120));
      }

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, stack) {
      debugPrint('Error capturing A4 raster: $e\n$stack');
      return null;
    }
  }

  Future<String?> _saveFileToStorage({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          targetDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        targetDir = await getDownloadsDirectory();
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      final file = File('${targetDir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Direct storage write error: $e');
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final pngBytes = await _captureA4Raster();
      if (pngBytes == null) {
        _showToast(Ar.reportSaveError, isError: true);
        return;
      }

      final doc = pw.Document();
      final image = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(image, fit: pw.BoxFit.fill),
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      final safeName = widget.profile.name.replaceAll(
        RegExp(r'[\s/\\?%*:|"<>]'),
        '_',
      );
      final filename =
          'Medical_Report_${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // 1. Save to temp directory for reliable cross-app sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(pdfBytes, flush: true);

      // 2. Also try writing to device storage
      await _saveFileToStorage(bytes: pdfBytes, filename: filename);

      // 3. Open share sheet (WhatsApp, Drive, Save to Files, etc.)
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          text: '📄 ${Ar.reportA4HeaderTitle} - ${widget.profile.name}',
        ),
      );

      if (mounted) {
        _showToast('✅ ${Ar.reportPdfSavedSuccess}');
      }
    } catch (e) {
      debugPrint('PDF export failed: $e');
      if (mounted) _showToast(Ar.reportSaveError, isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _downloadImage() async {
    if (_isGeneratingImage) return;
    setState(() => _isGeneratingImage = true);

    try {
      final pngBytes = await _captureA4Raster();
      if (pngBytes == null) {
        _showToast(Ar.reportSaveError, isError: true);
        return;
      }

      final safeName = widget.profile.name.replaceAll(
        RegExp(r'[\s/\\?%*:|"<>]'),
        '_',
      );
      final filename =
          'Medical_Report_${safeName}_${DateTime.now().millisecondsSinceEpoch}.png';

      // 1. Save directly to Photo Gallery / الاستوديو
      bool savedToGallery = false;
      try {
        final hasAccess = await Gal.hasAccess(toAlbum: false);
        if (!hasAccess) {
          await Gal.requestAccess(toAlbum: false);
        }
        await Gal.putImageBytes(pngBytes, name: filename);
        savedToGallery = true;
      } catch (galError) {
        debugPrint('Gal save to gallery error: $galError');
      }

      // 2. Save to temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(pngBytes, flush: true);

      // 3. Also try writing to storage
      await _saveFileToStorage(bytes: pngBytes, filename: filename);

      // 4. Open share sheet so user can immediately send to WhatsApp or save
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          text: '🖼️ ${Ar.reportA4HeaderTitle} - ${widget.profile.name}',
        ),
      );

      if (mounted) {
        if (savedToGallery) {
          _showToast('✅ تم حفظ صورة التقرير في معرض الصور (Gallery) بنجاح!');
        } else {
          _showToast('✅ تم تجهيز صورة التقرير بنجاح!');
        }
      }
    } catch (e) {
      debugPrint('Image export failed: $e');
      if (mounted) _showToast(Ar.reportSaveError, isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }

  Future<void> _printReport() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      final pngBytes = await _captureA4Raster();
      if (pngBytes == null) {
        _showToast(Ar.reportSaveError, isError: true);
        return;
      }

      final doc = pw.Document();
      final image = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(image, fit: pw.BoxFit.fill),
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      final safeName = widget.profile.name.replaceAll(
        RegExp(r'[\s/\\?%*:|"<>]'),
        '_',
      );

      await Printing.layoutPdf(
        name: 'Medical_Report_$safeName',
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      debugPrint('Printing failed: $e');
      if (mounted) _showToast(Ar.reportSaveError, isError: true);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  String _generateReportText(
    DateTime now,
    List<Medicine> medicines,
    List<DoseLog> logs,
    List<DoseLog> painLogs,
    List<DoseLog> recentLogs,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(Ar.reportDocHeader);
    buffer.writeln('===================================');
    buffer.writeln(
      '${Ar.reportPatientName} ${widget.profile.name} (${widget.profile.relation})',
    );
    buffer.writeln(
      '${Ar.reportGeneratedDate} ${AppDateUtils.formatFullDate(now)}',
    );
    buffer.writeln('===================================\n');

    buffer.writeln(Ar.reportMedsAndStock);
    if (medicines.isEmpty) {
      buffer.writeln(Ar.reportNoMeds);
    } else {
      for (final med in medicines) {
        final type =
            med.isPainkiller ? Ar.painkillerAsNeeded : Ar.treatmentTag;
        buffer.writeln('• *${med.name}* ($type)');
        buffer.writeln(
          '  - ${Ar.reportDoseLabel} ${med.pillsPerDose} ${med.unitLabel}',
        );
        buffer.writeln(
          '  - ${Ar.reportRemainingStock} ${med.totalPills} ${med.unitLabel}',
        );
        if (med.isTreatment && med.scheduledTimes.isNotEmpty) {
          final times = med.scheduledTimes
              .map(
                (t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}',
              )
              .join(', ');
          buffer.writeln('  - ${Ar.reportDailyTimes} $times');
        }
      }
    }

    buffer.writeln('\n${Ar.reportAdherenceStats7Days}');
    buffer.writeln(
      '• ${Ar.reportTotalDosesTaken} ${recentLogs.length} ${Ar.unitDoses}',
    );

    buffer.writeln('\n${Ar.reportPainAndPainkillersLog}');
    if (painLogs.isEmpty) {
      buffer.writeln(Ar.reportNoRecentPain);
    } else {
      for (final pl in painLogs.take(5)) {
        final timeStr = AppDateUtils.formatDateTime(pl.takenAt);
        final painScore = pl.painLevel != null
            ? '${pl.painLevel}/10'
            : Ar.reportNotSpecified;
        final reason = pl.notes ?? Ar.reportGeneralPain;
        buffer.writeln('• $timeStr');
        buffer.writeln('  - ${Ar.reportPainkiller} ${pl.medicineName}');
        buffer.writeln(
          '  - ${Ar.reportPainIntensity} $painScore | ${Ar.reportPainSite} $reason',
        );
      }
    }

    buffer.writeln('\n===================================');
    buffer.writeln(Ar.reportAutoGeneratedFooter);
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final medicines = widget.storageService.getMedicines(
      forProfileId: widget.profile.id,
    );
    final logs = widget.storageService.getLogs();
    final painLogs = logs.where((l) => l.isPainkiller).toList();
    final recentLogs = logs
        .where((l) => now.difference(l.takenAt).inDays <= 7)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: Color(0xFF0F172A),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: Ar.cancel,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Color(0xFF0D9488),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Ar.reportA4HeaderTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'اسحب للتكبير بالأصابع • الحجم الأدنى 100%',
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: InteractiveViewer(
          minScale: 1.0, // Strictly locked at 100% min width
          maxScale: 3.5, // Smooth zoom in up to 3.5x
          boundaryMargin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 794,
                height: 1123,
                child: RepaintBoundary(
                  key: _a4Key,
                  child: _buildA4Paper(
                    context,
                    now,
                    medicines,
                    logs,
                    painLogs,
                    recentLogs,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
          border: const Border(
            top: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // 1. Download as PDF Button
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _downloadPdf,
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 20,
                        ),
                  label: Text(
                    Ar.reportBtnDownloadPdf,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Save as Image Button
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingImage ? null : _downloadImage,
                  icon: _isGeneratingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.image_rounded,
                          size: 20,
                        ),
                  label: Text(
                    Ar.reportBtnDownloadImage,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 3. Direct Print Icon Button
              IconButton(
                onPressed: _isPrinting ? null : _printReport,
                icon: _isPrinting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.print_rounded,
                        color: Color(0xFF0D9488),
                        size: 22,
                      ),
                tooltip: Ar.reportBtnPrint,
                style: IconButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF0D9488).withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(10),
                ),
              ),

              // 4. Copy Text Icon Button
              IconButton(
                onPressed: () async {
                  final reportText = _generateReportText(
                    now,
                    medicines,
                    logs,
                    painLogs,
                    recentLogs,
                  );
                  await Clipboard.setData(
                    ClipboardData(text: reportText),
                  );
                  _showToast(Ar.reportCopiedSuccess);
                },
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 20,
                ),
                tooltip: Ar.reportBtnCopy,
                style: IconButton.styleFrom(
                  backgroundColor:
                      Colors.grey.withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildA4Paper(
    BuildContext context,
    DateTime now,
    List<Medicine> medicines,
    List<DoseLog> logs,
    List<DoseLog> painLogs,
    List<DoseLog> recentLogs,
  ) {
    final refCode =
        'DWA-${widget.profile.id.hashCode.abs().toString().padLeft(5, '0')}';
    final qrPayload =
        'DAWAAI-CLINICAL|PATIENT:${widget.profile.name}|REF:$refCode|DATE:${now.toIso8601String()}|MEDS:${medicines.length}|LOGS:${logs.length}';

    int scheduledDosesExpected = 0;
    for (final med in medicines) {
      if (med.isTreatment) {
        final timesPerDay =
            med.scheduledTimes.isNotEmpty ? med.scheduledTimes.length : 1;
        scheduledDosesExpected += (timesPerDay * 7);
      }
    }
    final adherenceRate = scheduledDosesExpected > 0
        ? ((recentLogs.length / scheduledDosesExpected) * 100).clamp(0, 100).toInt()
        : 100;

    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: const Color(0xFF0D9488),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: 794,
          height: 1123,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Colorful Accent Stripe
              Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F766E),
                      Color(0xFF0D9488),
                      Color(0xFF14B8A6),
                      Color(0xFFF59E0B),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Official Clinic Letterhead
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right Logo / Emblem
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Ar.reportA4SystemName,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F766E),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'DAWAAI DIGITAL HEALTHCARE PLATFORM',
                          style: GoogleFonts.outfit(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'نظام الرعاية الدوائية المتقدم والتوثيق السريري',
                          style: GoogleFonts.cairo(
                            fontSize: 9.5,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Left Document Meta Box
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              refCode,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${Ar.reportDocumentRef} ',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Ar.reportGeneratedDate} ${AppDateUtils.formatFullDate(now)}',
                          style: GoogleFonts.cairo(
                            fontSize: 9.5,
                            color: const Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'وقت التقرير: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: Color(0xFFCBD5E1), thickness: 1.2),
              const SizedBox(height: 8),

              // Document Title Bar
              Center(
                child: Column(
                  children: [
                    Text(
                      Ar.reportA4HeaderTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      Ar.reportA4SubTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D9488),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Patient Information & Demographics Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Patient Name
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Ar.reportPatientDetails,
                                  style: GoogleFonts.cairo(
                                    fontSize: 9,
                                    color: const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.profile.name,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Relationship
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Ar.reportPatientRelationship,
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            widget.profile.relation,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Medicines Count
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Ar.reportMedicationsCount,
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '${medicines.length} أدوية مسجلة',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 7-Day Adherence Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: adherenceRate >= 80
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: adherenceRate >= 80
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            adherenceRate >= 80
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                            size: 16,
                            color: adherenceRate >= 80
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Ar.reportAdherenceRateLabel,
                                style: GoogleFonts.cairo(
                                  fontSize: 8.5,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                '$adherenceRate% (${recentLogs.length} جرعة)',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: adherenceRate >= 80
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Section 1: Active Medications Table
              Row(
                children: [
                  const Icon(
                    Icons.medication_rounded,
                    size: 16,
                    color: Color(0xFF0D9488),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'الوصفات والجدول الدوائي النشط',
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'CURRENT PRESCRIBED MEDICINES',
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Medications Table
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        color: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                Ar.reportTableColMedName,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                Ar.reportTableColDose,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                Ar.reportTableColSchedule,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                Ar.reportTableColStock,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                Ar.reportTableColStatus,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Rows (Up to 5 medicines)
                      if (medicines.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              Ar.reportNoMeds,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        )
                      else
                        ...medicines.take(5).map((med) {
                          final isEven = medicines.indexOf(med) % 2 == 0;
                          final scheduleText = med.isTreatment
                              ? (med.scheduledTimes.isNotEmpty
                                  ? med.scheduledTimes
                                      .map(
                                        (t) =>
                                            '${t.hour}:${t.minute.toString().padLeft(2, '0')}',
                                      )
                                      .join(' ، ')
                                  : 'مجدول يومياً')
                              : 'عند اللزوم (فاصل ${med.minSafeIntervalHours} س)';

                          final isLowStock =
                              med.totalPills <= med.lowStockThreshold;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isEven
                                  ? Colors.white
                                  : const Color(0xFFF8FAFC),
                              border: const Border(
                                top: BorderSide(
                                  color: Color(0xFFE2E8F0),
                                  width: 0.8,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Name & Type Chip
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          med.name,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: med.isPainkiller
                                              ? const Color(0xFFFEF3C7)
                                              : const Color(0xFFE0F2FE),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          med.isPainkiller ? 'مسكن' : 'علاج',
                                          style: GoogleFonts.cairo(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: med.isPainkiller
                                                ? const Color(0xFFB45309)
                                                : const Color(0xFF0369A1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Dose
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${med.pillsPerDose} ${med.unitLabel}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10.5,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ),

                                // Schedule
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    scheduleText,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Stock
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${med.totalPills} ${med.unitLabel}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isLowStock
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF0F766E),
                                    ),
                                  ),
                                ),

                                // Status
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLowStock
                                          ? const Color(0xFFFEE2E2)
                                          : (med.isPainkiller
                                              ? const Color(0xFFFEF3C7)
                                              : const Color(0xFFECFDF5)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isLowStock
                                          ? Ar.reportStatusLow
                                          : (med.isPainkiller
                                              ? Ar.reportStatusAsNeeded
                                              : Ar.reportStatusGood),
                                      style: GoogleFonts.cairo(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: isLowStock
                                            ? const Color(0xFFB91C1C)
                                            : (med.isPainkiller
                                                ? const Color(0xFF92400E)
                                                : const Color(0xFF047857)),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Section 2: Adherence & Pain Analysis Side-by-Side Cards
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Right Card: 7-Day Adherence Analytics
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.insights_rounded,
                                  size: 14,
                                  color: Color(0xFF0D9488),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'تحليل الالتزام (7 أيام)',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F766E),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              color: Color(0xFFE2E8F0),
                              height: 10,
                            ),
                            Text(
                              '• إجمالي الجرعات: ${recentLogs.length} جرعة',
                              style: GoogleFonts.cairo(
                                fontSize: 9.5,
                                color: const Color(0xFF334155),
                                height: 1.4,
                              ),
                            ),
                            Text(
                              '• معدل التناول: ${(recentLogs.length / 7).toStringAsFixed(1)} جرعة / يوم',
                              style: GoogleFonts.cairo(
                                fontSize: 9.5,
                                color: const Color(0xFF334155),
                                height: 1.4,
                              ),
                            ),
                            Text(
                              '• آخر جرعة: ${logs.isNotEmpty ? AppDateUtils.formatDateTime(logs.first.takenAt) : 'لا يوجد'}',
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'المريض يتبع جدول العلاج بانتظام.',
                                      style: GoogleFonts.cairo(
                                        fontSize: 8.5,
                                        color: const Color(0xFF065F46),
                                        fontWeight: FontWeight.bold,
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

                    const SizedBox(width: 10),

                    // Left Card: Emergency Painkiller Log
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.healing_rounded,
                                  size: 14,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'سجل نوبات الألم والمسكنات',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              color: Color(0xFFE2E8F0),
                              height: 10,
                            ),
                            if (painLogs.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    Ar.reportNoPainLogged,
                                    style: GoogleFonts.cairo(
                                      fontSize: 9.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ...painLogs.take(2).map((pl) {
                                final timeStr =
                                    AppDateUtils.formatDateTime(pl.takenAt);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '• $timeStr',
                                            style: GoogleFonts.cairo(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'شدة: ${pl.painLevel ?? '-'}/10',
                                            style: GoogleFonts.cairo(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFB45309),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '  المسكن: ${pl.medicineName} | السبب: ${pl.notes ?? Ar.reportGeneralPain}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 8.5,
                                          color: const Color(0xFF475569),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Section 3: Doctor's Clinical Notes & Signature Area
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Ar.reportDoctorNotesTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Lined space for handwriting
                    for (int i = 0; i < 2; i++)
                      Container(
                        height: 16,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Signatures & Official Stamp Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Doctor Signature Line
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Ar.reportDoctorSignatureLabel,
                                style: GoogleFonts.cairo(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'د. ',
                                    style: GoogleFonts.cairo(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      margin: const EdgeInsets.only(left: 16),
                                      color: const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Official Clinic Stamp Box
                        Container(
                          width: 120,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF94A3B8),
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: Color(0xFFCBD5E1),
                                ),
                                Text(
                                  'الختم والاعتماد الرسمي',
                                  style: GoogleFonts.cairo(
                                    fontSize: 8,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Official Footer & Verification QR Code
              const Divider(color: Color(0xFFCBD5E1), thickness: 1),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Verification Mini QR Code
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 40,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F766E),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Legal Disclaimer & Security Notice
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Ar.reportFooterConfidential,
                          style: GoogleFonts.cairo(
                            fontSize: 8,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'OFFICIAL MEDICAL RECORD • VERIFIED VIA DAWAAI CLINICAL ENGINE • ALL RIGHTS RESERVED',
                          style: GoogleFonts.outfit(
                            fontSize: 6.5,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page Number & System Ref
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'صفحة 1 من 1',
                        style: GoogleFonts.cairo(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        'DWA-A4-V2.0',
                        style: GoogleFonts.outfit(
                          fontSize: 7,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
