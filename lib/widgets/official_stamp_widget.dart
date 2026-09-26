import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Official Gold Standard Stamp Widget (الختم الذهبي المعتمد لمنظومة دوائي - رقم 6)
/// مصمم وفق المعايير الطبية السحابية المستقلة المتوافقة مع أنظمة الخصوصية الصحية.
class OfficialStampWidget extends StatelessWidget {
  final Color stampColor;
  final String clinicName;
  final String doctorName;
  final String refCode;
  final double scale;
  final bool enableRotation;

  const OfficialStampWidget({
    super.key,
    this.stampColor = const Color(0xFFB45309), // Amber Gold (الذهبي الملكي المعتمد)
    this.clinicName = 'منظومة دوائي للرعاية السريرية',
    this.doctorName = '',
    this.refCode = 'DWA-CLINICAL',
    this.scale = 1.0,
    this.enableRotation = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveClinic = clinicName.trim().isEmpty
        ? 'منظومة دوائي للرعاية السريرية'
        : clinicName.trim();

    final stamp = Container(
      width: 148,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: stampColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: stampColor.withValues(alpha: 0.9),
          width: 2.2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          border: Border.all(
            color: stampColor.withValues(alpha: 0.5),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: 136,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Arch Title & Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 7, color: stampColor),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'DAWAAI CLINICAL EXCELLENCE',
                        style: GoogleFonts.outfit(
                          fontSize: 6.0,
                          fontWeight: FontWeight.w900,
                          color: stampColor,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.star_rounded, size: 7, color: stampColor),
                  ],
                ),
                const SizedBox(height: 1),

                // Clinic Name & Premium Emblem
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 11,
                      color: stampColor,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '★ $effectiveClinic ★',
                        style: GoogleFonts.cairo(
                          fontSize: 6.8,
                          fontWeight: FontWeight.w900,
                          color: stampColor,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1.5),

                // Gold Standard Certification Ribbon
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 0.8),
                  decoration: BoxDecoration(
                    color: stampColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'VERIFIED DIGITAL HEALTH RECORD • توثيق رقمي',
                    style: GoogleFonts.outfit(
                      fontSize: 5.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 1.5),

                // Footer / Ref / Doctor
                Text(
                  doctorName.isNotEmpty
                      ? 'د. $doctorName • $refCode'
                      : 'توثيق سريري معتمد • $refCode',
                  style: GoogleFonts.cairo(
                    fontSize: 5.8,
                    fontWeight: FontWeight.bold,
                    color: stampColor.withValues(alpha: 0.9),
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Transform.scale(
      scale: scale,
      child: enableRotation
          ? Transform.rotate(
              angle: -0.06, // Realistic -3.5 degree ink stamp tilt
              child: stamp,
            )
          : stamp,
    );
  }
}
