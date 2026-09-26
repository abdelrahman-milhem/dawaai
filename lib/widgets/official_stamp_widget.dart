import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';

/// Available official stamp design types
enum StampStyleType {
  circularRoyal, // الختم الدائري الملكي السريري
  securityBox, // ختم الاعتماد الأمني المستطيل
  ovalMinistry, // ختم الشارة البيضاوية المعتمدة
  rxPharmacy, // ختم الصيدلية وصرف الوصفة
  consultantDoctor, // ختم الاستشاري المعالج
  digitalVerified, // ختم التوثيق الرقمي المشفر
}

/// Official Stamp Color Theme
class StampColorOption {
  final String id;
  final String name;
  final Color color;
  final String description;

  const StampColorOption({
    required this.id,
    required this.name,
    required this.color,
    required this.description,
  });
}

/// Stamp Style Definition
class StampStyleOption {
  final StampStyleType type;
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const StampStyleOption({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class OfficialStampsCatalog {
  static const List<StampColorOption> colors = [
    StampColorOption(
      id: 'royal_blue',
      name: 'أزرق سريري ملكي',
      color: Color(0xFF1D4ED8),
      description: 'اللون الأزرق الطبي الكلاسيكي المعتمد في المستشفيات والعيادات',
    ),
    StampColorOption(
      id: 'emerald_teal',
      name: 'أخضر زمردي معتمد',
      color: Color(0xFF0F766E),
      description: 'اللون الرسمي لمنظومة دوائي للرعاية الصحية',
    ),
    StampColorOption(
      id: 'crimson_security',
      name: 'أحمر أمني قرمزي',
      color: Color(0xFFB91C1C),
      description: 'ختم الاعتماد الأمني والتوثيق العاجل',
    ),
    StampColorOption(
      id: 'imperial_violet',
      name: 'بنفسجي سيادي',
      color: Color(0xFF6D28D9),
      description: 'ختم المصادقة الإدارية والرقمية المتقدمة',
    ),
    StampColorOption(
      id: 'amber_gold',
      name: 'ذهبي ملكي معتمد',
      color: Color(0xFFB45309),
      description: 'شارة الاعتماد الذهبية للتميز والجودة السريرية',
    ),
    StampColorOption(
      id: 'slate_charcoal',
      name: 'رمادي كلاسيكي',
      color: Color(0xFF334155),
      description: 'حبر التوثيق المكتبي والرسمي الكلاسيكي',
    ),
  ];

  static const List<StampStyleOption> styles = [
    StampStyleOption(
      type: StampStyleType.circularRoyal,
      id: 'circular_royal',
      title: 'الختم الدائري الملكي',
      subtitle: 'ختم سريري دائري كلاسيكي معتمد مع شعار الرعاية والتوثيق',
      icon: Icons.verified_rounded,
    ),
    StampStyleOption(
      type: StampStyleType.securityBox,
      id: 'security_box',
      title: 'ختم الاعتماد الأمني',
      subtitle: 'إطار مستطيل مزدوج يحمل كود المطابقة والتصريح السريري',
      icon: Icons.security_rounded,
    ),
    StampStyleOption(
      type: StampStyleType.ovalMinistry,
      id: 'oval_ministry',
      title: 'الختم البيضاوي المعتمد',
      subtitle: 'ختم بيضاوي فاخر لشهادات التوثيق والامتثال الطبي',
      icon: Icons.shield_rounded,
    ),
    StampStyleOption(
      type: StampStyleType.rxPharmacy,
      id: 'rx_pharmacy',
      title: 'ختم الصيدلية والوصفة Rx',
      subtitle: 'ختم الصرف الدوائي المعتمد والمطابقة مع الصيدلية',
      icon: Icons.local_pharmacy_rounded,
    ),
    StampStyleOption(
      type: StampStyleType.consultantDoctor,
      id: 'consultant_doctor',
      title: 'ختم الاستشاري المعالج',
      subtitle: 'ختم خاص بالطبيب المعالج والعيادة الاستشارية',
      icon: Icons.medical_services_rounded,
    ),
    StampStyleOption(
      type: StampStyleType.digitalVerified,
      id: 'digital_verified',
      title: 'ختم التوثيق الرقمي المشفر',
      subtitle: 'ختم تقني حديث برمز التشفير والاعتماد الرقمي الفوري',
      icon: Icons.qr_code_2_rounded,
    ),
  ];

  static StampColorOption getColorById(String id) {
    return colors.firstWhere(
      (c) => c.id == id,
      orElse: () => colors.first,
    );
  }

  static StampColorOption getColorByValue(int value) {
    return colors.firstWhere(
      (c) => c.color.toARGB32() == value,
      orElse: () => colors.first,
    );
  }

  static StampStyleOption getStyleById(String id) {
    return styles.firstWhere(
      (s) => s.id == id,
      orElse: () => styles.first,
    );
  }
}

/// Official Stamp Widget - Renders any official clinical stamp
class OfficialStampWidget extends StatelessWidget {
  final StampStyleType styleType;
  final Color stampColor;
  final String clinicName;
  final String doctorName;
  final String refCode;
  final double scale;
  final bool enableRotation;

  const OfficialStampWidget({
    super.key,
    this.styleType = StampStyleType.circularRoyal,
    this.stampColor = const Color(0xFF1D4ED8),
    this.clinicName = 'منظومة دوائي للرعاية السريرية',
    this.doctorName = '',
    this.refCode = 'DWA-CLINICAL',
    this.scale = 1.0,
    this.enableRotation = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveClinic =
        clinicName.trim().isEmpty ? 'منظومة دوائي للرعاية السريرية' : clinicName.trim();

    Widget stampContent;
    switch (styleType) {
      case StampStyleType.circularRoyal:
        stampContent = _buildCircularRoyal(context, effectiveClinic);
        break;
      case StampStyleType.securityBox:
        stampContent = _buildSecurityBox(context, effectiveClinic);
        break;
      case StampStyleType.ovalMinistry:
        stampContent = _buildOvalMinistry(context, effectiveClinic);
        break;
      case StampStyleType.rxPharmacy:
        stampContent = _buildRxPharmacy(context, effectiveClinic);
        break;
      case StampStyleType.consultantDoctor:
        stampContent = _buildConsultantDoctor(context, effectiveClinic);
        break;
      case StampStyleType.digitalVerified:
        stampContent = _buildDigitalVerified(context, effectiveClinic);
        break;
    }

    return Transform.scale(
      scale: scale,
      child: enableRotation
          ? Transform.rotate(
              angle: -0.06, // Realistic -3.5 degree ink stamp tilt
              child: stampContent,
            )
          : stampContent,
    );
  }

  // 1. الختم الدائري الملكي
  Widget _buildCircularRoyal(BuildContext context, String clinic) {
    return Container(
      width: 140,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: stampColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: stampColor.withValues(alpha: 0.85),
          width: 2.2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: stampColor.withValues(alpha: 0.5),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '★ $clinic ★',
              style: GoogleFonts.cairo(
                fontSize: 7.2,
                fontWeight: FontWeight.w900,
                color: stampColor,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: stampColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'معتمد رسمياً • APPROVED',
                style: GoogleFonts.cairo(
                  fontSize: 6.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              doctorName.isNotEmpty
                  ? 'د. $doctorName • $refCode'
                  : 'DAWAAI CLINICAL ENGINE • $refCode',
              style: GoogleFonts.outfit(
                fontSize: 6.2,
                fontWeight: FontWeight.w800,
                color: stampColor.withValues(alpha: 0.9),
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 2. ختم الاعتماد الأمني المستطيل
  Widget _buildSecurityBox(BuildContext context, String clinic) {
    return Container(
      width: 146,
      height: 68,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: stampColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: stampColor,
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: stampColor.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 8, color: stampColor),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '★ $clinic ★',
                    style: GoogleFonts.cairo(
                      fontSize: 7.2,
                      fontWeight: FontWeight.w900,
                      color: stampColor,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Text(
              'مُعتمد ومُطابق سريرياً • VERIFIED',
              style: GoogleFonts.cairo(
                fontSize: 7.0,
                fontWeight: FontWeight.bold,
                color: stampColor,
                height: 1.0,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  refCode,
                  style: GoogleFonts.outfit(
                    fontSize: 6.2,
                    fontWeight: FontWeight.bold,
                    color: stampColor.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  'توثيق دوائي رسمي',
                  style: GoogleFonts.cairo(
                    fontSize: 6.2,
                    fontWeight: FontWeight.bold,
                    color: stampColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. ختم الشارة البيضاوية
  Widget _buildOvalMinistry(BuildContext context, String clinic) {
    return Container(
      width: 142,
      height: 70,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: stampColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.all(Radius.elliptical(70, 35)),
        border: Border.all(
          color: stampColor,
          width: 2.2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              clinic,
              style: GoogleFonts.cairo(
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                color: stampColor,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_rounded, size: 9, color: stampColor),
                const SizedBox(width: 3),
                Text(
                  'مصادقة الرعاية الصحية',
                  style: GoogleFonts.cairo(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: stampColor,
                  ),
                ),
              ],
            ),
            Text(
              'CLINICALLY VALIDATED • $refCode',
              style: GoogleFonts.outfit(
                fontSize: 5.8,
                fontWeight: FontWeight.bold,
                color: stampColor.withValues(alpha: 0.85),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. ختم الصيدلية وصرف الوصفة Rx
  Widget _buildRxPharmacy(BuildContext context, String clinic) {
    return Container(
      width: 144,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: stampColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: stampColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: stampColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Rx',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinic,
                  style: GoogleFonts.cairo(
                    fontSize: 7.2,
                    fontWeight: FontWeight.w900,
                    color: stampColor,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'صُرف وطُوبق حسب الأصول',
                  style: GoogleFonts.cairo(
                    fontSize: 6.8,
                    fontWeight: FontWeight.bold,
                    color: stampColor,
                  ),
                ),
                Text(
                  'PHARMACY AUDITED • $refCode',
                  style: GoogleFonts.outfit(
                    fontSize: 5.8,
                    fontWeight: FontWeight.bold,
                    color: stampColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. ختم الاستشاري المعالج
  Widget _buildConsultantDoctor(BuildContext context, String clinic) {
    return Container(
      width: 144,
      height: 68,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: stampColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stampColor,
          width: 2.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            clinic,
            style: GoogleFonts.cairo(
              fontSize: 7.2,
              fontWeight: FontWeight.w900,
              color: stampColor,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            doctorName.isNotEmpty
                ? 'الاستشاري المعالج: د. $doctorName'
                : 'الاستشاري المعالج • صادر للاستخدام الطبي',
            style: GoogleFonts.cairo(
              fontSize: 6.8,
              fontWeight: FontWeight.bold,
              color: stampColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'AUTHORIZED PHYSICIAN • $refCode',
            style: GoogleFonts.outfit(
              fontSize: 5.8,
              fontWeight: FontWeight.w800,
              color: stampColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // 6. ختم التوثيق الرقمي المشفر
  Widget _buildDigitalVerified(BuildContext context, String clinic) {
    return Container(
      width: 144,
      height: 68,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: stampColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stampColor,
          width: 1.8,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, size: 22, color: stampColor),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'توثيق رقمي مشفر',
                  style: GoogleFonts.cairo(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: stampColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  clinic,
                  style: GoogleFonts.cairo(
                    fontSize: 6.8,
                    fontWeight: FontWeight.bold,
                    color: stampColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'CRYPTOGRAPHICALLY SEALED',
                  style: GoogleFonts.outfit(
                    fontSize: 5.5,
                    fontWeight: FontWeight.bold,
                    color: stampColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Official Stamp Customizer Dialog/Sheet
class OfficialStampCustomizerSheet extends StatefulWidget {
  final StorageService storageService;
  final String refCode;
  final VoidCallback onStampChanged;

  const OfficialStampCustomizerSheet({
    super.key,
    required this.storageService,
    required this.refCode,
    required this.onStampChanged,
  });

  @override
  State<OfficialStampCustomizerSheet> createState() =>
      _OfficialStampCustomizerSheetState();
}

class _OfficialStampCustomizerSheetState
    extends State<OfficialStampCustomizerSheet> {
  late String _selectedStyleId;
  late int _selectedColorValue;
  late TextEditingController _clinicController;
  late TextEditingController _doctorController;

  @override
  void initState() {
    super.initState();
    _selectedStyleId = widget.storageService.getDoctorReportStampStyle();
    _selectedColorValue = widget.storageService.getDoctorReportStampColor();
    _clinicController = TextEditingController(
      text: widget.storageService.getDoctorReportStampClinic(),
    );
    _doctorController = TextEditingController(
      text: widget.storageService.getDoctorReportStampDoctor(),
    );
  }

  @override
  void dispose() {
    _clinicController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _saveAndApply() async {
    await widget.storageService.setDoctorReportStampStyle(_selectedStyleId);
    await widget.storageService.setDoctorReportStampColor(_selectedColorValue);
    await widget.storageService
        .setDoctorReportStampClinic(_clinicController.text.trim());
    await widget.storageService
        .setDoctorReportStampDoctor(_doctorController.text.trim());

    widget.onStampChanged();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ تم حفظ وتطبيق الختم الرسمي المختار بنجاح!',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(_selectedColorValue),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStyle = OfficialStampsCatalog.getStyleById(_selectedStyleId);
    final activeColor = Color(_selectedColorValue);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.approval_rounded,
                    color: activeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختيار وتخصيص الختم الرسمي',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'اختر شكل الختم ولون الحبر الرسمي المفضل لديك',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 16, color: Color(0xFFE2E8F0)),

          // Scrollable Options & Live Preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Preview Card
                  Text(
                    'معاينة الختم المباشرة:',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: OfficialStampWidget(
                        styleType: activeStyle.type,
                        stampColor: activeColor,
                        clinicName: _clinicController.text,
                        doctorName: _doctorController.text,
                        refCode: widget.refCode,
                        scale: 1.15,
                        enableRotation: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 1. Stamp Colors Picker
                  Text(
                    '1. اختر لون الحبر الرسمي:',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: OfficialStampsCatalog.colors.map((c) {
                      final isSelected = _selectedColorValue == c.color.toARGB32();
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedColorValue = c.color.toARGB32();
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? c.color.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? c.color
                                  : const Color(0xFFCBD5E1),
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: c.color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.color.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c.name,
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? c.color
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 2. Stamp Styles List
                  Text(
                    '2. اختر شكل ونموذج الختم:',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...OfficialStampsCatalog.styles.map((style) {
                    final isSelected = _selectedStyleId == style.id;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedStyleId = style.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? activeColor
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor.withValues(alpha: 0.15)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                style.icon,
                                color: isSelected
                                    ? activeColor
                                    : const Color(0xFF64748B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    style.title,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? activeColor
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    style.subtitle,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: activeColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // 3. Optional Customization Fields
                  Text(
                    '3. نصوص وتفاصيل الختم (اختياري):',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _clinicController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'اسم المركز / العيادة / الصيدلية',
                      labelStyle: GoogleFonts.cairo(fontSize: 12),
                      hintText: 'مثال: عيادة الرعاية المتقدمة',
                      hintStyle: GoogleFonts.cairo(fontSize: 11),
                      prefixIcon: const Icon(Icons.local_hospital_rounded, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: GoogleFonts.cairo(fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _doctorController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'اسم الطبيب أو الصيدلي المسؤول',
                      labelStyle: GoogleFonts.cairo(fontSize: 12),
                      hintText: 'مثال: د. عبدالرحمن ملحم',
                      hintStyle: GoogleFonts.cairo(fontSize: 11),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: GoogleFonts.cairo(fontSize: 12.5),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: _saveAndApply,
                icon: const Icon(Icons.verified_rounded, size: 20),
                label: Text(
                  'تطبيق وحفظ الختم في التقرير',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
