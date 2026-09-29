import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String display = status.toUpperCase();

    switch (display) {
      case 'APPROVED':
      case 'COMPLETED':
      case 'WIN':
        bg = AppColors.success.withOpacity(0.12);
        fg = AppColors.success;
        break;
      case 'PENDING':
      case 'SCHEDULED':
      case 'DRAFT':
        bg = AppColors.warning.withOpacity(0.12);
        fg = AppColors.warning;
        break;
      case 'REJECTED':
      case 'CANCELLED':
      case 'LOSS':
        bg = AppColors.error.withOpacity(0.12);
        fg = AppColors.error;
        break;
      case 'DRAW':
        bg = AppColors.secondary.withOpacity(0.12);
        fg = AppColors.secondary;
        break;
      default:
        bg = AppColors.textSecondary.withOpacity(0.12);
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display,
        style: GoogleFonts.outfit(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
